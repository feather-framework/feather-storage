//
//  StorageMultipartChunk.swift
//  feather-storage
//
//  Created by Tibor Bodecs on 2023. 01. 16.

/// Represents a multipart chunk object.
public struct StorageMultipartChunk: Hashable, Codable, Equatable, Sendable {
    /// The identifier of the multipart chunk.
    public var id: String
    /// The name of the multipart chunk.
    public var number: Int

    /// Creates a multipart chunk descriptor.
    ///
    /// - Parameters:
    ///   - id: Driver-specific chunk identifier.
    ///   - number: 1-based multipart chunk number.
    public init(id: String, number: Int) {
        self.id = id
        self.number = number
    }
}
