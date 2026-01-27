//
//  File.swift
//  feather-storage
//
//  Created by Tibor Bödecs on 2026. 01. 27..
//

import NIOCore

public struct StorageByteBufferAsyncSequenceWrapper: Sendable, AsyncSequence {

    public typealias Element = ByteBuffer

    let buffer: ByteBuffer

    public init(
        buffer: ByteBuffer
    ) {
        self.buffer = buffer
    }

    public struct AsyncIterator: AsyncIteratorProtocol {
        let buffer: ByteBuffer
        var currentIndex: Int = 0

        public mutating func next() async -> ByteBuffer? {
            guard currentIndex < buffer.readableBytes else {
                return nil
            }

            let endIndex = Swift.min(
                currentIndex + 32 * 1024,
                buffer.readableBytes
            )
            let chunkRange = currentIndex..<endIndex

            var chunk = buffer
            chunk.moveReaderIndex(to: chunkRange.lowerBound)
            chunk.moveWriterIndex(to: chunkRange.upperBound)

            currentIndex = endIndex
            return chunk
        }
    }

    public func makeAsyncIterator() -> AsyncIterator {
        AsyncIterator(buffer: buffer)
    }
}
