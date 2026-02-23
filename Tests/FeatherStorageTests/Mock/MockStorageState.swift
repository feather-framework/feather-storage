//
//  MockStorageState.swift
//  feather-storage
//
//  Created by Tibor Bödecs on 2026. 02. 23..
//


actor MockStorageState {
    var objects: [String: [Int]] = [:]
    var multiparts: [String: [Int: [Int]]] = [:]

    func setObject(_ key: String, values: [Int]) {
        objects[key] = values
    }

    func object(for key: String) -> [Int]? {
        objects[key]
    }

    func hasObject(_ key: String) -> Bool {
        objects[key] != nil
    }

    func objectSize(for key: String) -> Int {
        objects[key]?.count ?? 0
    }

    func deleteObject(_ key: String) {
        objects.removeValue(forKey: key)
    }

    func listKeys(prefix: String) -> [String] {
        objects.keys.filter { $0.hasPrefix(prefix) }.sorted()
    }

    func createMultipart(id: String) {
        multiparts[id] = [:]
    }

    func hasMultipart(_ id: String) -> Bool {
        multiparts[id] != nil
    }

    func setMultipartPart(id: String, number: Int, values: [Int]) {
        multiparts[id]?[number] = values
    }

    func multipartParts(id: String) -> [Int: [Int]]? {
        multiparts[id]
    }

    func removeMultipart(_ id: String) {
        multiparts.removeValue(forKey: id)
    }
}
