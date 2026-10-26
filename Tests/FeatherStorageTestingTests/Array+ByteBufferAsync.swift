import NIOCore

extension Array where Element == Int {
    var byteBufferAsync: AsyncStream<ByteBuffer> {
        let values = self
        return AsyncStream { continuation in
            let allocator = ByteBufferAllocator()
            for value in values {
                var buffer = allocator.buffer(capacity: 1)
                buffer.writeInteger(UInt8(value))
                continuation.yield(buffer)
            }
            continuation.finish()
        }
    }
}
