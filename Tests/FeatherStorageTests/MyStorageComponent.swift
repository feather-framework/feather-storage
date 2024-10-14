//
//  MyStorageComponent.swift
//  FeatherStorageTests
//
//  Created by Tibor Bödecs on 29/11/2023.
//

import FeatherComponent
import FeatherStorage
import NIOCore

struct MyStorageComponent: StorageComponent {

    var config: ComponentConfig
    var availableSpace: UInt64

    func upload(key: String, buffer: ByteBuffer) async throws {
        fatalError()
    }

    func uploadStream(
        key: String,
        sequence: FeatherStorage.StorageAnyAsyncSequence<NIOCore.ByteBuffer>
    ) async throws {
        fatalError()
    }

    func download(
        key: String,
        range: ClosedRange<Int>?
    ) async throws -> ByteBuffer {
        fatalError()
    }

    func downloadStream(key: String, range: ClosedRange<Int>?) async throws
        -> FeatherStorage.StorageAnyAsyncSequence<NIOCore.ByteBuffer>
    {
        fatalError()
    }

    func exists(key: String) async -> Bool {
        fatalError()
    }

    func size(key: String) async -> UInt64 {
        fatalError()
    }

    func copy(key: String, to: String) async throws {
        fatalError()
    }

    func list(key: String?) async throws -> [String] {
        fatalError()
    }

    func delete(key: String) async throws {
        fatalError()
    }

    func create(key: String) async throws {
        fatalError()
    }

    func createMultipartId(key: String) async throws -> String {
        fatalError()
    }

    func upload(
        multipartId: String,
        key: String,
        number: Int,
        buffer: ByteBuffer
    ) async throws -> StorageChunk {
        fatalError()
    }

    func uploadStream(
        multipartId: String,
        key: String,
        number: Int,
        sequence: FeatherStorage.StorageAnyAsyncSequence<NIOCore.ByteBuffer>
    ) async throws -> FeatherStorage.StorageChunk {
        fatalError()
    }

    func abort(multipartId: String, key: String) async throws {
        fatalError()
    }

    func finish(
        multipartId: String,
        key: String,
        chunks: [StorageChunk]
    ) async throws {
        fatalError()
    }
}
