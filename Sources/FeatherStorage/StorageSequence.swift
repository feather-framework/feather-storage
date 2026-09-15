//
//  StorageSequence.swift
//  feather-storage
//
//  Created by Tibor Bodecs on 2023. 01. 16.

import NIOCore

/// A type-erased async sequence of storage byte buffers.
public struct StorageSequence: Sendable, AsyncSequence {
    /// An async iterator over a `StorageSequence`.
    public struct AsyncIterator: AsyncIteratorProtocol {
        private var base: any AsyncIteratorProtocol<ByteBuffer, any Error>

        init(
            base: any AsyncIteratorProtocol<ByteBuffer, any Error>
        ) {
            self.base = base
        }

        #if compiler(>=6.2)
        /// Returns the next available byte buffer from the sequence.
        ///
        /// - Returns: The next `ByteBuffer`, or `nil` when the sequence is finished.
        /// - Throws: Any error emitted by the underlying async sequence.
        @concurrent
        public mutating func next() async throws -> ByteBuffer? {
            try await base.next(isolation: nil)
        }
        #else
        /// Returns the next available byte buffer from the sequence.
        ///
        /// - Returns: The next `ByteBuffer`, or `nil` when the sequence is finished.
        /// - Throws: Any error emitted by the underlying async sequence.
        public mutating func next() async throws -> ByteBuffer? {
            try await base.next()
        }
        #endif

        /// Returns the next available byte buffer using an explicit actor isolation context.
        ///
        /// - Parameter actor: The actor isolation context to use while awaiting the next element.
        /// - Returns: The next `ByteBuffer`, or `nil` when the sequence is finished.
        /// - Throws: Any error emitted by the underlying async sequence.
        public mutating func next(
            isolation actor: isolated (any Actor)?
        ) async throws -> Element? {
            try await base.next(isolation: actor)
        }
    }

    private struct ErrorErasingSequence<Base: AsyncSequence & Sendable>:
        AsyncSequence,
        Sendable
    where Base.Element == ByteBuffer {
        typealias Element = ByteBuffer
        typealias Failure = any Error

        struct AsyncIterator: AsyncIteratorProtocol {
            var base: Base.AsyncIterator

            mutating func next(
                isolation actor: isolated (any Actor)?
            ) async throws(any Error) -> ByteBuffer? {
                try await base.next(isolation: actor)
            }
        }

        let base: Base

        func makeAsyncIterator() -> AsyncIterator {
            .init(base: base.makeAsyncIterator())
        }
    }

    private let makeIterator: @Sendable () -> AsyncIterator

    /// Optional known byte length of the sequence.
    public let length: UInt64?

    /// Creates a type-erased storage sequence from a sendable async byte sequence.
    ///
    /// - Parameters:
    ///   - asyncSequence: The source async sequence producing `ByteBuffer` values.
    ///   - length: Optional known total byte length.
    public init<S: AsyncSequence & Sendable>(
        asyncSequence: S,
        length: UInt64? = nil
    ) where S.Element == ByteBuffer {
        self.length = length
        self.makeIterator = {
            AsyncIterator(
                base: ErrorErasingSequence(base: asyncSequence)
                    .makeAsyncIterator()
            )
        }
    }

    /// Creates a type-erased storage sequence from a byte buffer.
    ///
    /// - Parameters:
    ///   - buffer: The underlying byte buffer.
    ///   - chunkSize: The maximum number of bytes emitted per iteration.
    public init(
        buffer: ByteBuffer,
        chunkSize: Int = 32 * 1024
    ) {
        self.init(
            asyncSequence: ByteBufferSequence(
                buffer: buffer,
                chunkSize: chunkSize
            ),
            length: UInt64(buffer.readableBytes)
        )
    }

    /// Creates an async iterator for consuming the storage sequence.
    ///
    /// - Returns: A new `AsyncIterator` instance.
    public func makeAsyncIterator() -> AsyncIterator {
        makeIterator()
    }
}
