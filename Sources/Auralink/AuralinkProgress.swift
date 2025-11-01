import Foundation

public struct AuralinkProgress {
    public let bytesSent: Int64
    public let totalBytesSent: Int64
    public let totalBytesExpectedToSend: Int64

    public var fractionCompleted: Double {
        guard totalBytesExpectedToSend > 0 else { return 0 }
        return Double(totalBytesSent) / Double(totalBytesExpectedToSend)
    }
}

public typealias AuralinkProgressHandler = (AuralinkProgress) -> Void
