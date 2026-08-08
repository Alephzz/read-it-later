import SwiftUI

@main
struct ReadItLaterApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // No traditional window — all UI is in the notch
        Settings {
            SettingsView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    private var notchManager: NotchManager?
    private var httpServer: HTTPServerService?
    private let database = DatabaseService.shared

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Initialize database
        database.initialize()

        // Start HTTP server for Chrome extension
        httpServer = HTTPServerService()
        httpServer?.start()

        // Initialize notch window
        notchManager = NotchManager.shared
        notchManager?.setup()

        // Hide dock icon — this is a notch-only app
        NSApp.setActivationPolicy(.accessory)
    }

    func applicationWillTerminate(_ notification: Notification) {
        httpServer?.stop()
    }
}
