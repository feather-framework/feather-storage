//
//  File.swift
//  XCTFeatherStorage
//
//  Created by Tibor Bodecs on 17/11/2023.
//

import NIOCore
import NIOFoundationCompat
import Foundation
import FeatherStorage

extension Data {

    static func random(length: Int) -> Data {
        .init(
            (0..<length)
                .map { _ in
                    UInt8.random(in: UInt8.min...UInt8.max)
                }
        )
    }
}

extension ByteBuffer {

    func getData() -> Data? {
        getData(at: 0, length: readableBytes)
    }
}

public struct StorageTestSuiteError: Error {

    public let function: String
    public let line: Int
    public let error: Error?

    init(
        function: String = #function,
        line: Int = #line,
        error: Error? = nil
    ) {
        self.function = function
        self.line = line
        self.error = error
    }
}

public struct StorageTestSuite {

    let storage: StorageService

    public init(_ storage: StorageService) {
        self.storage = storage
    }

    public func testAll() async throws {
        async let tests: [Void] = [
            testUpload(),
            testCreate(),
            testList(),
            testExists(),
            testDownload(),
            testDownloadRange(),
            testDownloadRanges(),
            testListFile(),
            testCopy(),
            testMove(),
            testMultipart(),
        ]
        do {
            _ = try await tests
        }
        catch let error as StorageTestSuiteError {
            throw error
        }
        catch {
            throw StorageTestSuiteError(error: error)
        }
    }
}

public extension StorageTestSuite {

    // MARK: - tests

    func testUpload() async throws {
        let key = "test-case-01.txt"
        let data = Data("Lorem ipsum dolor sit amet".utf8)
        try await storage.upload(key: key, buffer: .init(data: data))
    }

    func testCreate() async throws {
        let key = "dir01/dir02/dir03"
        try await storage.create(key: key)

        let keys1 = try await storage.list(key: "dir01")
        guard keys1 == ["dir02"] else {
            throw StorageTestSuiteError()
        }

        let keys2 = try await storage.list(key: "dir01/dir02")
        guard keys2 == ["dir03"] else {
            throw StorageTestSuiteError()
        }
    }

    func testList() async throws {
        let key1 = "dir02/dir03"
        try await storage.create(key: key1)

        let key2 = "dir02/test-01.txt"
        let data = Data("test".utf8)
        try await storage.upload(
            key: key2,
            buffer: .init(data: data)
        )

        let res = try await storage.list(key: "dir02")
        guard res == ["dir03", "test-01.txt"] else {
            throw StorageTestSuiteError()
        }
    }

    func testExists() async throws {
        /// file tests

        let key1 = "non-existing-thing"
        let exists1 = await storage.exists(key: key1)
        guard !exists1 else {
            throw StorageTestSuiteError()
        }

        let key2 = "existing-thing/"
        try await storage.upload(key: key2, buffer: .init(string: "foo"))

        let exists2 = await storage.exists(key: key2)
        guard exists2 else {
            throw StorageTestSuiteError()
        }

        /// directory tests

        let key3 = "my/dir/"
        try await storage.create(key: key3)

        let exists3 = await storage.exists(key: key3)
        guard exists3 else {
            throw StorageTestSuiteError()
        }

        let key4 = "my/dir"
        let exists4 = await storage.exists(key: key4)
        guard exists4 else {
            throw StorageTestSuiteError()
        }
    }

    func testDownload() async throws {
        let key2 = "dir04/test-01.txt"
        let data = Data("test".utf8)
        try await storage.upload(
            key: key2,
            buffer: .init(data: data)
        )

        let res = try await storage.download(
            key: key2,
            range: nil
        )
        guard
            let resData = res.getData(at: 0, length: res.readableBytes),
            String(data: resData, encoding: .utf8) == "test"
        else {
            throw StorageTestSuiteError()
        }
    }

    func testDownloadRange() async throws {
        let value = "test"
        let key2 = "dir04/test-01.txt"
        let data = Data(value.utf8)
        try await storage.upload(
            key: key2,
            buffer: .init(data: data)
        )

        let range = 1...3
        let startIndex = value.index(
            value.startIndex,
            offsetBy: range.lowerBound
        )
        let endIndex = value.index(value.startIndex, offsetBy: range.upperBound)
        let exp = value[startIndex...endIndex]

        let res = try await storage.download(
            key: key2,
            range: range
        )
        guard
            let resData = res.getData(at: 0, length: res.readableBytes),
            let res = String(data: resData, encoding: .utf8),
            res == exp
        else {
            throw StorageTestSuiteError()
        }
    }

