import Foundation

public final class AuralinkOfflineQueue {
    public static let shared = AuralinkOfflineQueue()
    private var queue: [() async -> Void] = []
    public weak var client: AuralinkClient?

    private init() {}

    public func enqueue(_ job: @escaping () async -> Void) {
        queue.append(job)
    }

    public func flush() {
        guard !queue.isEmpty else { return }
        let jobs = queue
        queue.removeAll()
        for job in jobs {
            Task { await job() }
        }
    }
}
