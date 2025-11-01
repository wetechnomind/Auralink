import Foundation

public extension AuralinkOfflineQueue {
    private static var storageURL: URL {
        let fm = FileManager.default
        let dir = fm.urls(for: .cachesDirectory, in: .userDomainMask).first!
        return dir.appendingPathComponent("auralink_offline_queue.json")
    }

    func persist() {
        let fm = FileManager.default
        let arr: [String] = queue.map { _ in UUID().uuidString } // placeholder: cannot serialize closures
        try? JSONSerialization.data(withJSONObject: arr).map { try? $0.write(to: Self.storageURL) }
    }

    func restore() {
        // can't restore closures; in real life you'd persist request metadata and rebuild jobs
    }
}
