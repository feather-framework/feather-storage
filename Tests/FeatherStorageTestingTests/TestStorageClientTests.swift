import FeatherStorage
import FeatherStorageTesting
import NIOCore
import Testing

@Suite
struct TestStorageClientTests {

    @Test
    func uploadAndDownloadExposeBytesAndMetadata() async throws {
        let state = TestStorageState()
        let client = TestStorageClient(state: state)
        try await client.upload(
            key: "docs/hello.txt",
            sequence: sequence([1, 2, 3, 4, 5]),
            contentType: "text/plain"
        )

        #expect(
            await state.objectBytes(for: "docs/hello.txt") == [1, 2, 3, 4, 5]
        )
        #expect(await state.objectSize("docs/hello.txt") == 5)
        #expect(await state.contentType(for: "docs/hello.txt") == "text/plain")
        #expect(await state.objectExists("docs/hello.txt"))

        let fullDownload = try await client.download(
            key: "docs/hello.txt",
            range: nil
        )
        #expect(try await collect(fullDownload) == [1, 2, 3, 4, 5])

        let rangedDownload = try await client.download(
            key: "docs/hello.txt",
            range: 1...3
        )
        #expect(try await collect(rangedDownload) == [2, 3, 4])
    }

    @Test
    func downloadReportsMissingObjectsAndInvalidRanges() async throws {
        let client = TestStorageClient()

        do {
            _ = try await client.download(key: "missing", range: nil)
            Issue.record("Expected a missing object to throw invalidKey.")
        }
        catch StorageClientError.invalidKey {
            // Expected missing object.
        }
        catch {
            Issue.record("Unexpected storage error: \(error)")
        }

        try await client.upload(
            key: "short.txt",
            sequence: sequence([1, 2, 3])
        )

        do {
            _ = try await client.download(key: "short.txt", range: 0...3)
            Issue.record(
                "Expected an out-of-bounds range to throw invalidBuffer."
            )
        }
        catch StorageClientError.invalidBuffer {
            // Expected invalid range.
        }
        catch {
            Issue.record("Unexpected storage error: \(error)")
        }
    }

    @Test
    func directoryListingAndRecursiveDeleteAreVisibleInState() async throws {
        let state = TestStorageState()
        let client = TestStorageClient(state: state)

        try await client.create(key: "docs/nested")
        try await client.upload(
            key: "docs/nested/a.txt",
            sequence: sequence([1])
        )
        try await client.upload(key: "docs/b.txt", sequence: sequence([2]))

        #expect(try await client.list(key: "docs") == ["b.txt", "nested"])
        #expect(await state.list(prefix: "docs/nested") == ["a.txt"])

        try await client.delete(key: "docs")

        #expect(await state.objectBytes(for: "docs/nested/a.txt") == nil)
        #expect(await state.objectExists("docs") == false)
        #expect(await state.list(prefix: nil).isEmpty)
    }

    @Test
    func multipartStateTracksFinishAndAbort() async throws {
        let state = TestStorageState()
        let client = TestStorageClient(state: state)
        let uploadId = try await client.createMultipartId(
            key: "bundle.bin",
            contentType: "application/octet-stream"
        )

        #expect(await state.multipartUploadIDs() == [uploadId])

        let first = try await client.upload(
            multipartId: uploadId,
            key: "bundle.bin",
            number: 1,
            sequence: sequence([1, 2])
        )
        let second = try await client.upload(
            multipartId: uploadId,
            key: "bundle.bin",
            number: 2,
            sequence: sequence([3, 4])
        )
        try await client.finish(
            multipartId: uploadId,
            key: "bundle.bin",
            chunks: [first, second]
        )

        #expect(await state.objectBytes(for: "bundle.bin") == [1, 2, 3, 4])
        #expect(
            await state.contentType(for: "bundle.bin")
                == "application/octet-stream"
        )
        #expect(await state.multipartUploadIDs().isEmpty)

        let abortedId = try await client.createMultipartId(key: "aborted.bin")
        try await client.abort(multipartId: abortedId, key: "aborted.bin")
        #expect(await state.hasMultipartUpload(abortedId) == false)
    }

    private func sequence(_ bytes: [UInt8]) -> StorageSequence {
        StorageSequence(buffer: ByteBuffer(bytes: bytes))
    }

    private func collect(_ sequence: StorageSequence) async throws -> [UInt8] {
        var result: [UInt8] = []
        for try await chunk in sequence {
            var buffer = chunk
            result.append(
                contentsOf: buffer.readBytes(length: buffer.readableBytes) ?? []
            )
        }
        return result
    }
}
