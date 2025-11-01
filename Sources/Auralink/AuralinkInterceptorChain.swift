import Foundation

public final class AuralinkInterceptorChain {
    private var interceptors: [AuralinkInterceptor] = []

    public init(interceptors: [AuralinkInterceptor] = []) {
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
