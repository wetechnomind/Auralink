#  Auralink – The Modern Swift Networking Engine (v1.0.0)

[![Build Status](https://github.com/WeTechnoMind/Auralink/actions/workflows/ci.yml/badge.svg)](https://github.com/WeTechnoMind/Auralink/actions)
[![Swift](https://img.shields.io/badge/Swift-5.7%2B-orange.svg)](https://swift.org)
![Platforms](https://img.shields.io/badge/Platforms-iOS%20%7C%20macOS%20%7C%20watchOS%20%7C%20tvOS-blue.svg)
![License](https://img.shields.io/badge/License-MIT-green.svg)
![Version](https://img.shields.io/badge/Version-1.0.0-blue.svg)

Auralink is a **pure Swift Concurrency–based** networking library designed as a modern replacement for Alamofire.  
Lightweight, fast, and beginner-friendly — it’s built to simplify async/await HTTP networking while offering advanced power features.

---

##  Table of Contents
- [ Features](#-features)
- [ Installation](#-installation)
- [ Quick Start](#-quick-start)
- [ Architecture Overview](#-architecture-overview)
- [ Advanced Examples](#-advanced-examples)
- [ Testing & CI](#-testing--ci)
- [ Documentation](#-documentation)
- [ Contributing](#-contributing)
- [ License](#-license)
- [ Download ZIP](#️-download-zip)

---

##  Features

| Category | Description |
|-----------|--------------|
| **Language Support** | Pure Swift Concurrency (async/await) |
| **Dependency Size** | Lightweight – only uses Foundation |
| **Performance** | Optimized for speed and low memory usage |
| **Request Handling** | SmartRequest engine with automatic configuration |
| **Response Decoding** |  Auto-decodes any Codable model (nested objects supported) |
| **Error Handling** | Detailed smart error system with hints and suggestions |
| **Retry Logic** | Automatic retry with exponential backoff |
| **Caching** | Smart memory + disk caching with TTL |
| **Logging** | Advanced request/response summary & timing |
| **Multipart Uploads** | Simple uploadMultipart() with progress and async/await |
| **File Download** | Resumable + optional background mode |
| **Network Reachability** | Smart network listener with auto-retry when online |
| **Offline Support** | Offline queue (executes pending requests when reconnected) |
| **Interceptors** | Token auto-refresh and adapter chain support |
| **Progress Tracking** | Real-time upload/download progress |
| **AI Insights (unique)** | Detects slow endpoints & suggests optimizations |
| **Ease of Use** | Extremely beginner-friendly syntax |
| **Platform Support** | iOS, macOS, watchOS, tvOS |
| **License** | MIT |

---

## Installation

### Swift Package Manager
1. In Xcode, go to **File → Add Packages…**
2. Enter:
   ```swift
   https://github.com/WeTechnoMind/Auralink.git
   ```
3. Select **Version: 1.0.0** (exact tag).

Or manually add to `Package.swift`:
```swift
dependencies: [
    .package(url: "https://github.com/WeTechnoMind/Auralink.git", from: "1.0.0")
]
```

---

## Quick Start
```swift
import Auralink

struct Post: Codable {
    let id: Int
    let title: String
    let body: String
}

@MainActor
func fetchPost() async {
    let client = AuralinkClient(configuration: .init(baseURL: URL(string: "https://jsonplaceholder.typicode.com")))
    do {
        let request = AuralinkRequest(path: "/posts/1", method: .GET)
        let post: Post = try await client.request(request)
        print("Fetched:", post.title)
    } catch {
        print("Error:", error)
    }
}
```

---

## Architecture Overview

```

## Advanced Examples

### 1. POST Request with Body
```swift
let client = AuralinkClient(configuration: .init(baseURL: URL(string: "https://jsonplaceholder.typicode.com")))
let request = AuralinkRequest(path: "/posts", method: .POST, body: [
    "title": "Hello World",
    "body": "Auralink makes networking easy!",
    "userId": 1
])
let response: Post = try await client.request(request)
```

### 2. Multipart Upload with Progress
```swift
try await client.uploadMultipart(
    to: "/upload",
    files: [("file1.jpg", imageData, "image/jpeg")],
    onProgress: { progress in
        print("Upload progress:", progress.fractionCompleted)
    }
)
```

### 3. File Download (Resumable)
```swift
let fileURL = try await client.download(
    from: "/bigfile.zip",
    to: FileManager.default.temporaryDirectory.appendingPathComponent("bigfile.zip"),
    onProgress: { p in print("Download:", p.fractionCompleted) }
)
```

### 4. Token Auto-Refresh Interceptor
```swift
let interceptor = AuralinkTokenRefreshInterceptor(
    initialToken: "initial_token",
    refreshURL: URL(string: "https://example.com/api/refresh")
)
let chain = AuralinkInterceptorChain(interceptors: [interceptor])
let client = AuralinkClient(configuration: .init(baseURL: URL(string: "https://api.example.com")), adapter: chain)
```

### 5. Offline Queue Example
```swift
try await client.requestOfflineSafe(
    AuralinkRequest(path: "/sync", method: .POST, body: ["data": "cached"])
)
```

---

## Testing & CI

Run unit tests:
```bash
swift test
```

GitHub Actions CI (`.github/workflows/ci.yml`) automatically builds and tests on macOS.

---

## Documentation

Build local documentation:
```bash
swift package generate-documentation --target Auralink --output-path ./docs
```
Or open `Docs/Auralink.docc` in Xcode.

---

## Contributing

Contributions are welcome!  
Please read the `CONTRIBUTING.md` before submitting pull requests.

Checklist:
- Run `swift build` and `swift test`
- Add tests for new features
- Update `CHANGELOG.md`
- Follow naming convention (`Auralink*` prefix)

---

## License

Auralink is available under the MIT License.  
See the LICENSE file for details.

---

## Author

**WeTechnoMind**  
Crafted with ❤️ in Swift — lightweight, fast, and ready for modern apps.

---

## Download ZIP

You can download the latest version directly from GitHub:  
- [Download Auralink v1.0.0 (ZIP)](https://github.com/WeTechnoMind/Auralink/archive/refs/tags/v1.0.0.zip)
