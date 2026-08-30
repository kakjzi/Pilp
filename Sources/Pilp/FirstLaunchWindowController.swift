import AppKit
import SwiftUI

@MainActor
final class FirstLaunchWindowController: NSWindowController {
    init(
        commandVSettings: CommandVHoldSettings,
        shortcutSettings: ShortcutSettings,
        privacySettings: ClipboardPrivacySettings,
        launchAtLoginSettings: LaunchAtLoginSettings,
        updater: AppUpdater
    ) {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 560, height: 760),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = L10n.text("welcome.title")
        window.isReleasedWhenClosed = false
        window.contentViewController = NSHostingController(
            rootView: PilpSettingsView(
                commandVSettings: commandVSettings,
                shortcutSettings: shortcutSettings,
                privacySettings: privacySettings,
                launchAtLoginSettings: launchAtLoginSettings,
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
