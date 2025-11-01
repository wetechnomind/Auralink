import Foundation

public final class AuralinkDownloadManager: NSObject, URLSessionDownloadDelegate {
    public static let shared = AuralinkDownloadManager()

    private var backgroundSession: URLSession!
    private var session: URLSession!
    private var activeHandlers: [URL: (URL?, Error?) -> Void] = [:]
    private let queue = DispatchQueue(label: "auralink.downloads")

    private override init() {
        super.init()
        let config = URLSessionConfiguration.background(withIdentifier: "com.auralink.background")
        config.httpMaximumConnectionsPerHost = 4
        backgroundSession = URLSession(configuration: config, delegate: self, delegateQueue: nil)
        session = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
    }

    public func download(url: URL, to destination: URL, progress: ((Double) -> Void)? = nil, completion: @escaping (URL?, Error?) -> Void) -> URLSessionDownloadTask {
        var req = URLRequest(url: url)
        let task = backgroundSession.downloadTask(with: req)
        queue.sync { activeHandlers[url] = completion }
        task.resume()
        return task
    }

    // Resume with resumeData
    public func resume(with resumeData: Data) -> URLSessionDownloadTask? {
        let task = backgroundSession.downloadTask(withResumeData: resumeData)
        task.resume()
        return task
    }

    // MARK: URLSessionDownloadDelegate
    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        guard let src = downloadTask.originalRequest?.url else { return }
        let completion = queue.sync { activeHandlers.removeValue(forKey: src) }
        // Move file from temp to Documents/AuralinkDownloads
        let fm = FileManager.default
        let docs = fm.urls(for: .documentDirectory, in: .userDomainMask).first!
        let destDir = docs.appendingPathComponent("AuralinkDownloads")
        try? fm.createDirectory(at: destDir, withIntermediateDirectories: true, attributes: nil)
        let dest = destDir.appendingPathComponent(src.lastPathComponent)
        try? fm.removeItem(at: dest)
        do {
            try fm.moveItem(at: location, to: dest)
            completion?(dest, nil)
        } catch {
            completion?(nil, error)
        }
    }

    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        // Handle errors such as resumeData extraction
        guard let src = task.originalRequest?.url else { return }
        if let err = error as NSError?, let resumeData = err.userInfo[NSURLSessionDownloadTaskResumeData] as? Data {
            // Save resumeData to disk for later resumption
            let key = src.absoluteString.data(using: .utf8)!.base64EncodedString()
            let url = FileManager.default.temporaryDirectory.appendingPathComponent(key)
            try? resumeData.write(to: url)
        }
        let completion = queue.sync { activeHandlers.removeValue(forKey: src) }
        completion?(nil, error)
    }

    public func urlSession(_ session: URLSession, task: URLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
        // for uploads: could notify upload progress; kept simple here
    }

    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        // download progress - could be bridged to listeners via notifications
    }
}
