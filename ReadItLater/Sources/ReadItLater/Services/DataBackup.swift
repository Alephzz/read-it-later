import Foundation
import AppKit

/// 数据备份：导出为 JSON 文件 / 从 JSON 文件导入
enum DataBackup {

    static func exportJSON(items: [Item]) -> Data? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return try? encoder.encode(items)
    }

    /// 解码导入的 JSON。兼容旧格式：接受 `[Item]` 数组或 `{ "items": [...] }` 包装
    static func decodeItems(from data: Data) -> [Item]? {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        if let items = try? decoder.decode([Item].self, from: data) {
            return items
        }
        if let wrapper = try? decoder.decode([String: [Item]].self, from: data),
           let items = wrapper["items"] {
            return items
        }
        return nil
    }

    static func writeToFile(data: Data, suggestedName: String) {
        let panel = NSSavePanel()
        panel.title = "导出数据"
        panel.nameFieldStringValue = suggestedName
        panel.allowedContentTypes = [.json]
        panel.canCreateDirectories = true
        guard panel.runModal() == .OK, let url = panel.url else { return }
        do {
            try data.write(to: url, options: .atomic)
        } catch {
            presentError("导出失败：\(error.localizedDescription)")
        }
    }

    static func pickAndRead() -> Data? {
        let panel = NSOpenPanel()
        panel.title = "导入数据"
        panel.allowedContentTypes = [.json]
        panel.allowsMultipleSelection = false
        guard panel.runModal() == .OK, let url = panel.url else { return nil }
        return try? Data(contentsOf: url)
    }

    static func presentError(_ message: String) {
        let alert = NSAlert()
        alert.messageText = message
        alert.alertStyle = .warning
        alert.addButton(withTitle: "好")
        alert.runModal()
    }
}
