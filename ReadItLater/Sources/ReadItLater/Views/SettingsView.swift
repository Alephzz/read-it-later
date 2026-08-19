import SwiftUI

struct SettingsView: View {
    @AppStorage("autoScrape") private var autoScrape: Bool = true
    @AppStorage("stalenessDays") private var stalenessDays: String = "7,30"
    @AppStorage("displayLanguage") private var displayLanguage: String = "auto"
    @AppStorage("showSummary") private var showSummary: Bool = true

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("设置")
                    .font(.system(size: 18, weight: .bold))

                Divider()

                VStack(alignment: .leading, spacing: 12) {
                    Text("显示")
                        .font(.system(size: 14, weight: .semibold))

                    Toggle("显示摘要预览", isOn: $showSummary)
                        .toggleStyle(.switch)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("标题和摘要显示语言")
                            .font(.system(size: 13))
                        Picker("语言", selection: $displayLanguage) {
                            Text("自动（跟随网页）").tag("auto")
                            Text("中文").tag("zh")
                            Text("English").tag("en")
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 320)
                    }
                }

                Divider()

                Toggle("自动抓取网页信息", isOn: $autoScrape)
                    .toggleStyle(.switch)

                VStack(alignment: .leading, spacing: 8) {
                    Text("陈旧提醒天数")
                        .font(.system(size: 14, weight: .semibold))
                    Text("格式：变黄天数,变红天数（如 7,30）")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                    TextField("7,30", text: $stalenessDays)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 100)
                }

                Divider()

                VStack(alignment: .leading, spacing: 8) {
                    Text("数据")
                        .font(.system(size: 14, weight: .semibold))
                    HStack(spacing: 8) {
                        Button("导出数据") { exportData() }
                            .buttonStyle(.bordered)
                        Button("导入数据") { importData() }
                            .buttonStyle(.bordered)
                    }
                    Text("导出为 JSON 文件，可备份或迁移到其他电脑")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }

                Divider()

                VStack(alignment: .leading, spacing: 4) {
                    Text("快捷键")
                        .font(.system(size: 14, weight: .semibold))
                    Text("⌘+Shift+R  打开/收起刘海面板")
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(.secondary)
                }

                Divider()

                Text("Read It Later v1.0")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
            .padding(24)
            .frame(width: 380)
        }
    }

    // MARK: - 数据备份

    private func exportData() {
        let items = DatabaseService.shared.fetchAll()
        guard let data = DataBackup.exportJSON(items: items) else {
            DataBackup.presentError("导出失败：无法序列化数据")
            return
        }
        let date = ISO8601DateFormatter().string(from: Date()).replacingOccurrences(of: ":", with: "-")
        DataBackup.writeToFile(data: data, suggestedName: "ReadItLater-\(date).json")
    }

    private func importData() {
        guard let data = DataBackup.pickAndRead() else { return }
        guard let items = DataBackup.decodeItems(from: data), !items.isEmpty else {
            DataBackup.presentError("导入失败：文件不是有效的备份格式")
            return
        }
        DatabaseService.shared.saveItems(items)
        NotificationCenter.default.post(name: .itemsDidChange, object: nil)
        DataBackup.presentError("已导入 \(items.count) 条记录")
    }
}
