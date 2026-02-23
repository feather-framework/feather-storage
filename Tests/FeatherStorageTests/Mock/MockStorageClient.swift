//
//  File.swift
//  feather-storage
//
//  Created by Tibor Bödecs on 2026. 02. 23..
//

import NIOCore
import FeatherStorage

extension Array where Element: Sendable {
    var async: AsyncStream<Element> {
        AsyncStream { continuation in
            for element in self {
                continuation.yield(element)
            }
            continuation.finish()
        }
    }
}

extension Array where Element == Int {
    var byteBufferAsync: AsyncStream<ByteBuffer> {
        let values = self
        return AsyncStream { continuation in
            let allocator = ByteBufferAllocator()
            for value in values {
                var buffer = allocator.buffer(capacity: 1)
                buffer.writeInteger(UInt8(value))
                continuation.yield(buffer)
            }
            continuation.finish()
        }
    }
}


struct MockStorageClient: StorageClient {

    let state = MockStorageState()

    func setObject(
        key: String,
        values: [Int]
    ) async {
        await state.setObject(key, values: values)
    }

    func multipartExists(
        _ id: String
    ) async -> Bool {
        await state.hasMultipart(id)
    }

    func upload(
        key: String,
        sequence: StorageSequence
    ) async throws(StorageClientError) {
        let values: [Int]
        do {
            values = try await decodeValues(from: sequence)
        }
        catch {
            throw .unknown(error)
        }
        await state.setObject(key, values: values)
    }

    func download(
        key: String,
        range: ClosedRange<Int>?
    ) async throws(StorageClientError) -> StorageSequence {
        guard let object = await state.object(for: key) else {
            throw .invalidKey
        }
        var values = object
        if let range {
            guard range.lowerBound >= 0, range.upperBound < object.count else {
                throw .invalidBuffer
            }
            values = Array(object[range])
        }
        return StorageSequence(
            asyncSequence: values.byteBufferAsync,
            length: UInt64(values.count)
        )
    }

    func exists(
        key: String
    ) async throws(StorageClientError) -> Bool {
        await state.hasObject(key)
    }

    func size(
        key: String
    ) async throws(StorageClientError) -> UInt64 {
        UInt64(await state.objectSize(for: key))
    }

    func copy(
        key source: String,
        to destination: String
    ) async throws(StorageClientError) {
        guard let values = await state.object(for: source) else {
            throw .invalidKey
        }
        await state.setObject(destination, values: values)
    }

    func list(
        key: String?
    ) async throws(StorageClientError) -> [String] {
        let prefix = key ?? ""
        return await state.listKeys(prefix: prefix)
    }

    func delete(
        key: String
    ) async throws(StorageClientError) {
        await state.deleteObject(key)
    }

    func create(
        key: String
    ) async throws(StorageClientError) {
        await state.setObject(key, values: [])
    }

    func createMultipartId(
        key: String
    ) async throws(StorageClientError) -> String {
        let id = "mp-\(key)"
        await state.createMultipart(id: id)
        return id
    }

    func upload(
        multipartId: String,
        key: String,
        number: Int,
        sequence: StorageSequence
    ) async throws(StorageClientError) -> StorageMultipartChunk {
        guard await state.hasMultipart(multipartId) else {
            throw .invalidMultipartId
        }
        let values: [Int]
        do {
            values = try await decodeValues(from: sequence)
        }
        catch {
            throw .unknown(error)
        }
        await state.setMultipartPart(
            id: multipartId,
            number: number,
            values: values
        )
        return StorageMultipartChunk(id: "\(key)-\(number)", number: number)
    }

    func abort(
        multipartId: String,
        key: String
    ) async throws(StorageClientError) {
        await state.removeMultipart(multipartId)
    }

    func finish(
        multipartId: String,
        key: String,
        chunks: [StorageMultipartChunk]
    ) async throws(StorageClientError) {
        guard let parts = await state.multipartParts(id: multipartId) else {
            throw .invalidMultipartId
        }
        var output: [Int] = []
        for chunk in chunks.sorted(by: { $0.number < $1.number }) {
            guard let values = parts[chunk.number] else {
                throw .invalidMultipartChunk
            }
            output.append(contentsOf: values)
        }
        await state.setObject(key, values: output)
        await state.removeMultipart(multipartId)
    }

    private func decodeValues(
        from sequence: StorageSequence
    ) async throws -> [Int] {
        var iterator = sequence.makeAsyncIterator()
        var values: [Int] = []
        while let buffer = try await iterator.next() {
            var remaining = buffer
            while let value = remaining.readInteger(as: UInt8.self) {
                values.append(Int(value))
            }
        }
        return values
    }
}

