#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

/// Thread-safe queue implementation using NSLock for synchronization.
/// Fixed race condition where concurrent access could cause crashes.
struct Queue<T> {
	private var list = [T]()
	private let lock = NSLock()

	mutating func enqueue(_ element: T) {
		lock.lock()
		defer { lock.unlock() }
		list.append(element)
	}

	mutating func dequeue() -> T? {
		lock.lock()
		defer { lock.unlock() }

		guard !list.isEmpty else { return nil }
		return list.removeFirst()
	}

	mutating func clear() {
		lock.lock()
		defer { lock.unlock() }
		list.removeAll()
	}

	func peek() -> T? {
		lock.lock()
		defer { lock.unlock() }

		guard !list.isEmpty else { return nil }
		return list[0]
	}

	var isEmpty: Bool {
		lock.lock()
		defer { lock.unlock() }
		return list.isEmpty
	}
}
