//
//  File.swift
//  feather-storage
//
//  Created by Tibor Bödecs on 2026. 01. 27..
//

import NIOCore

/// storage any async sequence
public struct StorageAnyAsyncSequence<Element>: Sendable, AsyncSequence {
    public typealias ByteChunk = ArraySlice<UInt8>

    public typealias AsyncIteratorNextCallback = () async throws -> Element?
    public let length: UInt64?

    public struct AsyncIterator: AsyncIteratorProtocol {
        @usableFromInline let nextCallback: AsyncIteratorNextCallback

        @inlinable init(nextCallback: @escaping AsyncIteratorNextCallback) {
            self.nextCallback = nextCallback
        }

        @inlinable public mutating func next() async throws -> Element? {
            try await self.nextCallback()
        }
    }

    @usableFromInline var makeAsyncIteratorCallback: @Sendable () -> AsyncIteratorNextCallback

    @inlinable
    public init<SequenceOfBytes>(
        asyncSequence: SequenceOfBytes,
        length: UInt64?
    )
    where
        SequenceOfBytes: AsyncSequence & Sendable,
        SequenceOfBytes.Element == ByteBuffer,
        Element == ByteChunk
    {
        self.makeAsyncIteratorCallback = {
            var iterator = asyncSequence.makeAsyncIterator()
            return {
//                if var buffer = try await iterator.next() {
//                    return ArraySlice(
//                        buffer.readBytes(length: buffer.readableBytes) ?? []
//                    )
//                }
                return nil
            }
        }
        self.length = length
    }

    @inlinable
    public init<SequenceOfBytes>(
        asyncSequence: SequenceOfBytes,
        length: UInt64?
    )
    where
        SequenceOfBytes: AsyncSequence & Sendable,
        SequenceOfBytes.Element == ByteChunk,
        Element == ByteBuffer
    {
        self.makeAsyncIteratorCallback = {
            var iterator = asyncSequence.makeAsyncIterator()
            return {
//                if let arraySlice = try await iterator.next() {
//                    var byteBuffer = ByteBufferAllocator()
//                        .buffer(capacity: arraySlice.count)
//                    byteBuffer.writeBytes(arraySlice)
//                    return byteBuffer
//                }
                return nil
            }
        }
        self.length = length
    }

    @inlinable
    public init<SequenceOfBytes>(
        asyncSequence: SequenceOfBytes,
        length: UInt64?
    )
    where
        SequenceOfBytes: AsyncSequence & Sendable,
        SequenceOfBytes.Element == Element
    {
        self.makeAsyncIteratorCallback = {
            var iterator = asyncSequence.makeAsyncIterator()
//            return {
//                try await iterator.next()
//            }
            fatalError()
        }
        self.length = length
    }

    @inlinable public func makeAsyncIterator() -> AsyncIterator {
        .init(nextCallback: self.makeAsyncIteratorCallback())
    }
}
