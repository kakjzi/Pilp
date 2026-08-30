import SwiftUI

@main
struct PilpApp: App {
    @NSApplicationDelegateAdaptor(PilpAppDelegate.self)
    private var appDelegate

    var body: some Scene {
        MenuBarExtra("Pilp", systemImage: "clipboard") {
            ClipboardMenuView(
                model: appDelegate.model,
                privacySettings: appDelegate.privacySettings,
                updater: appDelegate.updater,
                onShowPicker: appDelegate.overlayController.show
            )
        }
        .menuBarExtraStyle(.window)

        Settings {
            PilpSettingsView(
                commandVSettings: appDelegate.commandVSettings,
                shortcutSettings: appDelegate.shortcutSettings,
                privacySettings: appDelegate.privacySettings,
                launchAtLoginSettings: appDelegate.launchAtLoginSettings,
                updater: appDelegate.updater
            )
        }
    }
}
