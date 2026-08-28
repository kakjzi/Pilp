import ApplicationServices
import Combine
import Foundation

@MainActor
final class CommandVHoldSettings: ObservableObject {
    @Published var isEnabled: Bool {
        didSet {
            guard isEnabled != oldValue else {
                return
            }

            defaults.set(isEnabled, forKey: Self.storageKey)
            refreshPermissionStatus()
        }
    }

    @Published private(set) var isAccessibilityGranted = false
    @Published private(set) var activationError: String?

    private static let storageKey = "pilp.commandVHoldEnabled"

    private let defaults: UserDefaults
    private let monitor: CommandVHoldMonitor

    init(
        defaults: UserDefaults = .standard,
        onLongPress: @escaping () -> Void
    ) {
        self.defaults = defaults
        self.monitor = CommandVHoldMonitor(onLongPress: onLongPress)
        self.isEnabled = defaults.object(forKey: Self.storageKey) == nil
            ? true
            : defaults.bool(forKey: Self.storageKey)

        refreshPermissionStatus()
    }

    func requestAccessibilityPermission() {
        guard isEnabled else {
            return
        }

        let options = [
            "AXTrustedCheckOptionPrompt": true
        ] as CFDictionary
        isAccessibilityGranted = AXIsProcessTrustedWithOptions(options)
        updateMonitor()
    }

    func refreshPermissionStatus() {
        isAccessibilityGranted = AXIsProcessTrusted()
        updateMonitor()
    }

    private func updateMonitor() {
        guard isEnabled, isAccessibilityGranted else {
            monitor.stop()
            activationError = nil
            return
        }

        activationError = monitor.start()
            ? nil
            : L10n.text("command_v.activation_error")
    }
}
