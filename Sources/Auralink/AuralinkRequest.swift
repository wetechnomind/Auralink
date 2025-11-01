import Foundation

public enum AuralinkHTTPMethod: String {
    case GET, POST, PUT, PATCH, DELETE, HEAD, OPTIONS
}

public protocol AuralinkRequestAdapter {
    func adapt(_ request: AuralinkRequest) async throws -> AuralinkRequest
}

public struct AuralinkRequest {
    public let path: String
    public let method: AuralinkHTTPMethod
    public var queryItems: [URLQueryItem] = []
    public var headers: [String: String] = [:]
    public var body: Data? = nil
    public var cacheKey: String {
        return "\(method.rawValue):\(path)?\(queryItems.map{"\($0.name)=\($0.value ?? "")"}.joined(separator: "&"))"
    }

    public init(path: String, method: AuralinkHTTPMethod = .GET) {
        self.path = path
        self.method = method
    }

    public func asURLRequest(baseURL: URL?) throws -> URLRequest {
        guard let url: URL = {
            if let base = baseURL { return URL(string: path, relativeTo: base)?.absoluteURL }
            return URL(string: path)
        }() else { throw AuralinkError.invalidURL }
        var components = URLComponents(url: url, resolvingAgainstBaseURL: true)
        components?.queryItems = queryItems.isEmpty ? nil : queryItems
        guard let finalURL = components?.url else { throw AuralinkError.invalidURL }
        var req = URLRequest(url: finalURL)
        req.httpMethod = method.rawValue
        req.httpBody = body
        headers.forEach { req.setValue($0.value, forHTTPHeaderField: $0.key) }
        return req
    }
}

public struct AuralinkMultipartRequest {
    public let path: String
    public var headers: [String: String] = [:]
    public var boundary: String = UUID().uuidString
    public var bodyData: Data = Data()

    public init(path: String) {
        self.path = path
    }

    public mutating func addFormField(name: String, value: String) {
        var part = "--\(boundary)\r\n"
        part += "Content-Disposition: form-data; name=\"\(name)\"\r\n\r\n"
        part += "\(value)\r\n"
        bodyData.append(part.data(using: .utf8)!)
    }

    public mutating func addFile(fieldName: String, filename: String, mimeType: String, data: Data) {
        var part = "--\(boundary)\r\n"
        part += "Content-Disposition: form-data; name=\"\(fieldName)\"; filename=\"\(filename)\"\r\n"
        part += "Content-Type: \(mimeType)\r\n\r\n"
        bodyData.append(part.data(using: .utf8)!)
        bodyData.append(data)
        bodyData.append("\r\n".data(using: .utf8)!)
    }

    public func asURLRequest(baseURL: URL?) throws -> URLRequest {
        guard let url = (baseURL != nil) ? URL(string: path, relativeTo: baseURL)?.absoluteURL : URL(string: path) else { throw AuralinkError.invalidURL }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        headers.forEach { req.setValue($0.value, forHTTPHeaderField: $0.key) }
        // finalize
        var final = bodyData
        final.append("--\(boundary)--\r\n".data(using: .utf8)!)
        // attach as HTTPBody for uploadTask usage
        return req
    }
}
