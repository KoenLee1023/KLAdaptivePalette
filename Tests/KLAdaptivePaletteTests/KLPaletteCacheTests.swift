import Testing
@testable import KLAdaptivePalette

@Suite struct KLPaletteCacheTests {
    @Test func `cache evicts the least recently used entry at capacity`() {
        let cache = KLPaletteCache(capacity: 2)
        let first = KLAdaptivePalette.fallback
        let second = KLAdaptivePalette.fallback
        let third = KLAdaptivePalette.fallback

        cache.insert(first, for: "first")
        cache.insert(second, for: "second")
        _ = cache.value(for: "first")
        cache.insert(third, for: "third")

        #expect(cache.value(for: "first") != nil)
        #expect(cache.value(for: "second") == nil)
        #expect(cache.value(for: "third") != nil)
        #expect(cache.count == 2)
    }

    @Test func `replacing a value does not consume another slot`() {
        let cache = KLPaletteCache(capacity: 1)

        cache.insert(.fallback, for: "same")
        cache.insert(.fallback, for: "same")

        #expect(cache.count == 1)
    }
}
