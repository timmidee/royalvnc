#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

/// Thread-safe ring buffer queue implementation using NSLock for synchronization.
/// Uses a circular buffer to avoid expensive array shifts on dequeue operations.
/// This prevents address overlap issues and provides O(1) enqueue/dequeue performance.
struct Queue<T> {
	private var buffer: [T?]
	private var head: Int = 0
	private var tail: Int = 0
	private var count: Int = 0
	private let lock = NSLock()

	private static var defaultCapacity: Int { 16 }

	init(capacity: Int = defaultCapacity) {
		buffer = Array(repeating: nil, count: capacity)
	}

	mutating func enqueue(_ element: T) {
		lock.lock()
		defer { lock.unlock() }

		// Grow buffer if needed
		if count == buffer.count {
			resize(to: buffer.count * 2)
		}

		buffer[tail] = element
		tail = (tail + 1) % buffer.count
		count += 1
	}

	mutating func dequeue() -> T? {
		lock.lock()
		defer { lock.unlock() }

		guard count > 0 else { return nil }

		let element = buffer[head]
		buffer[head] = nil // Release reference
		head = (head + 1) % buffer.count
		count -= 1

		// Shrink buffer if needed (don't go below default capacity)
		if count > 0 && count < buffer.count / 4 && buffer.count > Queue.defaultCapacity {
			resize(to: max(buffer.count / 2, Queue.defaultCapacity))
		}

		return element
	}

	mutating func clear() {
		lock.lock()
		defer { lock.unlock() }

		// Release all references
		for i in 0..<buffer.count {
			buffer[i] = nil
		}
		head = 0
		tail = 0
		count = 0
	}

	func peek() -> T? {
		lock.lock()
		defer { lock.unlock() }

		guard count > 0 else { return nil }
		return buffer[head]
	}

	var isEmpty: Bool {
		lock.lock()
		defer { lock.unlock() }
		return count == 0
	}

	// MARK: - Private Helper

	private mutating func resize(to newCapacity: Int) {
		var newBuffer = Array<T?>(repeating: nil, count: newCapacity)

		// Copy elements in order from head to tail
		for i in 0..<count {
			let index = (head + i) % buffer.count
			newBuffer[i] = buffer[index]
		}

		buffer = newBuffer
		head = 0
		tail = count
	}
}
