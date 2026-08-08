import Foundation

struct ScrapeResult {
    let title: String
    let description: String?
    let faviconData: Data?
}

final class WebScraper {
    func scrape(_ urlString: String) async -> ScrapeResult? {
        guard let url = URL(string: urlString) else { return nil }

        var request = URLRequest(url: url)
        request.timeoutInterval = 5
        request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36", forHTTPHeaderField: "User-Agent")

        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            guard let html = String(data: data, encoding: .utf8) else { return nil }

            let title = extractTitle(from: html)
            let description = extractDescription(from: html)
            let faviconURL = extractFaviconURL(from: html, baseURL: url)
            let faviconData = await fetchFavicon(from: faviconURL, baseURL: url)

            return ScrapeResult(title: title, description: description, faviconData: faviconData)
        } catch {
            return nil
        }
    }

    // MARK: - HTML Parsing

    private func extractTitle(from html: String) -> String {
        // Try <title> tag
        if let range = html.range(of: #"<title[^>]*>(.*?)</title>"#, options: .regularExpression) {
            let titleTag = String(html[range])
            let content = titleTag
                .replacingOccurrences(of: #"<[^>]+>"#, with: "", options: .regularExpression)
                .trimmingCharacters(in: .whitespacesAndNewlines)
            if !content.isEmpty { return content }
        }

        // Try og:title
        if let ogTitle = extractMetaContent(from: html, property: "og:title"), !ogTitle.isEmpty {
            return ogTitle
        }

        return "Untitled"
    }

    private func extractDescription(from html: String) -> String? {
        // Try og:description
        if let ogDesc = extractMetaContent(from: html, property: "og:description"), !ogDesc.isEmpty {
            return ogDesc
        }

        // Try meta description
        if let metaDesc = extractMetaContent(from: html, name: "description"), !metaDesc.isEmpty {
            return metaDesc
        }

        return nil
    }

    private func extractFaviconURL(from html: String, baseURL: URL) -> URL? {
        // Try <link rel="icon" href="...">
        let patterns = [
            #"<link[^>]*rel=["'](?:shortcut )?icon["'][^>]*href=["']([^"']+)["']"#,
            #"<link[^>]*href=["']([^"']+)["'][^>]*rel=["'](?:shortcut )?icon["']"#,
        ]

        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
               let match = regex.firstMatch(in: html, range: NSRange(html.startIndex..., in: html)),
               let urlRange = Range(match.range(at: 1), in: html) {
                let href = String(html[urlRange])
                return resolveURL(href, baseURL: baseURL)
            }
        }

        // Fallback: /favicon.ico
        return baseURL.appendingPathComponent("favicon.ico")
    }

    private func fetchFavicon(from faviconURL: URL?, baseURL: URL) async -> Data? {
        let url = faviconURL ?? baseURL.appendingPathComponent("favicon.ico")

        var request = URLRequest(url: url)
        request.timeoutInterval = 3

        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            return data.isEmpty ? nil : data
        } catch {
            return nil
        }
    }

    // MARK: - Helpers

    private func extractMetaContent(from html: String, property: String) -> String? {
        let pattern = #"<meta[^>]*property=["']\#(property)["'][^>]*content=["']([^"']+)["']"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
              let match = regex.firstMatch(in: html, range: NSRange(html.startIndex..., in: html)),
              let contentRange = Range(match.range(at: 1), in: html) else { return nil }
        return String(html[contentRange])
    }

    private func extractMetaContent(from html: String, name: String) -> String? {
        let pattern = #"<meta[^>]*name=["']\#(name)["'][^>]*content=["']([^"']+)["']"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
              let match = regex.firstMatch(in: html, range: NSRange(html.startIndex..., in: html)),
              let contentRange = Range(match.range(at: 1), in: html) else { return nil }
        return String(html[contentRange])
    }

    private func resolveURL(_ href: String, baseURL: URL) -> URL? {
        if href.hasPrefix("http://") || href.hasPrefix("https://") {
            return URL(string: href)
        }
        if href.hasPrefix("//") {
            return URL(string: baseURL.scheme! + ":" + href)
        }
        return URL(string: href, relativeTo: baseURL)?.absoluteURL
    }
}
