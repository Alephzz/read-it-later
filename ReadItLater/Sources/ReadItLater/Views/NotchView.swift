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
    @State private var unreadCount: Int = 0

    var body: some View {
        if unreadCount > 0 {
            Text("\(unreadCount)")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.white)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.orange)
                .clipShape(Capsule())
        }
    }

    func updateCount() {
        unreadCount = DatabaseService.shared.fetchUnread().count
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
