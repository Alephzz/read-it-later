import SwiftUI

/// 快速编辑标签的弹窗（从列表右键"编辑标签"进入）
struct TagEditView: View {
    let item: Item
    @ObservedObject var store: ItemStore
    @Environment(\.dismiss) var dismiss
    @State private var editedTags: String

    init(item: Item, store: ItemStore) {
        self.item = item
        self.store = store
        _editedTags = State(initialValue: item.tags.joined(separator: ", "))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Text("编辑标签")
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

            // 标题
            Text(item.title)
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.8))
                .lineLimit(2)

            // 标签输入
            VStack(alignment: .leading, spacing: 4) {
                Text("标签（逗号或中文逗号分隔）")
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.4))
                TextField("标签1, 标签2", text: $editedTags)
                    .textFieldStyle(.plain)
                    .foregroundColor(.white)
                    .font(.system(size: 13))
                    .padding(8)
                    .background(Color.white.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            }

            // 常用标签快捷选择
            if !suggestedTags.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("常用标签")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.4))
                    FlowTags(tags: suggestedTags, selected: currentTags) { tag in
                        toggleSuggestion(tag)
                    }
                }
            }

            Spacer()

            // Actions
            HStack(spacing: 12) {
                Spacer()
                Button("取消") { dismiss() }
                    .buttonStyle(.plain)
                    .foregroundColor(.white.opacity(0.5))
                    .font(.system(size: 12))

                Button("保存") {
                    var updated = item
                    updated.tags = TagParser.parse(editedTags)
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
        .frame(width: 420, height: 300)
        .background(Color(red: 0.13, green: 0.13, blue: 0.15))
    }

    /// 当前已解析的标签（用于高亮常用标签）
    private var currentTags: Set<String> {
        Set(TagParser.parse(editedTags))
    }

    /// 常用标签：从库中所有条目的标签里收集（去掉当前已选的）
    private var suggestedTags: [String] {
        let all = Set(DatabaseService.shared.fetchAll().flatMap { $0.tags })
        let existing = currentTags
        return all.filter { !existing.contains($0) }.sorted()
    }

    private func toggleSuggestion(_ tag: String) {
        var tags = TagParser.parse(editedTags)
        if tags.contains(tag) {
            tags.removeAll { $0 == tag }
        } else {
            tags.append(tag)
        }
        editedTags = tags.joined(separator: ", ")
    }
}

/// 流式排布的标签胶囊（自动换行），用于"常用标签"快捷选择
private struct FlowTags: View {
    let tags: [String]
    let selected: Set<String>
    let onTap: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(wrappedRows, id: \.self) { row in
                HStack(spacing: 6) {
                    ForEach(row, id: \.self) { tag in
                        tagChip(tag)
                    }
                }
            }
        }
    }

    private func tagChip(_ tag: String) -> some View {
        Button(action: { onTap(tag) }) {
            Text("#\(tag)")
                .font(.system(size: 11))
                .foregroundColor(selected.contains(tag) ? .white : .orange.opacity(0.8))
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(selected.contains(tag) ? Color.orange : Color.white.opacity(0.08))
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    /// 简单按顺序分组换行（宽度足够则不换行）
    private var wrappedRows: [[String]] {
        let maxWidth: CGFloat = 380
        var rows: [[String]] = []
        var current: [String] = []
        var currentWidth: CGFloat = 0
        for tag in tags {
            let w = CGFloat(tag.count * 14 + 20)
            if currentWidth + w > maxWidth, !current.isEmpty {
                rows.append(current)
                current = [tag]
                currentWidth = w
            } else {
                current.append(tag)
                currentWidth += w + 6
            }
        }
        if !current.isEmpty { rows.append(current) }
        return rows
    }
}
