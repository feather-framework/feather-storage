import FeatherStorage
import NIOCore

public actor TestStorageState {

    struct StoredObject {
        let buffer: ByteBuffer
        let contentType: String?
    }

    struct MultipartUpload {
        let key: String
        let contentType: String?
        var parts: [Int: StoredPart]
    }

    struct StoredPart {
        let chunkId: String
        let buffer: ByteBuffer
    }

    private var objects: [String: StoredObject] = [:]
    private var directories: Set<String> = [""]
    private var multipartUploads: [String: MultipartUpload] = [:]
    private var nextUploadId = 1
    private var nextChunkId = 1

    /// Creates an empty test storage state.
    public init() {}

    func putObject(
        _ key: String,
        buffer: ByteBuffer,
        contentType: String?
    ) {
        objects[key] = .init(buffer: buffer, contentType: contentType)
        ensureParentDirectories(for: key)
    }

    func object(for key: String) -> StoredObject? {
        objects[key]
    }

    /// Returns the stored bytes for an object, or `nil` when it is absent.
    public func objectBytes(for key: String) -> [UInt8]? {
        guard let object = objects[key] else { return nil }
        return object.buffer.getBytes(
            at: object.buffer.readerIndex,
            length: object.buffer.readableBytes
        )
    }

    /// Returns whether an object or directory exists at the given key.
    public func objectExists(_ key: String) -> Bool {
        objects[key] != nil
            || directories.contains(Self.normalizeDirectoryKey(key))
    }

    /// Returns the stored object's byte count, or zero when it is absent.
    public func objectSize(_ key: String) -> UInt64 {
        UInt64(objects[key]?.buffer.readableBytes ?? 0)
    }

    /// Returns the content type recorded for an object.
    public func contentType(for key: String) -> String? {
        objects[key]?.contentType
    }

    /// Returns the immediate child entries below a prefix.
    public func list(prefix: String?) -> [String] {
        listEntries(prefix: prefix)
    }

    /// Returns whether a multipart upload is still active.
    public func hasMultipartUpload(_ id: String) -> Bool {
        multipartUploads[id] != nil
    }

    /// Returns the active multipart upload identifiers in sorted order.
    public func multipartUploadIDs() -> [String] {
        multipartUploads.keys.sorted()
    }

    /// Removes all objects, directories, and multipart uploads.
    public func clear() {
        objects.removeAll()
        directories = [""]
        multipartUploads.removeAll()
        nextUploadId = 1
        nextChunkId = 1
    }

    func remove(_ key: String) {
        let normalizedDirectory = Self.normalizeDirectoryKey(key)
        objects = objects.filter { objectKey, _ in
            !(objectKey == key
                || objectKey.hasPrefix(normalizedDirectory + "/"))
        }
        directories = directories.filter { directoryKey in
            !(directoryKey == normalizedDirectory
                || directoryKey.hasPrefix(normalizedDirectory + "/"))
        }
    }

    func copyObject(
        source: String,
        destination: String
    ) throws(StorageClientError) {
        guard let sourceObject = objects[source] else {
            throw .invalidKey
        }
        objects[destination] = sourceObject
        ensureParentDirectories(for: destination)
    }

    func createDirectory(_ key: String) {
        let normalized = Self.normalizeDirectoryKey(key)
        directories.insert(normalized)
        ensureParentDirectories(for: normalized)
    }

    func listEntries(prefix: String?) -> [String] {
        let normalizedPrefix = prefix.map(Self.normalizeDirectoryKey)
        let rootPrefix =
            normalizedPrefix.map {
                $0.isEmpty ? "" : $0 + "/"
            } ?? ""
        var entries: Set<String> = []

        for objectKey in objects.keys where objectKey.hasPrefix(rootPrefix) {
            let remainder = String(objectKey.dropFirst(rootPrefix.count))
            guard !remainder.isEmpty else { continue }
            if let component =
                remainder
                .split(separator: "/", maxSplits: 1)
                .first
            {
                entries.insert(String(component))
            }
        }

        for directory in directories where directory.hasPrefix(rootPrefix) {
            let remainder = String(directory.dropFirst(rootPrefix.count))
            guard !remainder.isEmpty else { continue }
            if let component =
                remainder
                .split(separator: "/", maxSplits: 1)
                .first
            {
                entries.insert(String(component))
            }
        }

        return entries.sorted()
    }

    func createMultipartUpload(
        for key: String,
        contentType: String?
    ) -> String {
        let id = "upload-\(nextUploadId)"
        nextUploadId += 1
        multipartUploads[id] = .init(
            key: key,
            contentType: contentType,
            parts: [:]
        )
        ensureParentDirectories(for: key)
        return id
    }

    func addMultipartPart(
        uploadId: String,
        key: String,
        number: Int,
        buffer: ByteBuffer
    ) throws(StorageClientError) -> StorageMultipartChunk {
        guard number > 0 else {
            throw .invalidMultipartChunk
        }
        guard var upload = multipartUploads[uploadId], upload.key == key else {
            throw .invalidMultipartId
        }

        let chunkId = "chunk-\(nextChunkId)"
        nextChunkId += 1
        upload.parts[number] = .init(chunkId: chunkId, buffer: buffer)
        multipartUploads[uploadId] = upload
        return .init(id: chunkId, number: number)
    }

    func abortMultipartUpload(
        uploadId: String,
        key: String
    ) throws(StorageClientError) {
        guard multipartUploads[uploadId]?.key == key else {
            throw .invalidMultipartId
        }
        multipartUploads.removeValue(forKey: uploadId)
    }

    func finishMultipartUpload(
        uploadId: String,
        key: String,
        chunks: [StorageMultipartChunk]
    ) throws(StorageClientError) {
        guard let upload = multipartUploads[uploadId], upload.key == key else {
            throw .invalidMultipartId
        }

        var result = ByteBufferAllocator().buffer(capacity: 0)
        for chunk in chunks.sorted(by: { $0.number < $1.number }) {
            guard let part = upload.parts[chunk.number],
                part.chunkId == chunk.id
            else {
                throw .invalidMultipartChunk
            }
            var buffer = part.buffer
            result.writeBuffer(&buffer)
        }

        objects[key] = .init(buffer: result, contentType: upload.contentType)
        ensureParentDirectories(for: key)
        multipartUploads.removeValue(forKey: uploadId)
    }

    private func ensureParentDirectories(for key: String) {
        let parts = key.split(separator: "/").map(String.init)
        guard parts.count > 1 else { return }

        var current = ""
        for part in parts.dropLast() {
            current = current.isEmpty ? part : current + "/" + part
            directories.insert(current)
        }
    }

    private static func normalizeDirectoryKey(_ key: String) -> String {
        key.split(separator: "/").filter { !$0.isEmpty }.joined(separator: "/")
    }
}
