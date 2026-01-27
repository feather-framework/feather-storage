//
//  File.swift
//  feather-storage
//
//  Created by Tibor Bödecs on 2026. 01. 27..
//

import NIOCore

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
