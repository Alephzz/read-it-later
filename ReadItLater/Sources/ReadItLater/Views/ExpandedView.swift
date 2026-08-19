import SwiftUI

/// 列表状态过滤：待处理 = 未读 + 在读，已读 = 归档
private enum StatusFilter {
    case active
    case done

    var label: String {
        switch self {
        case .active: return "待处理"
        case .done: return "已读"
        }
    }
}

/// 撤销提示：标记为已读后短暂出现，可一键回滚到原状态
private struct UndoState: Equatable {
    let itemId: UUID
    let previousStatus: ItemStatus
    let message: String
}

struct ExpandedView: View {
    let manager: NotchManager
    @ObservedObject var store: ItemStore
    @State private var searchText = ""
    @State private var selectedDomain: String? = nil
    @State private var showingAddSheet = false
    @State private var selectedDetailItem: Item? = nil
    @State private var statusFilter: StatusFilter = .active
    @State private var selectedTags: Set<String> = []
    @State private var undoState: UndoState?
    @State private var tagEditingItem: Item? = nil
    @State private var tagEditText: String = ""

    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView

            Divider().background(Color.white.opacity(0.1))

            // Content
            if selectedDomain == nil {
                if filteredItems.isEmpty {
                    emptyView
                } else {
                    domainGroupedView
                }
            } else {
                flatListView
            }
        }
        .frame(width: 680, height: 420)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(red: 0.13, green: 0.13, blue: 0.15))
                .shadow(color: .black.opacity(0.5), radius: 20, y: 10)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .onAppear { store.refresh() }
        .onReceive(NotificationCenter.default.publisher(for: .notchDidExpand)) { _ in
            store.refresh()
        }
        .onReceive(NotificationCenter.default.publisher(for: .itemsDidChange)) { _ in
            store.refresh()
        }
        .sheet(isPresented: $showingAddSheet) {
            AddItemView(store: store)
        }
        .onChange(of: showingAddSheet) { newValue in
            manager.setSheetActive(newValue)
        }
        .sheet(item: $selectedDetailItem) { item in
            DetailView(item: item, store: store)
        }
        .onChange(of: selectedDetailItem) { newValue in
            manager.setSheetActive(newValue != nil)
        }
        .sheet(item: $tagEditingItem) { item in
            TagEditView(item: item, store: store)
        }
        .onChange(of: tagEditingItem) { newValue in
            manager.setSheetActive(newValue != nil)
        }
        .onChange(of: filteredItems) { newItems in
            // 当前域名下没有条目时自动返回分组视图（例如最后一个已读归档后）
            if let domain = selectedDomain, !newItems.contains(where: { $0.domain == domain }) {
                selectedDomain = nil
            }
        }
        .overlay(alignment: .bottom) {
            if let undo = undoState {
                undoToast(undo)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .padding(.bottom, 10)
            }
        }
        .task(id: undoState) {
            guard undoState != nil else { return }
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            withAnimation(.easeOut(duration: 0.2)) { undoState = nil }
        }
    }

    // MARK: - Header

    private var headerView: some View {
        HStack(spacing: 12) {
            Image(systemName: "book.closed.fill")
                .foregroundColor(.orange)
                .font(.system(size: 16))

            Text("Read It Later")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)

            Spacer()

            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.white.opacity(0.4))
                    .font(.system(size: 12))
                TextField("搜索...", text: $searchText)
                    .textFieldStyle(.plain)
                    .foregroundColor(.white)
                    .font(.system(size: 12))
                    .frame(width: 140)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.white.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 6))

            Button(action: { showingAddSheet = true }) {
                Image(systemName: "plus")
                    .foregroundColor(.white)
                    .font(.system(size: 14, weight: .medium))
                    .padding(6)
                    .background(Color.orange)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            }
            .buttonStyle(.plain)

            Button(action: openSettings) {
                Image(systemName: "gearshape")
                    .foregroundColor(.white.opacity(0.6))
                    .font(.system(size: 13))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    // MARK: - Domain Grouped View

    private var domainGroupedView: some View {
        let grouped = Dictionary(grouping: filteredItems, by: { $0.domain })
        let sortedDomains = grouped.keys.sorted()

        return ScrollView {
            LazyVStack(spacing: 8) {
                // 状态过滤：待处理 / 已读（归档）
                HStack(spacing: 6) {
                    pillButton(label: StatusFilter.active.label, count: activeCount, isSelected: statusFilter == .active) {
                        statusFilter = .active
                    }
                    pillButton(label: StatusFilter.done.label, count: doneCount, isSelected: statusFilter == .done) {
                        statusFilter = .done
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 10)

                // 域名过滤
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        pillButton(label: "全部", count: filteredItems.count, isSelected: selectedDomain == nil) {
                            selectedDomain = nil
                        }
                        ForEach(sortedDomains, id: \.self) { domain in
                            pillButton(label: domain, count: grouped[domain]?.count ?? 0, isSelected: false) {
                                selectedDomain = domain
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                }

                // 标签过滤（仅当有标签时显示）
                if !allTags.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            pillButton(label: "全部标签", count: tagFilteredCount(selected: nil), isSelected: selectedTags.isEmpty) {
                                selectedTags = []
                            }
                            ForEach(allTags, id: \.self) { tag in
                                pillButton(label: tag, count: tagFilteredCount(selected: tag), isSelected: selectedTags.contains(tag)) {
                                    toggleTag(tag)
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                    }
                }

                ForEach(filteredItems) { item in
                    ItemRowView(item: item, onToggleDone: { toggleDone(item) })
                        .onTapGesture {
                            openItem(item)
                        }
                        .contextMenu {
                            itemContextMenu(item)
                        }
                }
            }
            .padding(.vertical, 8)
        }
    }

    // MARK: - Flat List View (single domain)

    private var flatListView: some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: { selectedDomain = nil }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("返回")
                    }
                    .foregroundColor(.orange)
                    .font(.system(size: 12))
                }
                .buttonStyle(.plain)

                Spacer()

                Text(selectedDomain ?? "")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)

            ScrollView {
                LazyVStack(spacing: 4) {
                    ForEach(filteredItems.filter { $0.domain == selectedDomain }) { item in
                        ItemRowView(item: item, onToggleDone: { toggleDone(item) })
                            .onTapGesture {
                                openItem(item)
                            }
                            .contextMenu {
                                itemContextMenu(item)
                            }
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }

    // MARK: - Empty State

    private var emptyView: some View {
        VStack(spacing: 12) {
            Image(systemName: "tray")
                .font(.system(size: 32))
                .foregroundColor(.white.opacity(0.2))
            Text(emptyText)
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.4))
            Text("按 ⌘+Shift+R 或点击 + 添加")
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.25))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Helpers

    private var searchFiltered: [Item] {
        var result = store.items
        if !searchText.isEmpty {
            result = result.filter {
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                ($0.url?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                $0.domain.localizedCaseInsensitiveContains(searchText)
            }
        }
        return result
    }

    private var filteredItems: [Item] {
        var result = searchFiltered
        if !selectedTags.isEmpty {
            result = result.filter { item in
                !selectedTags.isDisjoint(with: item.tags)
            }
        }
        switch statusFilter {
        case .active: return result.filter { $0.status != .done }
        case .done: return result.filter { $0.status == .done }
        }
    }

    private var activeCount: Int { searchFiltered.filter { $0.status != .done }.count }
    private var doneCount: Int { searchFiltered.filter { $0.status == .done }.count }

    /// 全部标签（去重、排序，来自待处理+已读的所有条目）
    private var allTags: [String] {
        let tags = Set(store.items.flatMap { $0.tags })
        return tags.sorted()
    }

    private func toggleTag(_ tag: String) {
        if selectedTags.contains(tag) {
            selectedTags.remove(tag)
        } else {
            selectedTags.insert(tag)
        }
        statusFilter = .active
    }

    /// 某个标签（或全部标签）在当前状态+搜索+域名条件下对应的条目数
    private func tagFilteredCount(selected: String?) -> Int {
        let base = searchFiltered
        let tag = selected
        switch statusFilter {
        case .active: return base.filter { $0.status != .done && (tag == nil || $0.tags.contains(tag!)) }.count
        case .done: return base.filter { $0.status == .done && (tag == nil || $0.tags.contains(tag!)) }.count
        }
    }

    private var emptyText: String {
        statusFilter == .active ? "还没有保存任何链接" : "还没有已读的链接"
    }

    private func pillButton(label: String, count: Int, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Text(label)
                Text("\(count)")
                    .font(.system(size: 9))
                    .foregroundColor(isSelected ? .white.opacity(0.7) : .white.opacity(0.4))
            }
            .font(.system(size: 11, weight: isSelected ? .medium : .regular))
            .foregroundColor(isSelected ? .white : .white.opacity(0.6))
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(isSelected ? Color.orange : Color.white.opacity(0.08))
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private func openItem(_ item: Item) {
        if let url = item.url, let link = URL(string: url) {
            NSWorkspace.shared.open(link)
            if item.status == .unread {
                store.updateStatus(id: item.id, status: .reading)
            }
        }
    }

    /// 行内圆圈按钮：已读 ↔ 未读 切换
    private func toggleDone(_ item: Item) {
        if item.status == .done {
            store.updateStatus(id: item.id, status: .unread)
        } else {
            markAsDone(item)
        }
    }

    /// 标记为已读，并弹出可撤销的提示
    private func markAsDone(_ item: Item) {
        store.updateStatus(id: item.id, status: .done)
        withAnimation(.spring(response: 0.35)) {
            undoState = UndoState(itemId: item.id, previousStatus: item.status, message: "已标为已读")
        }
    }

    private func undoToast(_ undo: UndoState) -> some View {
        HStack(spacing: 10) {
            Text(undo.message)
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.9))
            Button("撤销") {
                store.updateStatus(id: undo.itemId, status: undo.previousStatus)
                withAnimation(.easeOut(duration: 0.2)) { undoState = nil }
            }
            .buttonStyle(.plain)
            .foregroundColor(.orange)
            .font(.system(size: 12, weight: .semibold))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 9)
        .background(Color(red: 0.07, green: 0.07, blue: 0.08).opacity(0.92))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .shadow(color: .black.opacity(0.4), radius: 8, y: 3)
    }

    @ViewBuilder
    private func itemContextMenu(_ item: Item) -> some View {
        if item.status == .done {
            Button("恢复为未读") {
                store.updateStatus(id: item.id, status: .unread)
            }
        } else {
            Button("标记为已读") {
                markAsDone(item)
            }
            Button("标记为在读") {
                store.updateStatus(id: item.id, status: .reading)
            }
        }
        Button("编辑标签") {
            tagEditingItem = item
        }
        Button("查看详情") {
            selectedDetailItem = item
        }
        Divider()
        Button("删除", role: .destructive) {
            store.delete(id: item.id)
        }
    }

    private func openSettings() {
        let settingsWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 480),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
        settingsWindow.title = "Read It Later 设置"
        settingsWindow.center()
        settingsWindow.isReleasedWhenClosed = false
        settingsWindow.contentView = NSHostingView(rootView: SettingsView())
        settingsWindow.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
