import Foundation

/// Utility for detecting duplicate URLs before saving
enum DuplicateDetector {
    static func isDuplicate(url: String, existingItems: [Item]) -> Bool {
        let normalizedURL = normalize(url)
        return existingItems.contains { normalize($0.url ?? "") == normalizedURL }
    }

    /// Normalize URL: remove trailing slash, lowercase scheme+host, remove common tracking params
    static func normalize(_ urlString: String) -> String {
        var str = urlString.trimmingCharacters(in: .whitespacesAndNewlines)

        // Remove trailing slash
        while str.hasSuffix("/") {
            str = String(str.dropLast())
        }

        // Lowercase scheme and host
        if let url = URL(string: str),
           let scheme = url.scheme?.lowercased(),
           let host = url.host?.lowercased() {
            var normalized = "\(scheme)://\(host)"
            if let port = url.port { normalized += ":\(port)" }
            if let path = url.path.isEmpty ? nil : url.path { normalized += path }
            // Remove common tracking query params
            let trackingParams = ["utm_source", "utm_medium", "utm_campaign", "utm_term", "utm_content", "fbclid", "ref"]
            if let queryItems = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems {
                let filtered = queryItems.filter { !trackingParams.contains($0.name) }
                if !filtered.isEmpty {
                    let queryString = filtered.map { "\($0.name)=\($0.value ?? "")" }.joined(separator: "&")
                    normalized += "?" + queryString
                }
            }
            return normalized
        }

        return str.lowercased()
    }
}
