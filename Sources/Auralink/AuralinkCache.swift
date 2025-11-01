import Foundation

public final class AuralinkCache {
    public static let shared = AuralinkCache()
    private var memory: NSCache<NSString, AnyObject> = NSCache()
    private init() {}

    public func set(value: AnyObject, forKey key: String) {
        memory.setObject(value, forKey: NSString(string: key))
    }

    public func value(forKey key: String) -> AnyObject? {
        return memory.object(forKey: NSString(string: key))
    }

    public func remove(forKey key: String) {
        memory.removeObject(forKey: NSString(string: key))
    }

    public func clear() {
        memory.removeAllObjects()
    }
}
