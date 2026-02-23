//
//  StorageSequenceTestSuite.swift
//  feather-storage
//
//  Created by Tibor Bodecs on 2023. 01. 16.

import NIOCore
import Testing

@testable import FeatherStorage

@Suite
struct StorageSequenceTestSuite {

    enum TestError: Error {
        case failed
    }

    @Test
    func initFromAsyncSequencePreservesElementsAndLength() async throws {
        let allocator = ByteBufferAllocator()
        let sequence = StorageSequence(
            asyncSequence: AsyncStream { continuation in
                continuation.yield(Self.makeBuffer([1, 2], allocator: allocator))
                continuation.yield(Self.makeBuffer([3], allocator: allocator))
                continuation.finish()
            },
            length: 3
        )

        var iterator = sequence.makeAsyncIterator()
        let first = try await iterator.next()
        let second = try await iterator.next()
        let end = try await iterator.next()

        #expect(sequence.length == 3)
        #expect(Self.readBytes(first) == [1, 2])
        #expect(Self.readBytes(second) == [3])
        #expect(end == nil)
    }

    @Test
    func initFromAsyncSequenceUsesNilLengthByDefault() {
        let sequence = StorageSequence(asyncSequence: AsyncStream<ByteBuffer> { continuation in
            continuation.finish()
        })

        #expect(sequence.length == nil)
    }

    @Test
    func initFromBufferSetsLengthAndStreamsAllBytes() async throws {
        let allocator = ByteBufferAllocator()
        let sequence = StorageSequence(
            buffer: Self.makeBuffer([9, 8, 7, 6], allocator: allocator)
        )

        var iterator = sequence.makeAsyncIterator()
        let first = try await iterator.next()
        let end = try await iterator.next()

        #expect(sequence.length == 4)
        #expect(Self.readBytes(first) == [9, 8, 7, 6])
        #expect(end == nil)
    }

    @Test
    func initFromThrowingSequencePropagatesErrors() async {
        let allocator = ByteBufferAllocator()
        let sequence = StorageSequence(asyncSequence: AsyncThrowingStream<ByteBuffer, Error> { continuation in
            continuation.yield(Self.makeBuffer([1], allocator: allocator))
            continuation.finish(throwing: TestError.failed)
        })

        var iterator = sequence.makeAsyncIterator()
        do {
            _ = try await iterator.next()
            _ = try await iterator.next()
            Issue.record("Expected TestError.failed")
        }
        catch TestError.failed {
            // expected
        }
        catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    private static func makeBuffer(
        _ bytes: [UInt8],
        allocator: ByteBufferAllocator
    ) -> ByteBuffer {
        var buffer = allocator.buffer(capacity: bytes.count)
        buffer.writeBytes(bytes)
        return buffer
    }

    private static func readBytes(_ buffer: ByteBuffer?) -> [UInt8] {
        guard var value = buffer else {
            return []
        }
        return value.readBytes(length: value.readableBytes) ?? []
    }
}
