import Foundation

public enum AuralinkError: Error {
    case invalidURL
    case network(Error)
    case decoding(Error)
    case server(statusCode: Int, data: Data?)
    case cancelled
    case unknown
}

public final class AuralinkClient {
    public struct Configuration {
        public var baseURL: URL?
        public var defaultHeaders: [String: String]
        public var timeout: TimeInterval
        public init(baseURL: URL? = nil, defaultHeaders: [String: String] = [:], timeout: TimeInterval = 60) {
            self.baseURL = baseURL
            self.defaultHeaders = defaultHeaders
            self.timeout = timeout
        }
    }

    private let session: URLSession
    public var configuration: Configuration
    public let logger = AuralinkLogger.shared
    public let retryPolicy = AuralinkRetryPolicy()
    public let cache = AuralinkCache.shared
    public let adapter: AuralinkRequestAdapter?

    public init(configuration: Configuration = .init(), adapter: AuralinkRequestAdapter? = nil, urlSession: URLSession? = nil) {
        self.configuration = configuration
        self.adapter = adapter
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = configuration.timeout
        self.session = urlSession ?? URLSession(configuration: config)
        AuralinkReachability.shared.start()
        AuralinkOfflineQueue.shared.client = self
    }

    // Generic request
    public func request<T: Decodable>(_ endpoint: AuralinkRequest) async throws -> T {
        let adapted = try await adapter?.adapt(endpoint) ?? endpoint
        let cacheKey = adapted.cacheKey
        if let cached = cache.value(forKey: cacheKey) as? T {
            logger.log(.info, "cache hit: \(cacheKey)")
            return cached
        }

        return try await withCheckedThrowingContinuation { continuation in
            Task {
                do {
                    let (data, response) = try await perform(adapted)
                    if let http = response as? HTTPURLResponse {
                        if (200..<300).contains(http.statusCode) {
                            do {
                                let decoded = try JSONDecoder().decode(T.self, from: data)
                                cache.set(value: decoded as AnyObject, forKey: cacheKey)
                                continuation.resume(returning: decoded)
                            } catch {
                                continuation.resume(throwing: AuralinkError.decoding(error))
                            }
                        } else {
                            continuation.resume(throwing: AuralinkError.server(statusCode: http.statusCode, data: data))
                        }
                    } else {
                        continuation.resume(throwing: AuralinkError.unknown)
                    }
                } catch {
                    continuation.resume(throwing: AuralinkError.network(error))
                }
            }
        }
    }

    private func perform(_ endpoint: AuralinkRequest) async throws -> (Data, URLResponse) {
        var urlRequest = try endpoint.asURLRequest(baseURL: configuration.baseURL)
        // merge default headers
        for (k,v) in configuration.defaultHeaders where urlRequest.value(forHTTPHeaderField: k) == nil {
            urlRequest.setValue(v, forHTTPHeaderField: k)
        }
        logger.log(.debug, "-> \(urlRequest.httpMethod ?? "REQ") \(urlRequest.url?.absoluteString ?? "")")
        return try await retryPolicy.execute { [session] in
            try await session.data(for: urlRequest)
        }
    }

    // Multipart upload simplified
    public func uploadMultipart<T: Decodable>(_ endpoint: AuralinkMultipartRequest, progress: @escaping (Double) -> Void) async throws -> T {
        let urlRequest = try endpoint.asURLRequest(baseURL: configuration.baseURL)
        return try await withCheckedThrowingContinuation { cont in
            let task = session.uploadTask(with: urlRequest, from: endpoint.bodyData) { data, response, error in
                if let err = error { cont.resume(throwing: AuralinkError.network(err)); return }
                guard let data = data, let response = response as? HTTPURLResponse else { cont.resume(throwing: AuralinkError.unknown); return }
                if (200..<300).contains(response.statusCode) {
                    do {
                        let decoded = try JSONDecoder().decode(T.self, from: data)
                        cont.resume(returning: decoded)
                    } catch { cont.resume(throwing: AuralinkError.decoding(error)) }
                } else {
                    cont.resume(throwing: AuralinkError.server(statusCode: response.statusCode, data: data))
                }
            }
            let observation = session.progress.observe(\.fractionCompleted) { prog, _ in
                progress(prog.fractionCompleted)
            }
            task.resume()
        }
    }
}
