import Foundation
import Network
import AppKit

final class HTTPServerService {
    private var listener: NWListener?
    private let port: UInt16 = 19623
    private let database = DatabaseService.shared
    private let scraper = WebScraper()
    private var connections: [NWConnection] = []
    private let connectionsLock = NSLock()

    func start() {
        do {
            let params = NWParameters.tcp
            params.acceptLocalOnly = true
            listener = try NWListener(using: params, on: NWEndpoint.Port(rawValue: port)!)
            listener?.stateUpdateHandler = { [weak self] state in
                switch state {
                case .ready:
                    print("HTTP server ready on port \(self?.port ?? 0)")
                case .failed(let error):
                    print("HTTP server failed: \(error)")
                default:
                    break
                }
            }
            listener?.newConnectionHandler = { [weak self] conn in
                self?.handleConnection(conn)
            }
            listener?.start(queue: .global(qos: .userInitiated))
        } catch {
            print("Failed to start HTTP server: \(error)")
        }
    }

    func stop() {
        listener?.cancel()
        connectionsLock.lock()
        let conns = connections
        connections.removeAll()
        connectionsLock.unlock()
        conns.forEach { $0.cancel() }
    }

    // MARK: - Connection Handling

    private func handleConnection(_ conn: NWConnection) {
        connectionsLock.lock()
        connections.append(conn)
        connectionsLock.unlock()

        // 连接结束（取消/失败）时从数组中移除，避免长期运行后缓慢泄漏
        conn.stateUpdateHandler = { [weak self] state in
            switch state {
            case .cancelled, .failed:
                self?.connectionsLock.lock()
                self?.connections.removeAll { $0 === conn }
                self?.connectionsLock.unlock()
            default:
                break
            }
        }

        conn.start(queue: .global(qos: .userInitiated))
        receiveRequest(conn)
    }

    private func receiveRequest(_ conn: NWConnection) {
        conn.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self] data, _, isComplete, error in
            guard let self, let data, !data.isEmpty else {
                if isComplete { conn.cancel() }
                return
            }

            guard let request = String(data: data, encoding: .utf8) else {
                conn.cancel()
                return
            }

            let response = self.route(request)
            let responseData = response.data(using: .utf8) ?? Data()

