import Foundation

final class KLPaletteCache {
    private var values: [String: KLAdaptivePalette] = [:]
    private var recency: [String] = []
    private let capacity: Int
    private let lock = NSLock()

    init(capacity: Int = 64) {
        self.capacity = max(capacity, 1)
    }

    var count: Int {
        lock.lock(); defer { lock.unlock() }
        return values.count
    }

    func value(for key: String) -> KLAdaptivePalette? {
        lock.lock(); defer { lock.unlock() }
        guard let value = values[key] else { return nil }
        markRecentlyUsed(key)
        return value
    }

    func insert(_ value: KLAdaptivePalette, for key: String) {
        lock.lock(); defer { lock.unlock() }
        values[key] = value
        markRecentlyUsed(key)
        while values.count > capacity, let leastRecentKey = recency.first {
            recency.removeFirst()
            values.removeValue(forKey: leastRecentKey)
        }
    }

    private func markRecentlyUsed(_ key: String) {
        recency.removeAll { $0 == key }
        recency.append(key)
    }
}
