import SwiftUI
import AppKit
import Carbon.HIToolbox

final class NotchManager {
    static let shared = NotchManager()

    private var notchWindow: NotchPanel?
    private var isExpanded = false
    private var hotKeyRef: EventHotKeyRef?
    private(set) var sheetIsActive = false
    private var sheetDismissedAt: Date?

    // Collapsed: match physical notch width (~200px)
    private let collapsedWidth: CGFloat = 220
    private let collapsedHeight: CGFloat = 36
    // Expanded: wider panel
    private let expandedWidth: CGFloat = 680
    private let expandedHeight: CGFloat = 420
    // Mouse trigger area: slightly larger than collapsed notch
    private let triggerPadding: CGFloat = 10

    private init() {}

    func setup() {
        createWindow()
        registerHotKey()
        startMouseTracking()
    }

    func toggle() {
        if isExpanded {
            collapse()
        } else {
            expand()
        }
    }

    func expand() {
        guard let window = notchWindow, !isExpanded else { return }
        isExpanded = true
        let frame = notchFrame(width: expandedWidth, height: expandedHeight)
        window.animator().setFrame(frame, display: true)
        window.orderFrontRegardless()
        NotificationCenter.default.post(name: .notchDidExpand, object: nil)
    }

    func collapse() {
        // Don't collapse if a sheet (detail/add) is active
        guard !sheetIsActive else { return }
        guard let window = notchWindow, isExpanded else { return }
        isExpanded = false
        let frame = notchFrame(width: collapsedWidth, height: collapsedHeight)
        window.animator().setFrame(frame, display: true)
        NotificationCenter.default.post(name: .notchDidCollapse, object: nil)
    }

    func setSheetActive(_ active: Bool) {
        sheetIsActive = active
        if !active {
            // Sheet just closed — delay collapse to let user read
            sheetDismissedAt = Date()
        }
    }

    var expanded: Bool { isExpanded }

    // MARK: - Window

    private func createWindow() {
        let frame = notchFrame(width: collapsedWidth, height: collapsedHeight)
        let panel = NotchPanel(
            contentRect: frame,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.level = .screenSaver
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.isMovableByWindowBackground = false
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.ignoresMouseEvents = false

        let contentView = NotchContainerView(manager: self)
        panel.contentView = NSHostingView(rootView: contentView)
        panel.orderFrontRegardless()

        self.notchWindow = panel
    }

    private func notchFrame(width: CGFloat, height: CGFloat) -> NSRect {
        guard let screen = NSScreen.main else {
            return NSRect(x: 0, y: 0, width: width, height: height)
        }
        let screenFrame = screen.frame
        let topY = screenFrame.maxY
        let x = screenFrame.midX - width / 2
        return NSRect(x: x, y: topY - height, width: width, height: height)
    }

    // MARK: - HotKey (Carbon API)

    private func registerHotKey() {
        // ⌘⇧R = Command + Shift + R
        var hotKeyID = EventHotKeyID()
        hotKeyID.signature = OSType(0x5249544C) // "RITL"
        hotKeyID.id = 1

        var gMyHotKeyRef: EventHotKeyRef?
        let status = RegisterEventHotKey(
            UInt32(kVK_ANSI_R),
            UInt32(cmdKey | shiftKey),
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &gMyHotKeyRef
        )

        if status == noErr {
            hotKeyRef = gMyHotKeyRef
        }

        // Install event handler
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        InstallEventHandler(
            GetApplicationEventTarget(),
            { (_, event, _) -> OSStatus in
                NotchManager.shared.toggle()
                return noErr
            },
            1,
            &eventType,
            nil,
            nil
        )
    }

    // MARK: - Mouse Tracking

    private func startMouseTracking() {
        Timer.scheduledTimer(withTimeInterval: 0.15, repeats: true) { [weak self] _ in
            self?.checkMousePosition()
        }
    }

    private func checkMousePosition() {
        guard let screen = NSScreen.main else { return }
        let mouseLocation = NSEvent.mouseLocation
        let screenFrame = screen.frame

        // Trigger area: only over the physical notch (collapsed size + small padding)
        let triggerWidth = collapsedWidth + triggerPadding * 2
        let triggerArea = NSRect(
            x: screenFrame.midX - triggerWidth / 2,
            y: screenFrame.maxY - collapsedHeight - triggerPadding,
            width: triggerWidth,
            height: collapsedHeight + triggerPadding * 2
        )

        if triggerArea.contains(mouseLocation) {
            if !isExpanded { expand() }
        } else if isExpanded {
            // Don't collapse if a sheet is active
            guard !sheetIsActive else { return }

            // Don't collapse for 2 seconds after a sheet was dismissed
            if let dismissedAt = sheetDismissedAt {
                if Date().timeIntervalSince(dismissedAt) < 2.0 {
                    return
                }
                sheetDismissedAt = nil
            }

            // Only collapse if mouse is outside the expanded window
            guard let windowFrame = notchWindow?.frame else { return }
            if !windowFrame.contains(mouseLocation) {
                // Add a small delay area below the notch panel
                let belowPanel = NSRect(
                    x: windowFrame.minX,
                    y: windowFrame.minY - 20,
                    width: windowFrame.width,
                    height: windowFrame.height + 20
                )
                if !belowPanel.contains(mouseLocation) {
                    collapse()
                }
            }
        }
    }
}

// MARK: - Custom Panel

class NotchPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

// MARK: - Notifications

extension Notification.Name {
    static let notchDidExpand = Notification.Name("notchDidExpand")
    static let notchDidCollapse = Notification.Name("notchDidCollapse")
    /// 条目变化（新增/保存成功），用于角标等实时刷新
    static let itemsDidChange = Notification.Name("itemsDidChange")
}

// MARK: - Container View

struct NotchContainerView: View {
    let manager: NotchManager
    @StateObject private var store = ItemStore()
    @State private var isExpanded = false

    var body: some View {
        Group {
            if isExpanded {
                ExpandedView(manager: manager, store: store)
            } else {
                NotchView()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .notchDidExpand)) { _ in
            withAnimation(.easeInOut(duration: 0.25)) { isExpanded = true }
        }
        .onReceive(NotificationCenter.default.publisher(for: .notchDidCollapse)) { _ in
            withAnimation(.easeInOut(duration: 0.2)) { isExpanded = false }
        }
    }
}
