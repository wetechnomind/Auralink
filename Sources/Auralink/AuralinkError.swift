import Foundation

public enum AuralinkError: Error, LocalizedError {
    case invalidURL
    case network(Error)
    case decoding(Error)
    case server(statusCode: Int, data: Data?)
    case cancelled
    case timeout
    case authenticationFailed
    case unknown

    public var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid URL provided to Auralink."
        case .network(let e): return "Network error: \(e.localizedDescription)"
        case .decoding(let e): return "Decoding failed: \(e.localizedDescription)"
        case .server(let code, _): return "Server returned HTTP status \(code)."
        case .cancelled: return "Request was cancelled."
        case .timeout: return "Request timed out."
        case .authenticationFailed: return "Authentication failed (401)."
        case .unknown: return "Unknown error."
        }
    }
}
