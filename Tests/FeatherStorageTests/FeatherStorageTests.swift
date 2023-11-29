//
//  FeatherStorageTests.swift
//  FeatherStorageTests
//
//  Created by Tibor Bodecs on 2023. 01. 16..
//

import XCTest
import FeatherService
import FeatherStorage

final class FeatherStorageTests: XCTestCase {

    func testExample() async throws {

        let registry = ServiceRegistry()

        try await registry.addStorage(MyStorageServiceContext())
        try await registry.run()

        let storage = try await registry.storage()
        XCTAssertNotNil(storage)

        try await registry.shutdown()
    }
}
