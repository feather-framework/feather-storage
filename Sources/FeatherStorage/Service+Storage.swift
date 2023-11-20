//
//  Service+Storage.swift
//  FeatherStorage
//
//  Created by Tibor Bodecs on 20/11/2023.
//

import FeatherService
import Logging

public enum StorageServiceID: ServiceID {

    /// default storage service identifier
    case `default`
    
    /// custom storage service identifier
    case custom(String)
    
    public var rawId: String {
        switch self {
        case .default:
            return "storage-id"
        case .custom(let value):
            return "\(value)-storage-id"
        }
    }
}

public extension ServiceRegistry {

    /// add a new storage service using a context
    func add(
        _ contextFactoryBuilder: @autoclosure @escaping () -> ServiceContext,
        id: StorageServiceID = .default
    ) async throws {
        try await add(.init { contextFactoryBuilder() }, id: id)
    }

    /// returns a storage service by a given id
    func storage(
        _ id: StorageServiceID = .default,
        logger: Logger? = nil
    ) throws -> StorageService {
        guard let storage = try get(id, logger: logger) as? StorageService else {
            fatalError("Storage service not found, use `add` to register.")
        }
        return storage
    }
}
