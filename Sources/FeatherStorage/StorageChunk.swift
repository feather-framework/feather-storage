//
//  File.swift
//  feather-storage
//
//  Created by Tibor Bödecs on 2026. 01. 27..
//

/// storage chunks returned used by the multipart request apis
public struct StorageChunk: Hashable, Codable, Sendable, Equatable {
    public let chunkId: String
    public let number: Int

    public init(
        chunkId: String,
        number: Int
    ) {
        self.chunkId = chunkId
        self.number = number
    }
}
