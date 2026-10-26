public import FeatherStorage
import NIOCore

/// An actor-backed in-memory `StorageClient` for tests and previews.
public struct TestStorageClient: StorageClient {

    public let state: TestStorageState

    /// Creates a test client using the supplied or a new storage state.
    public init(state: TestStorageState = TestStorageState()) {
        self.state = state
    }

    /// Returns the content type recorded for an object upload.
    public func contentType(for key: String) async -> String? {
        await state.contentType(for: key)
    }

    /// Returns whether a multipart upload is still active.
    public func multipartExists(_ id: String) async -> Bool {
        await state.hasMultipartUpload(id)
    }

    public func upload(
        key: String,
        sequence: StorageSequence,
        contentType: String?
    ) async throws(StorageClientError) {
        do {
            let object = try await sequence.collect(upTo: .max)
            await state.putObject(key, buffer: object, contentType: contentType)
        }
        catch let error as StorageClientError {
            throw error
        }
        catch {
            throw .unknown(error)
        }
    }

    public func download(
        key: String,
        range: ClosedRange<Int>?
    ) async throws(StorageClientError) -> StorageSequence {
        guard var object = await state.object(for: key)?.buffer else {
            throw .invalidKey
        }

        if let range {
            guard range.lowerBound >= 0, range.upperBound < object.readableBytes
            else {
                throw .invalidBuffer
            }
            object.moveReaderIndex(to: range.lowerBound)
            let length = range.upperBound - range.lowerBound + 1
            guard let bytes = object.readBytes(length: length) else {
                throw .invalidBuffer
            }
            object = ByteBuffer(bytes: bytes)
        }

        return StorageSequence(
            asyncSequence: ByteBufferSequence(buffer: object),
            length: UInt64(object.readableBytes)
        )
    }

    public func exists(key: String) async throws(StorageClientError) -> Bool {
        await state.objectExists(key)
    }

    public func size(key: String) async throws(StorageClientError) -> UInt64 {
        await state.objectSize(key)
    }

    public func copy(
        key source: String,
        to destination: String
    ) async throws(StorageClientError) {
        try await state.copyObject(source: source, destination: destination)
    }

    public func list(key: String?) async throws(StorageClientError) -> [String] {
        await state.listEntries(prefix: key)
    }

    public func delete(key: String) async throws(StorageClientError) {
        await state.remove(key)
    }

    public func create(key: String) async throws(StorageClientError) {
        await state.createDirectory(key)
    }

    public func createMultipartId(
        key: String,
        contentType: String?
    ) async throws(StorageClientError) -> String {
        await state.createMultipartUpload(for: key, contentType: contentType)
    }

    public func upload(
        multipartId: String,
        key: String,
        number: Int,
        sequence: StorageSequence
    ) async throws(StorageClientError) -> StorageMultipartChunk {
        do {
            let part = try await sequence.collect(upTo: .max)
            return try await state.addMultipartPart(
                uploadId: multipartId,
                key: key,
                number: number,
                buffer: part
            )
        }
        catch let error as StorageClientError {
            throw error
        }
        catch {
            throw .unknown(error)
        }
    }

    public func abort(
        multipartId: String,
        key: String
    ) async throws(StorageClientError) {
        try await state.abortMultipartUpload(uploadId: multipartId, key: key)
    }

    public func finish(
        multipartId: String,
        key: String,
        chunks: [StorageMultipartChunk]
    ) async throws(StorageClientError) {
        try await state.finishMultipartUpload(
            uploadId: multipartId,
            key: key,
            chunks: chunks
        )
    }
}
