// main.swift
import Foundation

class JSONStreamer: NSObject {
    let url: URL
    let outputFile: URL
    var session: URLSession!
    var task: URLSessionDataTask?
    let sseEventParser = ServerSentEventParser()

    init(url: URL, outputFile: URL) {
        self.url = url
        self.outputFile = outputFile
        super.init()
        self.session = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
    }

    func startStreaming() {
        print("Start streaming")

        var request = URLRequest(url: url)
        request.setValue("text/event-stream", forHTTPHeaderField: "Accept")

        task = session.dataTask(with: request)
        task?.resume()
    }

    func appendJSONToFile(jsonString: String) throws {
        let data = (jsonString + "\n").data(using: .utf8)!
        try append(data: data, to: outputFile)
    }
    
    func append(data: Data, to url: URL) throws {
        if let fileHandle = try? FileHandle(forWritingTo: url) {
            defer { fileHandle.closeFile() }
            fileHandle.seekToEndOfFile()
            fileHandle.write(data)
        } else {
            try data.write(to: url)
        }
    }
}

extension JSONStreamer: URLSessionDataDelegate {
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        print("Parsing data")
        sseEventParser.parse(data: data) { json in
            print(json)
            do {
                try self.appendJSONToFile(jsonString: json)
                print("JSON appended to file. \(json)")
            } catch {
                print("Error appending JSON to file: \(error)")
            }
        }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            print("Error: \(error)")
            return
        }
        print("Task completed.")
    }
}

// ServerSentEventParser.swift
import Foundation

class ServerSentEventParser {
    private var buffer = ""

    func parse(data: Data, eventHandler: (String) -> Void) {
        if let chunk = String(data: data, encoding: .utf8) {
            buffer += chunk

            while let (event, remaining) = extractEvent(buffer) {
                buffer = remaining
                eventHandler(event)
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
}

let streamURL = URL(string: "http://localhost:8000/api/stream_test")!
// outputFile relative to the cwd path
let outputFile = URL(fileURLWithPath: "output.json")


let jsonStreamer = JSONStreamer(url: streamURL, outputFile: outputFile)

jsonStreamer.startStreaming()

RunLoop.main.run(until: Date(timeIntervalSinceNow: 15))