            conn.send(content: responseData, completion: .contentProcessed { _ in
                conn.cancel()
            })
        }
    }

    // MARK: - Routing

    private func route(_ request: String) -> String {
        let lines = request.components(separatedBy: "\r\n")
        guard let requestLine = lines.first else {
            return httpResponse(400, body: "{\"error\":\"Bad Request\"}")
        }
        let parts = requestLine.components(separatedBy: " ")
        guard parts.count >= 2 else {
            return httpResponse(400, body: "{\"error\":\"Bad Request\"}")
        }

        let method = parts[0]
        let fullPath = parts[1]
        let path = fullPath.components(separatedBy: "?").first ?? fullPath
        let queryString = fullPath.contains("?") ? fullPath.components(separatedBy: "?").last ?? "" : ""

        // Parse body
        let bodyData = request.components(separatedBy: "\r\n\r\n").dropFirst().joined(separator: "\r\n\r\n")

        switch (method, path) {
        case ("POST", "/api/save"):
            return handleSave(bodyData)
        case ("GET", "/api/status"):
            return httpResponse(200, body: "{\"status\":\"running\"}")
        case ("GET", "/api/exists"):
            let params = parseQueryString(queryString)
            guard let url = params["url"] else {
                return httpResponse(400, body: "{\"error\":\"Missing url\"}")
            }
            let exists = database.existsNormalized(url: url)
            return httpResponse(200, body: "{\"exists\":\(exists)}")
        case ("GET", "/api/items"):
            let items = database.fetchAll()
            let json = itemsToJSON(items)
            return httpResponse(200, body: json)
        case ("OPTIONS", _):
            return corsResponse()
        default:
            return httpResponse(404, body: "{\"error\":\"Not Found\"}")
        }
    }

    // MARK: - Handlers

    private func handleSave(_ body: String) -> String {
        guard let data = body.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let urlString = json["url"] as? String else {
            return httpResponse(400, body: "{\"error\":\"Invalid JSON\"}")
        }

        let title = json["title"] as? String ?? urlString
        // 兼容：扩展端传拆分好的数组，或直接传逗号分隔字符串
        var tags: [String] = []
        if let tagArray = json["tags"] as? [String] {
            tags = tagArray.map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        } else if let tagString = json["tags"] as? String {
            tags = TagParser.parse(tagString)
        }

        if database.existsNormalized(url: urlString) {
            return httpResponse(200, body: "{\"success\":false,\"message\":\"URL already saved\"}")
        }

        let domain = extractDomain(from: urlString)
        let item = Item(
            id: UUID(), url: urlString, content: urlString, title: title,
            summary: nil, faviconData: nil, domain: domain, tags: tags,
            status: .unread, createdAt: Date(), readAt: nil
        )

        do {
            try database.save(item)
            NotificationCenter.default.post(name: .itemsDidChange, object: nil)
            // Async scrape
            Task { await scrapeAndUpdate(item: item) }
            return httpResponse(200, body: "{\"success\":true,\"message\":\"Saved\"}")
        } catch {
            return httpResponse(500, body: "{\"error\":\"Save failed\"}")
        }
    }

    // MARK: - Helpers

    private func extractDomain(from urlString: String) -> String {
        guard let url = URL(string: urlString), let host = url.host else { return "unknown" }
        return host.replacingOccurrences(of: "www.", with: "")
    }

    private func scrapeAndUpdate(item: Item) async {
        guard let urlString = item.url else { return }
        guard let result = await scraper.scrape(urlString) else { return }

        var updatedItem = item
        if !result.title.isEmpty { updatedItem.title = result.title }
        updatedItem.summary = result.description
        updatedItem.faviconData = result.faviconData
        database.updateItem(updatedItem)
    }

    private func parseQueryString(_ qs: String) -> [String: String] {
        var dict: [String: String] = [:]
        for pair in qs.components(separatedBy: "&") {
            let kv = pair.components(separatedBy: "=")
            if kv.count == 2 {
                dict[kv[0]] = kv[1].removingPercentEncoding ?? kv[1]
            }
        }
        return dict
    }

    private func itemsToJSON(_ items: [Item]) -> String {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let encodableItems = items.map { ItemEncodable(item: $0) }
        guard let data = try? encoder.encode(encodableItems),
              let str = String(data: data, encoding: .utf8) else {
            return "[]"
        }
        return str
    }

    private func httpResponse(_ code: Int, body: String) -> String {
        let statusText = code == 200 ? "OK" : code == 400 ? "Bad Request" : code == 404 ? "Not Found" : "Internal Server Error"
        return """
        HTTP/1.1 \(code) \(statusText)\r
        Content-Type: application/json\r
        Content-Length: \(body.utf8.count)\r
        Access-Control-Allow-Origin: *\r
        Access-Control-Allow-Methods: GET, POST, OPTIONS\r
        Access-Control-Allow-Headers: Content-Type\r
        Connection: close\r
        \r
        \(body)
        """
    }

    private func corsResponse() -> String {
        httpResponse(204, body: "")
    }
}

// MARK: - JSON Encodable wrapper

private struct ItemEncodable: Encodable {
    let id: String
    let url: String?
    let title: String
    let summary: String?
    let domain: String
    let status: Int
    let createdAt: Date

    init(item: Item) {
        self.id = item.id.uuidString
        self.url = item.url
        self.title = item.title
        self.summary = item.summary
        self.domain = item.domain
        self.status = item.status.rawValue
        self.createdAt = item.createdAt
    }
}
