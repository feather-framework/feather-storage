//
//  FeatherStorageTestSuite.swift
//  feather-storage
//
//  Created by Tibor Bodecs on 2023. 01. 16.

import FeatherStorageTesting
import NIOCore
import Testing

@testable import FeatherStorage

@Suite
struct FeatherStorageTestSuite {

    @Test
    func storageClientUploadPreservesContentType() async throws {
        let state = TestStorageState()
        let client = TestStorageClient(state: state)
        let sequence = StorageSequence(
            asyncSequence: [1, 2, 3].byteBufferAsync,
            length: 3
        )

        try await client.upload(
            key: "image.webp",
            sequence: sequence,
            contentType: "image/webp"
        )

        #expect(await state.contentType(for: "image.webp") == "image/webp")
        #expect(await state.objectBytes(for: "image.webp") == [1, 2, 3])
        #expect(await state.objectExists("image.webp"))
    }

    @Test
    func storageClientMoveDeletesSourceOnSuccess() async throws {
        let client = TestStorageClient()
        try await client.upload(
            key: "source",
            sequence: StorageSequence(buffer: ByteBuffer(bytes: [1, 2, 3]))
        )

        try await client.move(key: "source", to: "dest")

        #expect(try await client.exists(key: "source") == false)
        #expect(try await client.exists(key: "dest") == true)
        #expect(try await client.size(key: "dest") == 3)
    }

    @Test
    func storageClientMoveThrowsForMissingSource() async {
        let client = TestStorageClient()
        do {
            try await client.move(key: "missing", to: "dest")
            Issue.record("Expected invalidKey")
        }
        catch StorageClientError.invalidKey {
            // expected
        }
        catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    @Test
    func storageClientMultipartAliasesRouteToUnderlyingMethods() async throws {
        let testClient = TestStorageClient()
        let client: any StorageClient = testClient

        let uploadId = try await client.createMultipartId(
            key: "file",
            contentType: "application/pdf"
        )
        #expect(!uploadId.isEmpty)
        #expect(await testClient.state.hasMultipartUpload(uploadId))

        let partSequence = StorageSequence(
            asyncSequence: [7, 8, 9].byteBufferAsync,
            length: 3
        )
        let part = try await client.upload(
            multipartId: uploadId,
            key: "file",
            number: 1,
            sequence: partSequence
        )

        #expect(!part.id.isEmpty)
        #expect(part.number == 1)

        try await client.finish(
            multipartId: uploadId,
            key: "file",
            chunks: [part]
        )

        #expect(try await client.exists(key: "file") == true)
        #expect(try await client.size(key: "file") == 3)
        #expect(
            await testClient.state.contentType(for: "file") == "application/pdf"
        )
        #expect(await testClient.state.objectBytes(for: "file") == [7, 8, 9])
        #expect(await testClient.state.hasMultipartUpload(uploadId) == false)

        let uploadId2 = try await client.createMultipartId(key: "tmp")
        try await client.abort(multipartId: uploadId2, key: "tmp")
        #expect(await testClient.state.hasMultipartUpload(uploadId2) == false)

    }

}
