import SwiftUI

struct ItemRowView: View {
    let item: Item
    @AppStorage("showSummary") private var showSummary: Bool = true

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
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
            }

            Spacer()

            // Status indicator
            statusIndicator
                .padding(.top, 2)
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
    private var statusIndicator: some View {
        switch item.status {
        case .done:
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green.opacity(0.6))
                .font(.system(size: 12))
        case .reading:
            Image(systemName: "book.fill")
                .foregroundColor(.blue.opacity(0.6))
                .font(.system(size: 12))
        case .unread:
            stalenessDot
        }
    }

    private var stalenessDot: some View {
        Circle()
            .fill(stalenessColor)
            .frame(width: 6, height: 6)
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
