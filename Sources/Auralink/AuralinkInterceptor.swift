import Foundation

public protocol AuralinkInterceptor {
    func intercept(_ request: URLRequest) async throws -> URLRequest
    func didReceive(_ response: URLResponse?, data: Data?) async
}

public final class AuralinkInterceptorChain {
    private var interceptors: [AuralinkInterceptor] = []

    public init(_ interceptors: [AuralinkInterceptor] = []) {
        self.interceptors = interceptors
    }

    public func add(_ interceptor: AuralinkInterceptor) {
        interceptors.append(interceptor)
    }

    public func run(request: URLRequest) async throws -> URLRequest {
        var current = request
        for interceptor in interceptors {
            current = try await interceptor.intercept(current)
        }
        return current
    }

    public func notify(response: URLResponse?, data: Data?) async {
        for interceptor in interceptors {
            await interceptor.didReceive(response, data: data)
        }
    }
}

// Example Token Refresh Interceptor
public final class AuralinkTokenRefreshInterceptor: AuralinkInterceptor {
    private let lock = NSLock()
    private var refreshing: Bool = false
    private var token: String?

    public init(initialToken: String? = nil) {
        self.token = initialToken
    }

    public func setToken(_ t: String?) {
        lock.lock(); defer { lock.unlock() }
        token = t
    }

    public func intercept(_ request: URLRequest) async throws -> URLRequest {
        var req = request
        if let t = token {
            req.setValue("Bearer \(t)", forHTTPHeaderField: "Authorization")
        }
        return req
    }

    public func didReceive(_ response: URLResponse?, data: Data?) async {
        // If 401, attempt refresh - simplistic placeholder
        if let http = response as? HTTPURLResponse, http.statusCode == 401 {
            await refreshToken()
        }
    }

    private func refreshToken() async {
        lock.lock()
        if refreshing { lock.unlock(); return }
        refreshing = true
        lock.unlock()

        // Simulated token refresh flow - replace with real network call
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1s
        setToken("new-token-\(UUID().uuidString)")

        lock.lock(); refreshing = false; lock.unlock()
    }
}
