//
//  StorageServiceError.swift
//  FeatherStorage
//
//  Created by Tibor Bodecs on 2023. 01. 16..
//

/// storage service error
public enum StorageServiceError: Error {

    case invalidKey

    case invalidBuffer

    case invalidMultipartId

    case invalidMultipartChunk

    case unknown(Error)
}
