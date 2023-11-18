//
//  File.swift
//  XCTFeatherStorage
//
//  Created by Tibor Bodecs on 17/11/2023.
//

import NIOFoundationCompat
import Foundation
import FeatherStorage

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
            //            testDownloadRange(),
            //            testDownloadRanges(),
            testListFile(),
            testCopy(),
            testMove(),
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
        let key2 = "dir04/test-01.txt"
        let data = Data("test".utf8)
        try await storage.upload(
            key: key2,
            buffer: .init(data: data)
        )

        let res = try await storage.download(
            key: key2,
            range: 1...3
        )
        guard
            let resData = res.getData(at: 0, length: res.readableBytes),
            let res = String(data: resData, encoding: .utf8),
            res == "es"
        else {
            throw StorageTestSuiteError()
        }
    }

    func testDownloadRanges() async throws {
        let key2 = "dir04/test-01.txt"
        let data = Data("test".utf8)
        try await storage.upload(
            key: key2,
            buffer: .init(data: data)
        )

        let res1 = try await storage.download(
            key: key2,
            range: 0...2
        )
        guard
            let resData = res1.getData(at: 0, length: res1.readableBytes),
            let res1 = String(data: resData, encoding: .utf8),
            res1 == "te"
        else {
            throw StorageTestSuiteError()
        }

        let res2 = try await storage.download(
            key: key2,
            range: 2...4
        )
        guard
            let resData = res2.getData(at: 0, length: res2.readableBytes),
            let res2 = String(data: resData, encoding: .utf8),
            res2 == "st"
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

    //    func testMultipartUpload() async throws {
    //
    //        let key = "test-04.txt"
    //
    //        let id = try await storage.createMultipartUpload(key: key)
    //
    //        let data1 = Data("lorem ipsum".utf8)
    //        let chunk1 = try await storage.uploadMultipartChunk(
    //            key: key,
    //            buffer: .init(data: data1),
    //            uploadId: id,
    //            number: 1
    //        )
    //
    //        let data2 = Data(" dolor sit amet".utf8)
    //        let chunk2 = try await storage.uploadMultipartChunk(
    //            key: key,
    //            buffer: .init(data: data2),
    //            uploadId: id,
    //            number: 2
    //        )
    //
    //        try await storage.completeMultipartUpload(
    //            key: key,
    //            uploadId: id,
    //            checksum: nil,
    //            chunks: [
    //                chunk1,
    //                chunk2,
    //            ]
    //        )
    //
    //        let file = try await storage.download(
    //            key: key,
    //            range: nil,
    //            timeout: .seconds(30)
    //        )
    //
    //        guard
    //            let data = file.getData(at: 0, length: file.readableBytes),
    //            let value = String(data: data, encoding: .utf8)
    //        else {
    //            return XCTFail("Missing or invalid file data.")
    //        }
    //
    //        XCTAssertEqual(value, "lorem ipsum dolor sit amet")
    //    }

}
