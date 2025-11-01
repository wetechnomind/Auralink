import Foundation

public final class AuralinkAIInsights {
    public static let shared = AuralinkAIInsights()

    private var records: [String: [TimeInterval]] = [:]
    private let lock = NSLock()

    // thresholds (seconds)
    public var slowThreshold: TimeInterval = 1.5
    public var recordWindow: Int = 50

    private init() {}

    public func record(endpoint: String, duration: TimeInterval) {
        lock.lock()
        defer { lock.unlock() }
        var arr = records[endpoint] ?? []
        arr.append(duration)
        if arr.count > recordWindow { arr.removeFirst(arr.count - recordWindow) }
        records[endpoint] = arr
    }

    public func suggestion(for endpoint: String) -> String? {
        lock.lock(); defer { lock.unlock() }
        guard let arr = records[endpoint], !arr.isEmpty else { return nil }
        let avg = arr.reduce(0, +) / Double(arr.count)
        if avg > slowThreshold {
            return "Average response time for \(endpoint) is \(String(format: "%.2fs", avg)). Consider backend optimization, caching, or pagination."
        }
        return nil
    }
}
