import SwiftUI

struct SettingsView: View {
    @AppStorage("httpPort") private var httpPort: Int = 19623
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

                VStack(alignment: .leading, spacing: 8) {
                    Text("HTTP 服务端口")
                        .font(.system(size: 14, weight: .semibold))
                    Text("Chrome 扩展通过此端口与 Read It Later 通信")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                    TextField("端口号", value: $httpPort, format: .number)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 100)
                }

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
}
