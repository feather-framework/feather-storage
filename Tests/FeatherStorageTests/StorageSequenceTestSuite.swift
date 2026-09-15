//
//  StorageSequenceTestSuite.swift
//  feather-storage
//
//  Created by Tibor Bodecs on 2023. 01. 16.

import NIOCore
import Testing

@testable import FeatherStorage

@Suite
struct StorageSequenceTestSuite {

    enum TestError: Error {
        case failed
    }

    private actor DemandProbe {
        private(set) var requestCount = 0

        func recordRequest() {
            requestCount += 1
        }
    }

    private struct DemandTrackingSequence: AsyncSequence, Sendable {
        typealias Element = ByteBuffer

        struct AsyncIterator: AsyncIteratorProtocol {
            let probe: DemandProbe
            var remainingCount: Int

            mutating func next(
                isolation actor: isolated (any Actor)?
            ) async -> ByteBuffer? {
                guard remainingCount > 0 else {
                    return nil
                }
                remainingCount -= 1
                await probe.recordRequest()
                return ByteBuffer(bytes: [UInt8(remainingCount)])
            }
        }

        let probe: DemandProbe
        let count: Int

        func makeAsyncIterator() -> AsyncIterator {
            .init(probe: probe, remainingCount: count)
        }
    }

    @Test
    func initFromAsyncSequencePreservesElementsAndLength() async throws {
        let allocator = ByteBufferAllocator()
        let sequence = StorageSequence(
            asyncSequence: AsyncStream { continuation in
                continuation.yield(
                    Self.makeBuffer([1, 2], allocator: allocator)
                )
                continuation.yield(Self.makeBuffer([3], allocator: allocator))
                continuation.finish()
            },
            length: 3
        )

        var iterator = sequence.makeAsyncIterator()
        let first = try await iterator.next()
        let second = try await iterator.next()
        let end = try await iterator.next()

        #expect(sequence.length == 3)
        #expect(Self.readBytes(first) == [1, 2])
        #expect(Self.readBytes(second) == [3])
        #expect(end == nil)
    }

    @Test
    func initFromAsyncSequenceUsesNilLengthByDefault() {
        let sequence = StorageSequence(
            asyncSequence: AsyncStream<ByteBuffer> { continuation in
                continuation.finish()
            }
        )

        #expect(sequence.length == nil)
    }

    @Test
    func initFromBufferSetsLengthAndStreamsAllBytes() async throws {
        let allocator = ByteBufferAllocator()
        let sequence = StorageSequence(
            buffer: Self.makeBuffer([9, 8, 7, 6], allocator: allocator)
        )

        var iterator = sequence.makeAsyncIterator()
        let first = try await iterator.next()
        let end = try await iterator.next()

        #expect(sequence.length == 4)
        #expect(Self.readBytes(first) == [9, 8, 7, 6])
        #expect(end == nil)
    }

    @Test
    func initFromThrowingSequencePropagatesErrors() async {
        let allocator = ByteBufferAllocator()
        let sequence = StorageSequence(
            asyncSequence: AsyncThrowingStream<ByteBuffer, Error> {
                continuation in
                continuation.yield(Self.makeBuffer([1], allocator: allocator))
                continuation.finish(throwing: TestError.failed)
            }
        )

        var iterator = sequence.makeAsyncIterator()
        do {
            _ = try await iterator.next()
            _ = try await iterator.next()
            Issue.record("Expected TestError.failed")
        }
        catch TestError.failed {
            // expected
        }
        catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    @Test
    func requestsUpstreamElementsOnlyWhenConsumerAdvances() async throws {
        let probe = DemandProbe()
        let sequence = StorageSequence(
            asyncSequence: DemandTrackingSequence(probe: probe, count: 3)
        )
        var iterator = sequence.makeAsyncIterator()

        #expect(await probe.requestCount == 0)

        _ = try await iterator.next()
        for _ in 0..<10 {
            await Task.yield()
        }
        #expect(await probe.requestCount == 1)

        _ = try await iterator.next()
        for _ in 0..<10 {
            await Task.yield()
        }
        #expect(await probe.requestCount == 2)
    }

    private static func makeBuffer(
        _ bytes: [UInt8],
        allocator: ByteBufferAllocator
    ) -> ByteBuffer {
        var buffer = allocator.buffer(capacity: bytes.count)
        buffer.writeBytes(bytes)
        return buffer
    }

    private static func readBytes(_ buffer: ByteBuffer?) -> [UInt8] {
        guard var value = buffer else {
            return []
        }
        return value.readBytes(length: value.readableBytes) ?? []
    }
}
