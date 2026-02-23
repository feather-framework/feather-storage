//
//  StorageSequence.swift
//  feather-storage
//
//  Created by Tibor Bodecs on 2023. 01. 16.

import NIOCore

/// A type-erased async sequence of storage byte buffers.
public struct StorageSequence: Sendable, AsyncSequence {
    typealias BaseAsyncSequence = AsyncStream<Result<ByteBuffer, any Error>>

    /// An async iterator over a `StorageSequence`.
    public struct AsyncIterator: AsyncIteratorProtocol {
        private var base: BaseAsyncSequence.AsyncIterator

        init(base: BaseAsyncSequence.AsyncIterator) {
            self.base = base
        }

        #if compiler(>=6.2)
        /// Returns the next available byte buffer from the sequence.
        ///
        /// - Returns: The next `ByteBuffer`, or `nil` when the sequence is finished.
        /// - Throws: Any error emitted by the underlying async sequence.
        @concurrent
        public mutating func next() async throws -> ByteBuffer? {
            try await self.base.next(isolation: nil)?.get()
        }
        #else
        /// Returns the next available byte buffer from the sequence.
        ///
        /// - Returns: The next `ByteBuffer`, or `nil` when the sequence is finished.
        /// - Throws: Any error emitted by the underlying async sequence.
        public mutating func next() async throws -> ByteBuffer? {
            try await self.base.next()?.get()
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
            try await self.base.next(isolation: actor)?.get()
        }
    }

    private let makeIteratorCallback: @Sendable () -> BaseAsyncSequence

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
        self.makeIteratorCallback = {
            BaseAsyncSequence { continuation in
                let task = Task {
                    do {
                        for try await element in asyncSequence {
                            continuation.yield(.success(element))
                        }
                    }
                    catch {
                        continuation.yield(.failure(error))
                    }
                    continuation.finish()
                }
                continuation.onTermination = { _ in
                    task.cancel()
                }
            }
        }
    }

    /// Creates an async iterator for consuming the storage sequence.
    ///
    /// - Returns: A new `AsyncIterator` instance.
    public func makeAsyncIterator() -> AsyncIterator {
        AsyncIterator(base: makeIteratorCallback().makeAsyncIterator())
    }
}
