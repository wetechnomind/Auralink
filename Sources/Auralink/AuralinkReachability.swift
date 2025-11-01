import Foundation
import Network

public final class AuralinkReachability {
    public static let shared = AuralinkReachability()
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "auralink.reachability")
    public private(set) var isOnline: Bool = true
    public func start() {
        monitor.pathUpdateHandler = { path in
            self.isOnline = path.status == .satisfied
            if self.isOnline {
                AuralinkOfflineQueue.shared.flush()
            }
        }
        monitor.start(queue: queue)
    }
}
