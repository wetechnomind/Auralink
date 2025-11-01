import Foundation

public final class AuralinkDiskCache {
    public static let shared = AuralinkDiskCache()
    private let directory: URL
    private let fileManager = FileManager.default
    private let queue = DispatchQueue(label: "auralink.diskcache")

    private init() {
        let caches = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first ?? URL(fileURLWithPath: NSTemporaryDirectory())
        directory = caches.appendingPathComponent("AuralinkDiskCache")
        try? fileManager.createDirectory(at: directory, withIntermediateDirectories: true, attributes: nil)
    }

    private func fileURL(for key: String) -> URL {
        let safe = Data(key.utf8).base64EncodedString()
        return directory.appendingPathComponent(safe)
    }

    public func set(data: Data, forKey key: String, ttl: TimeInterval? = nil) {
        queue.async {
            var payload: [String: Any] = ["data": data.base64EncodedString()]
            if let ttl = ttl {
                payload["expiry"] = Date().addingTimeInterval(ttl).timeIntervalSince1970
            }
            if let json = try? JSONSerialization.data(withJSONObject: payload, options: []) {
                try? json.write(to: self.fileURL(for: key), options: .atomic)
            }
        }
    }

    public func get(forKey key: String) -> Data? {
        let url = fileURL(for: key)
        guard let json = try? Data(contentsOf: url) else { return nil }
        guard let obj = try? JSONSerialization.jsonObject(with: json, options: []) as? [String: Any] else { return nil }
        if let exp = obj["expiry"] as? TimeInterval {
            if Date().timeIntervalSince1970 > exp {
                try? fileManager.removeItem(at: url)
                return nil
            }
        }
        if let b64 = obj["data"] as? String, let data = Data(base64Encoded: b64) {
            return data
        }
        return nil
    }

    public func remove(forKey key: String) {
        try? fileManager.removeItem(at: fileURL(for: key))
    }

    public func clear() {
        try? fileManager.removeItem(at: directory)
        try? fileManager.createDirectory(at: directory, withIntermediateDirectories: true, attributes: nil)
    }
}
