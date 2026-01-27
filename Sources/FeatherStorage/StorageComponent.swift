//
//  StorageComponent.swift
//  FeatherStorage
//
//  Created by Tibor Bodecs on 2020. 04. 28..
//

import NIOCore

/// storage component protocol
public protocol StorageComponent {

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


