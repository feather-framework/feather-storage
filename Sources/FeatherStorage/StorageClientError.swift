//
//  StorageClientError.swift
//  feather-storage
//
//  Created by Tibor Bodecs on 2023. 01. 16.
//

/// Storage-level errors surfaced by `StorageClient` implementations.
public enum StorageClientError: Error {
    /// The provided key does not exist or is malformed for the operation.
    case invalidKey
    /// Invalid byte range or buffer layout was requested.
    case invalidBuffer
    /// The multipart upload session identifier is invalid.
    case invalidMultipartId
    /// A multipart chunk descriptor is invalid.
    case invalidMultipartChunk
    /// Driver-specific underlying failure.
    case unknown(Error)
}
