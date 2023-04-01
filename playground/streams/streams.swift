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
    var urlRequest: URLRequest
    var buffer: String = ""
    var task: URLSessionDataTask!
    var continuation: CheckedContinuation<Element, Never>?
    var isCompleted: Bool = false
    private var session: URLSession!


    typealias Element = Result<String, Error>

    init(urlRequest: URLRequest) {
        self.urlRequest = urlRequest
        super.init()
        self.session = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
        self.task = session.dataTask(with: urlRequest)
    }

    func next() async -> Element? {
        if isCompleted {
            return nil 
        }
        
        return await withCheckedContinuation { (continuation: CheckedContinuation<Element, Never>) in
            self.continuation = continuation
            self.task.resume()
        }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            continuation?.resume(returning: .failure(error))
        } else {
            isCompleted = true
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

    deinit {
        session.finishTasksAndInvalidate()
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

let url = URL(string: "http://localhost:8000/api/stream_test")!
let request = URLRequest(url: url)

let sseStream = sseEvents(for: request)

Task {
    for try await result in sseStream {
        switch result {
        case .success(let event):
            print("Received event: \(event)")
        case .failure(let error):
            print("Error: \(error)")
        }
    }

    print("Stream completed")
}

// Add signal handler for SIGINT
var signalInterrupt = false
let signalHandler: @convention(c) (Int32) -> Void = { _ in
    signalInterrupt = true
    CFRunLoopStop(CFRunLoopGetCurrent())
}
signal(SIGINT, signalHandler)

// Run the main run loop until a signal interrupt occurs
while !signalInterrupt {
    RunLoop.current.run(mode: .default, before: .distantFuture)
}