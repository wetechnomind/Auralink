import Foundation

public final class AuralinkRetryPolicy {
    public var maxRetries = 3
    public var baseDelay: TimeInterval = 0.5

    public init() {}

    public func execute<T>(_ operation: @escaping () async throws -> T) async throws -> T {
        var attempt = 0
        var lastError: Error?
        while attempt <= maxRetries {
            do {
                return try await operation()
            } catch {
                lastError = error
                attempt += 1
                if attempt > maxRetries { break }
                let delay = pow(2.0, Double(attempt)) * baseDelay
                try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            }
        }
        throw lastError ?? AuralinkError.unknown
    }
}
