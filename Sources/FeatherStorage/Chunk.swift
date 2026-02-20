//
//  File.swift
//  feather-storage
//
//  Created by Tibor Bödecs on 2026. 01. 27..
//

/// storage chunks returned used by the multipart request apis
public struct Chunk: Hashable, Codable, Sendable, Equatable {
    public var id: String
    public var number: Int

    public init(
        chunkId: String,
        number: Int
    ) {
        self.id = chunkId
        self.number = number
    }
}