    func testDownloadRanges() async throws {
        let value = "test"
        let key2 = "dir04/test-01.txt"

        let data = Data(value.utf8)
        try await storage.upload(
            key: key2,
            buffer: .init(data: data)
        )

        let range1 = 0...2
        let startIndex1 = value.index(
            value.startIndex,
            offsetBy: range1.lowerBound
        )
        let endIndex1 = value.index(
            value.startIndex,
            offsetBy: range1.upperBound
        )
        let exp1 = value[startIndex1...endIndex1]

        let res1 = try await storage.download(
            key: key2,
            range: range1
        )
        guard
            let resData = res1.getData(at: 0, length: res1.readableBytes),
            let res1 = String(data: resData, encoding: .utf8),
            res1 == exp1
        else {
            throw StorageTestSuiteError()
        }

        let range2 = 2...3
        let startIndex2 = value.index(
            value.startIndex,
            offsetBy: range2.lowerBound
        )
        let endIndex2 = value.index(
            value.startIndex,
            offsetBy: range2.upperBound
        )
        let exp2 = value[startIndex2...endIndex2]

        let res2 = try await storage.download(
            key: key2,
            range: range2
        )
        guard
            let resData = res2.getData(at: 0, length: res2.readableBytes),
            let res2 = String(data: resData, encoding: .utf8),
            res2 == exp2
        else {
            throw StorageTestSuiteError()
        }
    }

    func testListFile() async throws {
        let key2 = "dir04/test-01.txt"
        let data = Data("test".utf8)
        try await storage.upload(
            key: key2,
            buffer: .init(data: data)
        )
        let res = try await storage.list(key: key2)
        guard res.isEmpty else {
            throw StorageTestSuiteError()
        }
    }

    func testCopy() async throws {
        let key = "test-02.txt"
        let data = Data("file storage test 02".utf8)
        try await storage.upload(
            key: key,
            buffer: .init(data: data)
        )

        let dest = "test-03.txt"
        try await storage.copy(key: key, to: dest)

        let res3 = await storage.exists(key: key)
        let res4 = await storage.exists(key: dest)
        guard res3, res4 else {
            throw StorageTestSuiteError()
        }
    }

    func testMove() async throws {
        let key = "test-04.txt"
        let data = Data("file storage test 04".utf8)
        try await storage.upload(
            key: key,
            buffer: .init(data: data)
        )

        let dest = "test-05.txt"
        try await storage.move(key: key, to: dest)

        let res3 = await storage.exists(key: key)
        let res4 = await storage.exists(key: dest)
        guard !res3, res4 else {
            throw StorageTestSuiteError()
        }
    }

    func testMultipart() async throws {

        let chunkSize = 5 * 1024 * 1024  // 5MB chunks
        let data = Data.random(length: 12 * 1024 * 1024)  // 12MB data

        let dataSize = data.count
        var chunkCount = dataSize / chunkSize
        let remaining = dataSize % chunkSize
        if remaining > 0 {
            chunkCount += 1
        }

        let key = "multipart-\(UUID().uuidString).data"
        let multipartId = try await storage.createMultipartId(key: key)

        var chunks: [StorageChunk] = []
        for i in 0..<chunkCount {
            let startIndex = i * chunkSize
            var endIndex = startIndex + chunkSize
            if i + 1 == chunkCount {
                endIndex = startIndex + remaining
            }
            let chunkData = data[startIndex..<endIndex]
            let chunk = try await storage.upload(
                multipartId: multipartId,
                key: key,
                number: (i + 1),
                buffer: .init(data: chunkData)
            )
            chunks.append(chunk)
        }

        try await storage.finish(
            multipartId: multipartId,
            key: key,
            chunks: chunks
        )

        let download = try await storage.download(key: key, range: nil)
        guard let downloadData = download.getData() else {
            throw StorageTestSuiteError()
        }
        guard downloadData == data else {
            throw StorageTestSuiteError()
        }
    }

}
