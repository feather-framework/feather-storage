//
//  File.swift
//  feather-storage
//
//  Created by Tibor Bödecs on 2026. 01. 27..
//

import NIOCore

public struct ByteBufferSequence: Sendable, AsyncSequence {

    public typealias Element = ByteBuffer

    let buffer: ByteBuffer
    let chunkSize: Int

    public init(
        buffer: ByteBuffer,
        chunkSize: Int = 32 * 1024
    ) {
        self.buffer = buffer
        self.chunkSize = chunkSize
    }

    public struct AsyncIterator: AsyncIteratorProtocol {
        let buffer: ByteBuffer
        let chunkSize: Int
        var currentIndex: Int = 0
        
        public mutating func next() async -> ByteBuffer? {
            guard currentIndex < buffer.readableBytes else {
                return nil
            }
            let endIndex = Swift.min(
                currentIndex + chunkSize,
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
        AsyncIterator(
            buffer: buffer,
            chunkSize: chunkSize
        )
    }
}
