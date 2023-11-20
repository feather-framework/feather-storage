//
//  StorageService.swift
//  FeatherStorage
//
//  Created by Tibor Bodecs on 2020. 04. 28..
//

import FeatherService
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

/// storage service protocol
public protocol StorageService: Service {

    /// returns the available storage space
    var availableSpace: UInt64 { get }

    /// uploads the data using a key
    func upload(
        key: String,
        buffer: ByteBuffer
    ) async throws

    /// download a given object data using a key
    func download(
        key: String,
        range: ClosedRange<UInt>?
    ) async throws -> ByteBuffer

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

extension StorageService {

    public func move(
        key source: String,
        to destination: String
    ) async throws {
        let exists = await exists(key: source)
        guard exists else {
            throw StorageServiceError.invalidKey
        }
        try await copy(key: source, to: destination)
        try await delete(key: source)
    }
}
