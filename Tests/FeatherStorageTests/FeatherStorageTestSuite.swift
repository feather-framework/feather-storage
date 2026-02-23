//
//  FeatherStorageTestSuite.swift
//  feather-storage
//
//  Created by Tibor Bodecs on 2023. 01. 16.

import NIOCore
import Testing

@testable import FeatherStorage

@Suite
struct FeatherStorageTestSuite {

    @Test
    func storageClientMoveDeletesSourceOnSuccess() async throws {
        let client = MockStorageClient()
        await client.setObject(key: "source", values: [1, 2, 3])

        try await client.move(key: "source", to: "dest")

        #expect(try await client.exists(key: "source") == false)
        #expect(try await client.exists(key: "dest") == true)
        #expect(try await client.size(key: "dest") == 3)
    }

    @Test
    func storageClientMoveThrowsForMissingSource() async {
        let client = MockStorageClient()
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
        let client: any StorageClient = MockStorageClient()

        let uploadId = try await client.createMultipartId(key: "file")
        #expect(uploadId == "mp-file")

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

        #expect(part.id == "file-1")
        #expect(part.number == 1)

        try await client.finish(
            multipartId: uploadId,
            key: "file",
            chunks: [part]
        )

        #expect(try await client.exists(key: "file") == true)
        #expect(try await client.size(key: "file") == 3)

        let uploadId2 = try await client.createMultipartId(key: "tmp")
        try await client.abort(multipartId: uploadId2, key: "file")

    }

}
