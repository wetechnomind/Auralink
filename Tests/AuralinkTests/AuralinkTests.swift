import XCTest
@testable import Auralink

final class MockURLProtocol: URLProtocol {
    static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func startLoading() {
        guard let handler = MockURLProtocol.requestHandler else {
            fatalError("No handler set")
        }
        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }
    override func stopLoading() {}
}

final class AuralinkTests: XCTestCase {
    func testSuccessfulDecoding() async throws {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        let session = URLSession(configuration: config)
        let client = AuralinkClient(configuration: .init(baseURL: URL(string: "https://example.com")), adapter: nil, urlSession: session)

        struct Resp: Decodable, Equatable { let message: String }

        MockURLProtocol.requestHandler = { request in
            let data = try JSONEncoder().encode(Resp(message: "hello"))
            let resp = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (resp, data)
        }

        let req = AuralinkRequest(path: "/test", method: .GET)
        let decoded: Resp = try await client.request(req)
        XCTAssertEqual(decoded.message, "hello")
    }

    func testRetryPolicyRetriesOnFailure() async throws {
        let policy = AuralinkRetryPolicy()
        policy.maxRetries = 2
        var attempts = 0
        MockURLProtocol.requestHandler = { request in
            attempts += 1
            if attempts < 3 {
                throw URLError(.timedOut)
            }
            let data = Data("{}".utf8)
            let resp = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (resp, data)
        }
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        let session = URLSession(configuration: config)
        let client = AuralinkClient(configuration: .init(baseURL: URL(string: "https://example.com")), adapter: nil, urlSession: session)
        let req = AuralinkRequest(path: "/retry", method: .GET)
        // Should succeed after retries
        let _: EmptyResponse = try await client.request(req)
        XCTAssertGreaterThanOrEqual(attempts, 2)
    }
}

private struct EmptyResponse: Decodable {}
