import Foundation

struct SSEStream: AsyncSequence {
    let urlRequest: URLRequest

    typealias Element = Result<String, Error>
    typealias AsyncIterator = URLSessionIterator

    func makeAsyncIterator() -> URLSessionIterator {
        return URLSessionIterator(urlRequest: urlRequest)
    }
}

final class URLSessionIterator: NSObject, AsyncIteratorProtocol, URLSessionDataDelegate, URLSessionTaskDelegate, URLSessionDelegate {
    let urlRequest: URLRequest
    var buffer: String = ""
    let task: URLSessionDataTask
    var continuation: CheckedContinuation<Element, Never>?

    init(urlRequest: URLRequest) {
        self.urlRequest = urlRequest
        let session = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
        self.task = session.dataTask(with: urlRequest)
    }

    func next() async -> Element? {
        await withOptionalCheckedContinuation { continuation in
            self.continuation = continuation
            self.task.resume()
        }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            continuation?.resume(throwing: error)
        } else {
            continuation?.resume(returning: nil)
        }
    }

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        guard let chunk = String(data: data, encoding: .utf8) else { return }
        buffer += chunk
        while let (event, remaining) = extractEvent(buffer) {
            buffer = remaining
            continuation?.resume(returning: .success(event))
        }
    }
}

private func extractEvent(_ string: String) -> (String, String)? {
    if let range = string.range(of: "\n\n") {
            let event = String(string[string.startIndex..<range.lowerBound])
            let remaining = String(string[range.upperBound...])
            return (event, remaining)
        }
        return nil
}

func sseEvents(for request: URLRequest) -> SSEStream {
    return SSEStream(urlRequest: request)
}

// Example usage:

let url = URL(string: "https://example.com/sse")!
let request = URLRequest(url: url)

let sseStream = sseEvents(for: request)

Task {
    do {
        for try await result in sseStream {
            switch result {
            case .success(let event):
                print("Received event: \(event)")
            case .failure(let error):
                print("Error: \(error)")
            }
        }
    } catch {
        print("Caught error: \(error)")
    }
}

RunLoop.main.run()