import AppKit
import SwiftUI

@MainActor
final class FirstLaunchWindowController: NSWindowController {
    init(
        shortcutSettings: ShortcutSettings,
        updater: AppUpdater
    ) {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 480, height: 570),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "Welcome to Pilp"
        window.isReleasedWhenClosed = false
        window.contentViewController = NSHostingController(
            rootView: PilpSettingsView(
                shortcutSettings: shortcutSettings,
                updater: updater
            )
        )
        window.center()

        super.init(window: window)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func present() {
        showWindow(nil)
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
