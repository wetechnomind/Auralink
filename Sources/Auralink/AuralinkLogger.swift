import Foundation

public enum AuralinkLogLevel: Int {
    case debug, info, warning, error
}

public final class AuralinkLogger {
    public static let shared = AuralinkLogger()
    private init() {}
    public var enabled: Bool = true
    public func log(_ level: AuralinkLogLevel, _ message: String) {
        guard enabled else { return }
        let prefix: String
        switch level {
        case .debug: prefix = "[Auralink][DEBUG]"
        case .info: prefix = "[Auralink][INFO]"
        case .warning: prefix = "[Auralink][WARN]"
        case .error: prefix = "[Auralink][ERROR]"
        }
        print("\(prefix) \(message)")
    }
}
