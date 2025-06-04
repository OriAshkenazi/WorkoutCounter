import Foundation
#if os(Linux)
@_silgen_name("malloc_trim")
private func malloc_trim(_ pad: UInt) -> Int32
#endif

/// Simple memory watcher that triggers cleanup when usage grows.
final class MemoryManager {
    private let maxBytes: Int = 50_000_000

    func optimizeMemoryUsage() {
#if os(Linux)
        malloc_trim(0)
#endif
    }

    func estimateCurrentUsage() -> Int {
        // In a real app calculate buffer sizes. Here return a small value.
        return 0
    }

    func shouldReduceQuality() -> Bool {
        estimateCurrentUsage() > maxBytes * 80 / 100
    }
}
