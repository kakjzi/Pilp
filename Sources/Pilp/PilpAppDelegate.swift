import AppKit

@MainActor
final class PilpAppDelegate: NSObject, NSApplicationDelegate {
    let model: ClipboardModel
    let overlayController: ClipboardOverlayController
    let shortcutSettings: ShortcutSettings

    override init() {
        let model = ClipboardModel()
        let overlayController = ClipboardOverlayController(model: model)
        self.model = model
        self.overlayController = overlayController
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
        }
    }
}
