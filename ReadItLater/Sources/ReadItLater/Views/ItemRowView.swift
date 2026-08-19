import SwiftUI

struct ItemRowView: View {
    let item: Item
    var onToggleDone: (() -> Void)? = nil
    @AppStorage("showSummary") private var showSummary: Bool = true

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            // 一键标记已读 / 恢复未读（同时作为状态指示器）
            Button(action: { onToggleDone?() }) {
                statusIcon
                    .font(.system(size: 13))
                    .frame(width: 22, height: 22)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .help(item.status == .done ? "恢复为未读" : "标记为已读")

            // Favicon or domain icon
            faviconView
                .padding(.top, 2)

            // Title, summary, and domain
            VStack(alignment: .leading, spacing: 3) {
                Text(item.title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(titleColor)
                    .lineLimit(1)

                // Summary preview (only if enabled)
                if showSummary, let summary = item.summary, !summary.isEmpty {
                    Text(summary)
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.35))
                        .lineLimit(2)
                }

                HStack(spacing: 6) {
                    Text(item.domain)
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.25))

                    if let dateStr = relativeDate {
                        Text("·")
                            .foregroundColor(.white.opacity(0.15))
                        Text(dateStr)
                            .font(.system(size: 10))
                            .foregroundColor(.white.opacity(0.2))
                    }
                }

                // 标签
                if !item.tags.isEmpty {
                    HStack(spacing: 4) {
                        ForEach(item.tags, id: \.self) { tag in
                            Text("#\(tag)")
                                .font(.system(size: 9))
                                .foregroundColor(.orange.opacity(0.8))
                        }
                    }
                }
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(hoverColor)
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }

    // MARK: - Favicon

    @ViewBuilder
    private var faviconView: some View {
        if let faviconData = item.faviconData,
           let nsImage = NSImage(data: faviconData) {
            Image(nsImage: nsImage)
                .resizable()
                .frame(width: 16, height: 16)
                .clipShape(RoundedRectangle(cornerRadius: 3))
        } else {
            Image(systemName: "globe")
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.3))
                .frame(width: 16, height: 16)
        }
    }

    // MARK: - Status

    @ViewBuilder
    private var statusIcon: some View {
        switch item.status {
        case .done:
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green.opacity(0.6))
        case .reading:
            Image(systemName: "circle.inset.filled")
                .foregroundColor(.blue.opacity(0.6))
        case .unread:
            // 圆圈描边颜色 = 陈旧程度（绿=新鲜 / 黄=渐旧 / 红=陈旧）
            Image(systemName: "circle")
                .foregroundColor(stalenessColor)
        }
    }

    private var stalenessColor: Color {
        switch item.staleness {
        case .fresh: return .green
        case .aging: return .yellow
        case .stale: return .red
        }
    }

    // MARK: - Helpers

    private var titleColor: Color {
        switch item.status {
        case .done: .white.opacity(0.4)
        default: .white.opacity(0.9)
        }
    }

    private var hoverColor: Color {
        .white.opacity(0.03)
    }

    private var relativeDate: String? {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.localizedString(for: item.createdAt, relativeTo: Date())
    }
}
