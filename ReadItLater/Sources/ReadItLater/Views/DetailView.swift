import SwiftUI

struct DetailView: View {
    let item: Item
    @ObservedObject var store: ItemStore
    @Environment(\.dismiss) var dismiss
    @State private var editedTitle: String = ""
    @State private var editedTags: String = ""
    @State private var currentStatus: ItemStatus
    private let database = DatabaseService.shared

    init(item: Item, store: ItemStore) {
        self.item = item
        self.store = store
        _editedTitle = State(initialValue: item.title)
        _editedTags = State(initialValue: item.tags.joined(separator: ", "))
        _currentStatus = State(initialValue: item.status)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Text("详情")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .foregroundColor(.white.opacity(0.5))
                        .font(.system(size: 14))
                }
                .buttonStyle(.plain)
            }

            Divider().background(Color.white.opacity(0.1))

            // Status toggle buttons
            HStack(spacing: 8) {
                statusButton(label: "未读", icon: "circle", status: .unread, color: .green)
                statusButton(label: "在读", icon: "book", status: .reading, color: .blue)
                statusButton(label: "已读", icon: "checkmark.circle", status: .done, color: .gray)
            }

            // Title
            VStack(alignment: .leading, spacing: 4) {
                Text("标题")
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.4))
                TextField("标题", text: $editedTitle)
                    .textFieldStyle(.plain)
                    .foregroundColor(.white)
                    .font(.system(size: 13))
                    .padding(8)
                    .background(Color.white.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            }

            // URL
            if let url = item.url {
                VStack(alignment: .leading, spacing: 4) {
                    Text("链接")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.4))
                    HStack {
                        Text(url)
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(.orange.opacity(0.8))
                            .lineLimit(2)
                        Spacer()
                        Button("打开") {
                            if let link = URL(string: url) {
                                NSWorkspace.shared.open(link)
                            }
                        }
                        .buttonStyle(.plain)
                        .font(.system(size: 11))
                        .foregroundColor(.orange)
                    }
                    .padding(8)
                    .background(Color.white.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                }
            }

            // Summary
            if let summary = item.summary {
                VStack(alignment: .leading, spacing: 4) {
                    Text("摘要")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.4))
                    Text(summary)
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.7))
                        .padding(8)
                        .background(Color.white.opacity(0.06))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
            }

            // Tags
            VStack(alignment: .leading, spacing: 4) {
                Text("标签（逗号分隔）")
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.4))
                TextField("标签1, 标签2", text: $editedTags)
                    .textFieldStyle(.plain)
                    .foregroundColor(.white)
                    .font(.system(size: 12))
                    .padding(8)
                    .background(Color.white.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            }

            // Info
            HStack(spacing: 16) {
                Label(item.domain, systemImage: "globe")
            }
            .font(.system(size: 10))
            .foregroundColor(.white.opacity(0.35))

            Spacer()

            // Actions
            HStack(spacing: 12) {
                Button("删除") {
                    store.delete(id: item.id)
                    dismiss()
                }
                .buttonStyle(.plain)
                .foregroundColor(.red.opacity(0.7))
                .font(.system(size: 12))

                Spacer()

                Button("取消") { dismiss() }
                    .buttonStyle(.plain)
                    .foregroundColor(.white.opacity(0.5))
                    .font(.system(size: 12))

                Button("保存") {
                    var updated = item
                    updated.title = editedTitle
                    updated.tags = TagParser.parse(editedTags)
                    updated.status = currentStatus  // Include current status
                    store.update(updated)
                    dismiss()
                }
                .buttonStyle(.plain)
                .foregroundColor(.white)
                .font(.system(size: 12, weight: .medium))
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
                .background(Color.orange)
                .clipShape(RoundedRectangle(cornerRadius: 6))
            }
        }
        .padding(20)
        .frame(width: 440, height: 520)
        .background(Color(red: 0.13, green: 0.13, blue: 0.15))
    }

    // MARK: - Status Button

    private func statusButton(label: String, icon: String, status: ItemStatus, color: Color) -> some View {
        let isSelected = currentStatus == status
        return Button(action: {
            currentStatus = status
            store.updateStatus(id: item.id, status: status)
        }) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                Text(label)
            }
            .font(.system(size: 11, weight: isSelected ? .medium : .regular))
            .foregroundColor(isSelected ? .white : .white.opacity(0.5))
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(isSelected ? color.opacity(0.6) : Color.white.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 6))
        }
        .buttonStyle(.plain)
    }
}
