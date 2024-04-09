//
//  Component+Storage.swift
//  FeatherStorage
//
//  Created by Tibor Bodecs on 20/11/2023.
//

import FeatherComponent
import Logging

public enum StorageComponentID: ComponentID {

    /// default storage component identifier
    case `default`

    /// custom storage component identifier
    case custom(String)

    public var rawId: String {
        switch self {
        case .default:
            return "storage-component-id"
        case .custom(let value):
            return "\(value)-storage-component-id"
        }
    }
}

extension ComponentRegistry {

    /// add a new storage component using a context
    public func addStorage(
        _ context: ComponentContext,
        id: StorageComponentID = .default
    ) async throws {
        try await add(context, id: id)
    }

    /// returns a storage component by a given id
    public func storage(
        _ id: StorageComponentID = .default,
        logger: Logger? = nil
    ) throws -> StorageComponent {
        guard
            let storage = try get(id, logger: logger) as? StorageComponent
        else {
            fatalError(
                "Storage component not found, call `addStorage()` to register."
            )
        }
        return storage
    }
}
