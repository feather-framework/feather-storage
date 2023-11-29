//
//  XCTFeatherStorageTests.swift
//  XCTFeatherStorageTests
//
//  Created by Tibor Bodecs on 2023. 01. 16..
//

import XCTest
import XCTFeatherStorage

final class XCTFeatherStorageTests: XCTestCase {

    func testClosedRange1() async throws {
        let value = "test"
        let range = 1...3
        let startIndex = value.index(
            value.startIndex,
            offsetBy: range.lowerBound
        )
        let endIndex = value.index(value.startIndex, offsetBy: range.upperBound)
        XCTAssertEqual(value[startIndex...endIndex], "est")
    }

    func testClosedRange2() async throws {
        let value = "test"
        let range = 0...2
        let startIndex = value.index(
            value.startIndex,
            offsetBy: range.lowerBound
        )
        let endIndex = value.index(value.startIndex, offsetBy: range.upperBound)
        XCTAssertEqual(value[startIndex...endIndex], "tes")
    }

    func testClosedRange3() async throws {
        let value = "test"
        let range = 2...3
        let startIndex = value.index(
            value.startIndex,
            offsetBy: range.lowerBound
        )
        let endIndex = value.index(value.startIndex, offsetBy: range.upperBound)
        XCTAssertEqual(value[startIndex...endIndex], "st")
    }
}
