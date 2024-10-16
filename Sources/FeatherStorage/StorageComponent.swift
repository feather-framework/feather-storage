//
//  StorageComponent.swift
//  FeatherStorage
//
//  Created by Tibor Bodecs on 2020. 04. 28..
//

import FeatherComponent
import NIOCore

/// storage chunks returned used by the multipart request apis
public struct StorageChunk: Hashable, Codable, Sendable, Equatable {
    public let chunkId: String
    public let number: Int

    public init(
        chunkId: String,
        number: Int
    ) {
        self.chunkId = chunkId
        self.number = number
    }
}

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

    @usableFromInline var makeAsyncIteratorCallback:
        @Sendable () -> AsyncIteratorNextCallback

    @inlinable public init<SequenceOfBytes>(
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
                if var buffer = try await iterator.next() {
                    return ArraySlice(
                        buffer.readBytes(length: buffer.readableBytes) ?? []
                    )
                }
                return nil
            }
        }
        self.length = length
    }

    @inlinable public init<SequenceOfBytes>(
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
                if let arraySlice = try await iterator.next() {
                    var byteBuffer = ByteBufferAllocator()
                        .buffer(capacity: arraySlice.count)
                    byteBuffer.writeBytes(arraySlice)
                    return byteBuffer
                }
                return nil
            }
        }
        self.length = length
    }

    @inlinable public init<SequenceOfBytes>(
        asyncSequence: SequenceOfBytes,
        length: UInt64?
    )
    where
        SequenceOfBytes: AsyncSequence & Sendable,
        SequenceOfBytes.Element == Element
    {
        self.makeAsyncIteratorCallback = {
            var iterator = asyncSequence.makeAsyncIterator()
            return {
                try await iterator.next()
            }
        }
        self.length = length
    }

    @inlinable public func makeAsyncIterator() -> AsyncIterator {
        .init(nextCallback: self.makeAsyncIteratorCallback())
    }
}

/// storage component protocol
public protocol StorageComponent: Component {

    /// returns the available storage space
    var availableSpace: UInt64 { get }

    /// uploads the data using a key
    func upload(
        key: String,
        buffer: ByteBuffer
    ) async throws

    /// uploads the data using a key via async sequence
    func uploadStream(
        key: String,
        sequence: StorageAnyAsyncSequence<ByteBuffer>
    ) async throws

    /// download a given object data using a key
    func download(
        key: String,
        range: ClosedRange<Int>?
    ) async throws -> ByteBuffer

    /// download a given object data using a key via async sequence
    func downloadStream(
        key: String,
        range: ClosedRange<Int>?
    ) async throws -> StorageAnyAsyncSequence<ByteBuffer>

    /// check if a given key exists
    func exists(
        key: String
    ) async -> Bool

    /// get the size of an object
    func size(
        key: String
    ) async -> UInt64

    /// copy an object using a source and a destination key
    func copy(
        key: String,
        to: String
    ) async throws

    /// move an object using a source and a destination key
    func move(
        key: String,
        to: String
    ) async throws

    /// list the contents under a given key
    func list(
        key: String?
    ) async throws -> [String]

    /// removes the data under the given key
    func delete(
        key: String
    ) async throws

    /// creates a new directory using a key
    func create(
        key: String
    ) async throws

    // MARK: - multipart

    /// creates a new multipart upload identifier
    func createMultipartId(
        key: String
    ) async throws -> String

    /// upload a multipart chunk
    func upload(
        multipartId: String,
        key: String,
        number: Int,
        buffer: ByteBuffer
    ) async throws -> StorageChunk

    /// upload a multipart chunk via async sequence
    func uploadStream(
        multipartId: String,
        key: String,
        number: Int,
        sequence: StorageAnyAsyncSequence<ByteBuffer>
    ) async throws -> StorageChunk

    /// abort a multipart upload
    func abort(
        multipartId: String,
        key: String
    ) async throws

    /// finish a multipart upload
    func finish(
        multipartId: String,
        key: String,
        chunks: [StorageChunk]
    ) async throws
}

public struct StorageByteBufferAsyncSequenceWrapper: Sendable, AsyncSequence {
    public typealias Element = ByteBuffer
    let buffer: ByteBuffer

    public init(buffer: ByteBuffer) {
        self.buffer = buffer
    }

    public struct AsyncIterator: AsyncIteratorProtocol {
        var buffer: ByteBuffer?

        public mutating func next() async -> ByteBuffer? {
            let ret = buffer
            buffer = nil
            return ret
        }
    }

    public func makeAsyncIterator() -> AsyncIterator {
        AsyncIterator(buffer: (buffer.readableBytes > 0 ? buffer : nil))
    }
}

extension StorageComponent {

    public func move(
        key source: String,
        to destination: String
    ) async throws {
        let exists = await exists(key: source)
        guard exists else {
            throw StorageComponentError.invalidKey
        }
        try await copy(key: source, to: destination)
        try await delete(key: source)
    }

    public func upload(
        key: String,
        buffer: ByteBuffer
    ) async throws {
        try await uploadStream(
            key: key,
            sequence: .init(
                asyncSequence: StorageByteBufferAsyncSequenceWrapper(
                    buffer: buffer
                ),
                length: UInt64(buffer.readableBytes)
            )
        )
    }

    public func download(
        key: String,
        range: ClosedRange<Int>?
    ) async throws -> ByteBuffer {
        try await downloadStream(key: key, range: range).collect(upTo: Int.max)
    }

    public func upload(
        multipartId: String,
        key: String,
        number: Int,
        buffer: ByteBuffer
    ) async throws -> StorageChunk {
        try await uploadStream(
            multipartId: multipartId,
            key: key,
            number: number,
            sequence: .init(
                asyncSequence: StorageByteBufferAsyncSequenceWrapper(
                    buffer: buffer
                ),
                length: UInt64(buffer.readableBytes)
            )
        )
    }
}
