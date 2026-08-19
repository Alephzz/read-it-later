import SwiftUI

/// Collapsed notch view — shows unread count badge
struct NotchView: View {
    private let database = DatabaseService.shared

    var body: some View {
        HStack(spacing: 8) {
            NotchShape()
                .fill(Color(red: 0.11, green: 0.11, blue: 0.12))
                .frame(width: 220, height: 36)
                .overlay(
                    HStack(spacing: 12) {
                        Image(systemName: "book.closed.fill")
                            .foregroundColor(.white.opacity(0.7))
                            .font(.system(size: 14))

                        Text("Read It Later")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))

                        UnreadBadge()
                    }
                )
        }
        .frame(width: 220, height: 36)
    }
}

struct UnreadBadge: View {
    @State private var badgeCount: Int = 0

    var body: some View {
        Group {
            if badgeCount > 0 {
                Text("\(badgeCount)")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.orange)
                    .clipShape(Capsule())
            }
        }
        .onAppear { updateCount() }
        .onReceive(NotificationCenter.default.publisher(for: .notchDidCollapse)) { _ in
            updateCount()
        }
        .onReceive(NotificationCenter.default.publisher(for: .itemsDidChange)) { _ in
            updateCount()
        }
    }

    /// 角标口径 = 待处理（未读 + 在读），表示"还有几件没读完"
    func updateCount() {
        badgeCount = DatabaseService.shared.fetchPending().count
    }
}

/// The physical notch shape
struct NotchShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let cornerRadius: CGFloat = 14
        path.addRoundedRect(in: rect, cornerSize: CGSize(width: cornerRadius, height: cornerRadius))
        return path
    }
}
