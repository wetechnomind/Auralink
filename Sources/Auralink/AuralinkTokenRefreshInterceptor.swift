import Foundation

public final class AuralinkTokenRefreshInterceptor: AuralinkInterceptor {
    private let lock = NSLock()
    private var isRefreshing = false
    private var token: String?
    private var refreshURL: URL?

    public init(initialToken: String? = nil, refreshURL: URL? = nil) {
        self.token = initialToken
        self.refreshURL = refreshURL
    }

    public func setToken(_ newToken: String?) {
        lock.lock(); defer { lock.unlock() }
        token = newToken
    }

    public func intercept(_ request: URLRequest) async throws -> URLRequest {
        var req = request
        if let t = token {
            req.setValue("Bearer \(t)", forHTTPHeaderField: "Authorization")
        }
        return req
    }

    public func didReceive(_ response: URLResponse?, data: Data?) async {
        guard let http = response as? HTTPURLResponse else { return }
        if http.statusCode == 401 {
            await refreshTokenIfNeeded()
        }
    }

    // Public refresh method that other code can call to force refresh synchronously from async context
    public func refreshTokenIfNeeded() async {
        lock.lock()
        if isRefreshing { lock.unlock(); return }
        isRefreshing = true
        lock.unlock()

        defer {
            lock.lock(); isRefreshing = false; lock.unlock()
        }

        // Simulated refresh: Replace this block with a real network call to your auth server.
        if let url = refreshURL {
            var req = URLRequest(url: url)
            req.httpMethod = "POST"
            // Optionally add existing refresh token/body here
            do {
                let (data, response) = try await URLSession.shared.data(for: req)
                if let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) {
                    // parse token from response - this assumes JSON { token: "..." }
                    if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any], let newToken = json["token"] as? String {
                        setToken(newToken)
                    } else {
                        // fallback: use raw string
                        setToken(String(data: data, encoding: .utf8))
                    }
                }
            } catch {
                // ignore - keep old token if refresh fails
            }
        } else {
            // fallback simulated delay
            try? await Task.sleep(nanoseconds: 800_000_000)
            setToken("simulated-token-\(UUID().uuidString)")
        }
    }
}
