import AppKit
import PilpCore

@MainActor
final class PilpAppDelegate: NSObject, NSApplicationDelegate {
    private static let hasPresentedFirstLaunchKey = "hasPresentedFirstLaunch"

    let model: ClipboardModel
    let overlayController: ClipboardOverlayController
    let shortcutSettings: ShortcutSettings
    let updater: AppUpdater
    private var firstLaunchWindowController: FirstLaunchWindowController?

    override init() {
        let model = ClipboardModel()
        let overlayController = ClipboardOverlayController(model: model)
        let updater = AppUpdater()
        self.model = model
        self.overlayController = overlayController
        self.updater = updater
        self.shortcutSettings = ShortcutSettings {
            overlayController.toggle()
        }
        super.init()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
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
                shortcutSettings: shortcutSettings,
                updater: updater
            )
            firstLaunchWindowController = controller
            controller.present()
        }
    }
}
