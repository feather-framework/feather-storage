//
//  FeatherStorageTests.swift
//  FeatherStorageTests
//
//  Created by Tibor Bodecs on 2023. 01. 16..
//

import XCTest
import FeatherComponent
import FeatherStorage

final class FeatherStorageTests: XCTestCase {

    func testExample() async throws {

        let registry = ComponentRegistry()

        try await registry.addStorage(MyStorageComponentContext())

        let storage = try await registry.storage()
        XCTAssertNotNil(storage)
    }
}
