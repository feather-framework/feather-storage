//
//  MockStorageState.swift
//  feather-storage
//
//  Created by Tibor Bödecs on 2026. 02. 23..
//

actor MockStorageState {
    var objects: [String: [Int]] = [:]
    var objectContentTypes: [String: String] = [:]
    var multiparts: [String: [Int: [Int]]] = [:]
    var multipartContentTypes: [String: String] = [:]

    func setObject(
        _ key: String,
        values: [Int],
        contentType: String? = nil
    ) {
        objects[key] = values
        if let contentType {
            objectContentTypes[key] = contentType
        }
        else {
            objectContentTypes.removeValue(forKey: key)
        }
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

    func objectContentType(for key: String) -> String? {
        objectContentTypes[key]
    }

    func deleteObject(_ key: String) {
        objects.removeValue(forKey: key)
        objectContentTypes.removeValue(forKey: key)
    }

    func listKeys(prefix: String) -> [String] {
        objects.keys.filter { $0.hasPrefix(prefix) }.sorted()
    }

    func createMultipart(id: String, contentType: String?) {
        multiparts[id] = [:]
        if let contentType {
            multipartContentTypes[id] = contentType
        }
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

    func multipartContentType(_ id: String) -> String? {
        multipartContentTypes[id]
    }

    func removeMultipart(_ id: String) {
        multiparts.removeValue(forKey: id)
        multipartContentTypes.removeValue(forKey: id)
    }
}
