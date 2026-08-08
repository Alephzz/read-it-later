import SwiftUI

struct ExpandedView: View {
    let manager: NotchManager
    @ObservedObject var store: ItemStore
    @State private var searchText = ""
    @State private var selectedDomain: String? = nil
    @State private var showingAddSheet = false
    @State private var selectedDetailItem: Item? = nil

    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView

            Divider().background(Color.white.opacity(0.1))

            // Content
            if filteredItems.isEmpty {
                emptyView
            } else {
                if selectedDomain == nil {
                    domainGroupedView
                } else {
                    flatListView
                }
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
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        domainPill(label: "全部", count: filteredItems.count, isSelected: selectedDomain == nil)
                        ForEach(sortedDomains, id: \.self) { domain in
                            domainPill(label: domain, count: grouped[domain]?.count ?? 0, isSelected: false) {
                                selectedDomain = domain
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                }

                ForEach(filteredItems) { item in
                    ItemRowView(item: item)
                        .onTapGesture {
                            if let url = item.url, let link = URL(string: url) {
                                NSWorkspace.shared.open(link)
                                if item.status == .unread {
                                    store.updateStatus(id: item.id, status: .reading)
                                }
                            }
                        }
                        .contextMenu {
                            Button("标记为已读") {
                                store.updateStatus(id: item.id, status: .done)
                            }
                            Button("标记为在读") {
                                store.updateStatus(id: item.id, status: .reading)
                            }
                            Button("查看详情") {
                                selectedDetailItem = item
                            }
                            Divider()
                            Button("删除", role: .destructive) {
                                store.delete(id: item.id)
                            }
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
                        ItemRowView(item: item)
                            .onTapGesture {
                                if let url = item.url, let link = URL(string: url) {
                                    NSWorkspace.shared.open(link)
                                    if item.status == .unread {
                                        store.updateStatus(id: item.id, status: .reading)
                                    }
                                }
                            }
                            .contextMenu {
                                Button("标记为已读") {
                                    store.updateStatus(id: item.id, status: .done)
                                }
                                Button("标记为在读") {
                                    store.updateStatus(id: item.id, status: .reading)
                                }
                                Button("查看详情") {
                                    selectedDetailItem = item
                                }
                                Divider()
                                Button("删除", role: .destructive) {
                                    store.delete(id: item.id)
                                }
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
            Text("还没有保存任何链接")
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.4))
            Text("按 ⌘+Shift+R 或点击 + 添加")
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.25))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Helpers

    private func domainPill(label: String, count: Int, isSelected: Bool, action: (() -> Void)? = nil) -> some View {
        Button(action: { action?() }) {
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

    private var filteredItems: [Item] {
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
