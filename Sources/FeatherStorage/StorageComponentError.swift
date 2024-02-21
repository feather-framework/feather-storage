//
//  StorageComponentError.swift
//  FeatherStorage
//
//  Created by Tibor Bodecs on 2023. 01. 16..
//

/// storage component error
public enum StorageComponentError: Error {

    case invalidKey

    case invalidBuffer

    case invalidMultipartId

    case invalidMultipartChunk

    case unknown(Error)
}
