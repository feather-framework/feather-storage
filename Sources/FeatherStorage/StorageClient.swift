//
//  StorageClient.swift
//  feather-storage
//
//  Created by Tibor Bodecs on 2023. 01. 16.

/// High-level storage abstraction used by all Feather storage drivers.
public protocol StorageClient: Sendable {

    /// Uploads an object for the given key from an asynchronous byte stream.
    ///
    /// - Parameters:
    ///   - key: The destination object key.
    ///   - sequence: The source byte stream to upload.
    /// - Throws: `StorageClientError` if the upload fails.
    func upload(
        key: String,
        sequence: StorageSequence
    ) async throws(StorageClientError)

    /// Downloads an object as an asynchronous byte stream.
    ///
    /// - Parameters:
    ///   - key: The object key to download.
    ///   - range: Optional inclusive byte range (`start...end`) to download.
    /// - Returns: A byte sequence for the requested object content.
    /// - Throws: `StorageClientError` if the object cannot be downloaded.
    func download(
        key: String,
        range: ClosedRange<Int>?
    ) async throws(StorageClientError) -> StorageSequence

    /// Checks whether an object exists at the given key.
    ///
    /// - Parameter key: The object key to check.
    /// - Returns: `true` if the object exists, otherwise `false`.
    /// - Throws: `StorageClientError` if the object cannot be downloaded.
    func exists(
        key: String
    ) async throws(StorageClientError) -> Bool

    /// Returns the size of an object in bytes.
    ///
    /// - Parameter key: The object key to inspect.
    /// - Returns: The object size in bytes, or `0` when the key does not resolve to an object.
    /// - Throws: `StorageClientError` if the object cannot be downloaded.
    func size(
        key: String
    ) async throws(StorageClientError) -> UInt64

    /// Copies an object from one key to another.
    ///
    /// - Parameters:
    ///   - source: The source object key.
    ///   - destination: The destination object key.
    /// - Throws: `StorageClientError` if the copy fails.
    func copy(
        key source: String,
        to destination: String
    ) async throws(StorageClientError)

    /// Lists keys under a prefix.
    ///
    /// - Parameter key: Optional prefix key to list from. Pass `nil` to list from the root.
    /// - Returns: An array of matching keys.
    /// - Throws: `StorageClientError` if listing fails.
    func list(
        key: String?
    ) async throws(StorageClientError) -> [String]

    /// Deletes an object or prefix key.
    ///
    /// - Parameter key: The key to delete.
    /// - Throws: `StorageClientError` if deletion fails.
    func delete(
        key: String
    ) async throws(StorageClientError)

    /// Creates a directory-like prefix when supported by the storage driver.
    ///
    /// - Parameter key: The prefix key to create.
    /// - Throws: `StorageClientError` if creation fails.
    func create(
        key: String
    ) async throws(StorageClientError)

    /// Starts a multipart upload session.
    ///
    /// - Parameter key: The destination object key for the multipart upload.
    /// - Returns: The multipart upload identifier.
    /// - Throws: `StorageClientError` if the session cannot be created.
    func createMultipartId(
        key: String
    ) async throws(StorageClientError) -> String

    /// Uploads a single multipart chunk from an asynchronous byte stream.
    ///
    /// - Parameters:
    ///   - multipartId: The multipart upload session identifier.
    ///   - key: The destination object key.
    ///   - number: The part number to upload.
    ///   - sequence: The source byte stream for this chunk.
    /// - Returns: The uploaded chunk descriptor.
    /// - Throws: `StorageClientError` if the chunk upload fails.
    func upload(
        multipartId: String,
        key: String,
        number: Int,
        sequence: StorageSequence
    ) async throws(StorageClientError) -> StorageMultipartChunk

    /// Aborts an in-progress multipart upload session.
    ///
    /// - Parameters:
    ///   - multipartId: The multipart upload session identifier.
    ///   - key: The destination object key.
    /// - Throws: `StorageClientError` if the abort operation fails.
    func abort(
        multipartId: String,
        key: String
    ) async throws(StorageClientError)

    /// Completes a multipart upload using uploaded chunk descriptors.
    ///
    /// - Parameters:
    ///   - multipartId: The multipart upload session identifier.
    ///   - key: The destination object key.
    ///   - chunks: Ordered multipart chunk descriptors to finalize.
    /// - Throws: `StorageClientError` if completion fails.
    func finish(
        multipartId: String,
        key: String,
        chunks: [StorageMultipartChunk]
    ) async throws(StorageClientError)
}

extension StorageClient {

    /// Moves an object from one key to another by copying then deleting the source.
    ///
    /// - Parameters:
    ///   - source: The source object key.
    ///   - destination: The destination object key.
    /// - Throws: `StorageClientError.invalidKey` if the source does not exist, or another `StorageClientError`
    ///   if copy or delete fails.
    public func move(
        key source: String,
        to destination: String
    ) async throws(StorageClientError) {
        guard try await exists(key: source) else {
            throw .invalidKey
        }
        try await copy(key: source, to: destination)
        try await delete(key: source)
    }
}
