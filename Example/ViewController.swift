import UIKit
import Auralink

class ViewController: UIViewController {
    let client: AuralinkClient = {
        let cfg = AuralinkClient.Configuration(baseURL: URL(string: "https://jsonplaceholder.typicode.com"))
        // Example interceptor with simulated refresh endpoint
        let tokenInterceptor = AuralinkTokenRefreshInterceptor(initialToken: nil, refreshURL: URL(string: "https://example.com/refresh"))
        let chain = AuralinkInterceptorChain(interceptors: [tokenInterceptor])
        return AuralinkClient(configuration: cfg, adapter: chain)
    }()

    let stack = UIStackView()
    let statusLabel = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupUI()
    }

    func setupUI() {
        stack.axis = .vertical
        stack.spacing = 12
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            stack.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.9)
        ])

        let fetchBtn = makeButton(title: "Fetch GET /posts/1", action: #selector(fetchTapped))
        let postBtn = makeButton(title: "POST /posts", action: #selector(postTapped))
        let uploadBtn = makeButton(title: "Multipart Upload (simulate)", action: #selector(uploadTapped))
        let downloadBtn = makeButton(title: "Download File (simulate)", action: #selector(downloadTapped))
        let offlineBtn = makeButton(title: "Enqueue Offline Request", action: #selector(offlineTapped))
        let cacheBtn = makeButton(title: "Show Cache Keys", action: #selector(cacheTapped))
        let aiBtn = makeButton(title: "Show AI Insights", action: #selector(aiTapped))

        [fetchBtn, postBtn, uploadBtn, downloadBtn, offlineBtn, cacheBtn, aiBtn].forEach { stack.addArrangedSubview($0) }

        statusLabel.numberOfLines = 0
        statusLabel.textAlignment = .center
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(statusLabel)
        NSLayoutConstraint.activate([
            statusLabel.topAnchor.constraint(equalTo: stack.bottomAnchor, constant: 20),
            statusLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            statusLabel.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.9)
        ])
    }

    func makeButton(title: String, action: Selector) -> UIButton {
        let b = UIButton(type: .system)
        b.setTitle(title, for: .normal)
        b.backgroundColor = UIColor.systemGray6
        b.layer.cornerRadius = 8
        b.contentEdgeInsets = UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16)
        b.translatesAutoresizingMaskIntoConstraints = false
        b.widthAnchor.constraint(equalToConstant: 320).isActive = true
        b.addTarget(self, action: action, for: .touchUpInside)
        return b
    }

    @objc func fetchTapped() {
        statusLabel.text = "Fetching..."
        Task {
            struct Post: Decodable { let id: Int; let title: String; let body: String }
            do {
                let req = AuralinkRequest(path: "/posts/1", method: .GET)
                let post: Post = try await client.request(req)
                statusLabel.text = "Fetched: \(post.title)"
            } catch {
                statusLabel.text = "Fetch failed: \(error.localizedDescription)"
            }
        }
    }

    @objc func postTapped() {
        statusLabel.text = "Posting..."
        Task {
            do {
                let body: [String: Any] = ["title":"Hello","body":"From Auralink example","userId":1]
                var req = AuralinkRequest(path: "/posts", method: .POST)
                req.body = try JSONSerialization.data(withJSONObject: body)
                let resp: [String: Any] = try await client.request(req)
                statusLabel.text = "Post response: \(resp)"
            } catch {
                statusLabel.text = "Post failed: \(error.localizedDescription)"
            }
        }
    }

    @objc func uploadTapped() {
        statusLabel.text = "Uploading (simulated)..."
        Task {
            do {
                var multipart = AuralinkMultipartRequest(path: "/posts") // using posts endpoint as placeholder
                multipart.addFormField(name: "title", value: "Demo")
                let sample = "Hello".data(using: .utf8)!
                multipart.addFile(fieldName: "file", filename: "hello.txt", mimeType: "text/plain", data: sample)
                // Note: uploadMultipart uses URLSession.uploadTask internally
                struct Resp: Decodable { let id: Int }
                let resp: Resp = try await client.uploadMultipart(multipart) { p in
                    DispatchQueue.main.async { self.statusLabel.text = "Upload: \(Int(p*100))%" }
                }
                statusLabel.text = "Upload done: \(resp.id)"
            } catch {
                statusLabel.text = "Upload failed: \(error.localizedDescription)"
            }
        }
    }

    @objc func downloadTapped() {
        statusLabel.text = "Downloading (simulated)..."
        Task {
            do {
                guard let url = URL(string: "https://speed.hetzner.de/100MB.bin") else { return }
                let dest = FileManager.default.temporaryDirectory.appendingPathComponent("100MB.bin")
                AuralinkDownloadManager.shared.download(url: url, to: dest, progress: { p in
                    DispatchQueue.main.async { self.statusLabel.text = "Download: \(Int(p*100))%" }
                }, completion: { local, err in
                    DispatchQueue.main.async {
                        if let local = local {
                            self.statusLabel.text = "Downloaded to: \(local.path)"
                        } else {
                            self.statusLabel.text = "Download failed: \(err?.localizedDescription ?? "unknown")"
                        }
                    }
                })
            } catch {
                statusLabel.text = "Download error: \(error.localizedDescription)"
            }
        }
    }

    @objc func offlineTapped() {
        statusLabel.text = "Enqueueing offline request..."
        // Example: enqueue a job that will run when network back
        AuralinkOfflineQueue.shared.enqueue {
            Task {
                do {
                    var req = AuralinkRequest(path: "/posts", method: .POST)
                    req.body = try JSONSerialization.data(withJSONObject: ["title":"offline","body":"queued","userId":1])
                    let _: [String: Any] = try await self.client.request(req)
                    print("Offline request sent")
                } catch {
                    print("Offline job failed: \(error)") 
                }
            }
        }
        statusLabel.text = "Request enqueued"
    }

    @objc func cacheTapped() {
        statusLabel.text = "Cache keys: \(AuralinkCache.shared)"
    }

    @objc func aiTapped() {
        // Example suggestion check
        let ep = "https://jsonplaceholder.typicode.com/posts/1"
        if let suggestion = AuralinkAIInsights.shared.suggestion(for: ep) {
            statusLabel.text = suggestion
        } else {
            statusLabel.text = "No suggestions for endpoint yet."
        }
    }
}
