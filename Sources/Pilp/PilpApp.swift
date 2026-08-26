import SwiftUI

@main
struct PilpApp: App {
    @NSApplicationDelegateAdaptor(PilpAppDelegate.self)
    private var appDelegate

    var body: some Scene {
        MenuBarExtra("Pilp", systemImage: "clipboard") {
            ClipboardMenuView(
                model: appDelegate.model,
                onShowPicker: appDelegate.overlayController.show
            )
        }
        .menuBarExtraStyle(.window)

        Settings {
            PilpSettingsView(
                shortcutSettings: appDelegate.shortcutSettings
            )
        }
    }
}
