//
//  ByteBufferSequenceTestSuite.swift
//  feather-storage
//
//  Created by Tibor Bodecs on 2023. 01. 16.

import NIOCore
import Testing

@testable import FeatherStorage

@Suite
struct ByteBufferSequenceTestSuite {

    @Test
    func yieldsChunksUsingConfiguredChunkSize() async {
        let allocator = ByteBufferAllocator()
        var buffer = allocator.buffer(capacity: 10)
        buffer.writeBytes([1, 2, 3, 4, 5, 6, 7, 8, 9, 10])

        let sequence = ByteBufferSequence(buffer: buffer, chunkSize: 4)
        var iterator = sequence.makeAsyncIterator()

        let first = await iterator.next()
        let second = await iterator.next()
        let third = await iterator.next()
        let end = await iterator.next()

        #expect(Self.readBytes(first) == [1, 2, 3, 4])
        #expect(Self.readBytes(second) == [5, 6, 7, 8])
        #expect(Self.readBytes(third) == [9, 10])
        #expect(end == nil)
    }

    @Test
    func emptyBufferReturnsNilImmediately() async {
        let allocator = ByteBufferAllocator()
        let buffer = allocator.buffer(capacity: 0)

        let sequence = ByteBufferSequence(buffer: buffer)
        var iterator = sequence.makeAsyncIterator()

        #expect(await iterator.next() == nil)
    }

    private static func readBytes(_ buffer: ByteBuffer?) -> [UInt8] {
        guard var value = buffer else {
            return []
        }
        return value.readBytes(length: value.readableBytes) ?? []
    }
}
