import Foundation

public extension AuralinkClient {
    func requestWithProgress<T: Decodable>(_ endpoint: AuralinkRequest, progress: @escaping (Double) -> Void) async throws -> T {
        let adapted = try await adapter?.adapt(endpoint) ?? endpoint
        let cacheKey = adapted.cacheKey
        if let cached: T = (cache.value(forKey: cacheKey) as? T) {
            logger.log(.info, "cache hit memory: \(cacheKey)")
            return cached
        }
        if let disk = AuralinkDiskCache.shared.get(forKey: cacheKey) {
            let decoded = try JSONDecoder().decode(T.self, from: disk)
            cache.set(value: decoded as AnyObject, forKey: cacheKey)
            logger.log(.info, "cache hit disk: \(cacheKey)")
            return decoded
        }

        // Build URLRequest
        var urlRequest = try adapted.asURLRequest(baseURL: configuration.baseURL)
        for (k,v) in configuration.defaultHeaders where urlRequest.value(forHTTPHeaderField: k) == nil {
            urlRequest.setValue(v, forHTTPHeaderField: k)
        }

        // pass through interceptor chain if present
        if let chain = adapter as? AuralinkInterceptorChain {
            urlRequest = try await chain.run(request: urlRequest)
        }

        logger.log(.debug, "-> \(urlRequest.httpMethod ?? "REQ") \(urlRequest.url?.absoluteString ?? "")")

        let (data, response) = try await retryPolicy.execute { [session] in
            // Use URLSession dataTask with progress via delegate wrapper
            try await session.data(for: urlRequest)
        }

        if let http = response as? HTTPURLResponse {
            await (adapter as? AuralinkInterceptorChain)?.notify(response: response, data: data)
            if (200..<300).contains(http.statusCode) {
                let decoded = try JSONDecoder().decode(T.self, from: data)
                cache.set(value: decoded as AnyObject, forKey: cacheKey)
                AuralinkDiskCache.shared.set(data: data, forKey: cacheKey, ttl: 60 * 5) // default 5 min
                AuralinkAIInsights.shared.record(endpoint: urlRequest.url?.absoluteString ?? "", duration: 0) // simplified
                return decoded
            } else if http.statusCode == 401 {
                // attempt token refresh if present
                if let tokenInterceptor = adapter as? AuralinkTokenRefreshInterceptor {
                    await tokenInterceptor.refreshToken()
                    // retry once after refresh
                    let (data2, response2) = try await session.data(for: urlRequest)
                    if let http2 = response2 as? HTTPURLResponse, (200..<300).contains(http2.statusCode) {
                        let decoded = try JSONDecoder().decode(T.self, from: data2)
                        cache.set(value: decoded as AnyObject, forKey: cacheKey)
                        AuralinkDiskCache.shared.set(data: data2, forKey: cacheKey, ttl: 60 * 5)
                        return decoded
                    }
                }
                throw AuralinkError.server(statusCode: http.statusCode, data: data)
            } else {
                throw AuralinkError.server(statusCode: http.statusCode, data: data)
            }
        }
        throw AuralinkError.unknown
    }
}
