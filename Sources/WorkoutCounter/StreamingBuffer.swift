import Foundation

/// Generic fixed-size circular buffer.
struct CircularBuffer<Element> {
    private let capacity: Int
    private var storage: [Element]
    private var index: Int = 0
    private(set) var count: Int = 0

    init(capacity: Int) {
        precondition(capacity > 0)
        self.capacity = capacity
        self.storage = []
        self.storage.reserveCapacity(capacity)
    }

    mutating func append(_ element: Element) {
        if storage.count < capacity {
            storage.append(element)
        } else {
            storage[index] = element
        }
        index = (index + 1) % capacity
        count = min(count + 1, capacity)
    }

    func toArray() -> [Element] {
        guard count == capacity else { return storage }
        var result: [Element] = []
        result.reserveCapacity(count)
        for i in 0..<count {
            let idx = (index + i) % capacity
            result.append(storage[idx])
        }
        return result
    }
}

/// Fixed-size buffer for pose samples supporting time based queries.
final class CircularPoseBuffer {
    private let capacity: Int
    private var buffer: [PoseFrame]
    private var writeIndex: Int = 0
    private(set) var count: Int = 0

    init(capacity: Int = 180) {
        self.capacity = capacity
        let empty = PoseFrame(time: 0, joints: [:])
        self.buffer = Array(repeating: empty, count: capacity)
    }

    func append(_ sample: PoseFrame) {
        buffer[writeIndex] = sample
        writeIndex = (writeIndex + 1) % capacity
        count = min(count + 1, capacity)
    }

    /// Returns the last `frameCount` samples in chronological order.
    func getRecentFrames(_ frameCount: Int) -> [PoseFrame] {
        let actual = min(frameCount, count)
        var result: [PoseFrame] = []
        result.reserveCapacity(actual)
        for i in 0..<actual {
            let idx = (writeIndex - actual + i + capacity) % capacity
            result.append(buffer[idx])
        }
        return result
    }

    /// Returns all frames within the last `duration` seconds.
    func getTimeWindow(_ duration: TimeInterval) -> [PoseFrame] {
        guard count > 0 else { return [] }
        let latestTime = buffer[(writeIndex - 1 + capacity) % capacity].time
        var frames: [PoseFrame] = []
        for i in 0..<count {
            let idx = (writeIndex - 1 - i + capacity) % capacity
            let sample = buffer[idx]
            if latestTime - sample.time <= duration {
                frames.insert(sample, at: 0)
            } else {
                break
            }
        }
        return frames
    }
}
