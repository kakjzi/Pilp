import AppKit
import PilpCore

@MainActor
final class PilpAppDelegate: NSObject, NSApplicationDelegate {
    private static let hasPresentedFirstLaunchKey = "hasPresentedFirstLaunch"

    let model: ClipboardModel
    let overlayController: ClipboardOverlayController
    let commandVSettings: CommandVHoldSettings
    let shortcutSettings: ShortcutSettings
    let privacySettings: ClipboardPrivacySettings
    let launchAtLoginSettings: LaunchAtLoginSettings
    let updater: AppUpdater
    private var firstLaunchWindowController: FirstLaunchWindowController?

    override init() {
        let privacySettings = ClipboardPrivacySettings()
        let model = ClipboardModel(privacySettings: privacySettings)
        let overlayController = ClipboardOverlayController(model: model)
        let updater = AppUpdater()
        self.model = model
        self.overlayController = overlayController
        self.privacySettings = privacySettings
        self.launchAtLoginSettings = LaunchAtLoginSettings()
        self.updater = updater
        self.commandVSettings = CommandVHoldSettings {
            overlayController.show()
        }
        self.shortcutSettings = ShortcutSettings {
            overlayController.toggle()
        }
        super.init()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        if commandVSettings.isEnabled,
            !commandVSettings.isAccessibilityGranted
        {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                self.commandVSettings.requestAccessibilityPermission()
            }
        }

        if CommandLine.arguments.contains("--show-picker") {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.overlayController.show()
            }
            return
        }

        let defaults = UserDefaults.standard
        var firstLaunch = FirstLaunchPresentationState(
            hasPresented: defaults.bool(
                forKey: Self.hasPresentedFirstLaunchKey
            )
        )

        guard firstLaunch.consumePresentation() else {
            return
        }

        defaults.set(
            firstLaunch.hasPresented,
            forKey: Self.hasPresentedFirstLaunchKey
        )
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { [weak self] in
            guard let self else {
                return
            }

            let controller = FirstLaunchWindowController(
                commandVSettings: commandVSettings,
                shortcutSettings: shortcutSettings,
                privacySettings: privacySettings,
                launchAtLoginSettings: launchAtLoginSettings,
                updater: updater
            )
            firstLaunchWindowController = controller
            controller.present()
        }
    }

    func applicationDidBecomeActive(_ notification: Notification) {
        commandVSettings.refreshPermissionStatus()
        launchAtLoginSettings.refresh()
    }
}
