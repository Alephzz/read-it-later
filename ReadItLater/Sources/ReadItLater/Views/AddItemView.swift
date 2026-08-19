import SwiftUI

struct AddItemView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var store: ItemStore
    @State private var urlInput: String = ""
    @State private var titleInput: String = ""
    @State private var tagsInput: String = ""
    @State private var isSaving = false
    @State private var errorMessage: String?
    private let database = DatabaseService.shared
    private let scraper = WebScraper()

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("添加链接")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)

            VStack(alignment: .leading, spacing: 4) {
                Text("URL")
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.4))
                TextField("https://example.com/article", text: $urlInput)
                    .textFieldStyle(.plain)
                    .foregroundColor(.white)
                    .font(.system(size: 13, design: .monospaced))
                    .padding(8)
                    .background(Color.white.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("标题（可选，留空自动抓取）")
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.4))
                TextField("文章标题", text: $titleInput)
                    .textFieldStyle(.plain)
                    .foregroundColor(.white)
                    .font(.system(size: 13))
                    .padding(8)
                    .background(Color.white.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("标签（可选，逗号分隔）")
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.4))
                TextField("AI, 效率", text: $tagsInput)
                    .textFieldStyle(.plain)
                    .foregroundColor(.white)
                    .font(.system(size: 13))
                    .padding(8)
                    .background(Color.white.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            }

            if let error = errorMessage {
                Text(error)
                    .font(.system(size: 11))
                    .foregroundColor(.red)
            }

            HStack {
                Spacer()
                Button("取消") { dismiss() }
                    .buttonStyle(.plain)
                    .foregroundColor(.white.opacity(0.5))
                    .font(.system(size: 12))

                Button(isSaving ? "保存中..." : "保存") {
                    save()
                }
                .buttonStyle(.plain)
                .foregroundColor(.white)
                .font(.system(size: 12, weight: .medium))
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
                .background(isSaving ? Color.gray : Color.orange)
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .disabled(isSaving)
            }
        }
        .padding(20)
        .frame(width: 400, height: 280)
        .background(Color(red: 0.13, green: 0.13, blue: 0.15))
    }

    private func save() {
        let urlString = urlInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !urlString.isEmpty else {
            errorMessage = "请输入 URL"
            return
        }
        guard URL(string: urlString) != nil else {
            errorMessage = "URL 格式不正确"
            return
        }

        if database.existsNormalized(url: urlString) {
            errorMessage = "该链接已存在"
            return
        }

        isSaving = true
        let domain = extractDomain(from: urlString)

        let item = Item(
            id: UUID(),
            url: urlString,
            content: urlString,
            title: titleInput.isEmpty ? urlString : titleInput,
            summary: nil,
            faviconData: nil,
            domain: domain,
            tags: TagParser.parse(tagsInput),
            status: .unread,
            createdAt: Date(),
            readAt: nil
        )

        do {
            try database.save(item)
            store.refresh()
            NotificationCenter.default.post(name: .itemsDidChange, object: nil)

            if titleInput.isEmpty {
                Task {
                    if let result = await scraper.scrape(urlString) {
                        var updated = item
                        if !result.title.isEmpty { updated.title = result.title }
                        updated.summary = result.description
                        updated.faviconData = result.faviconData
                        database.updateItem(updated)
                        store.refresh()
                    }
                }
            }
            dismiss()
        } catch {
            errorMessage = "保存失败: \(error.localizedDescription)"
            isSaving = false
        }
    }

    private func extractDomain(from urlString: String) -> String {
        guard let url = URL(string: urlString), let host = url.host else { return "unknown" }
        return host.replacingOccurrences(of: "www.", with: "")
    }
}
