import AppKit
import ApplicationServices
import Combine
import Foundation
import PilpCore

@MainActor
final class CommandVHoldSettings: ObservableObject {
    @Published var isEnabled: Bool {
        didSet {
            guard isEnabled != oldValue else {
                return
            }

            defaults.set(isEnabled, forKey: Self.storageKey)
            apply(activationState.setEnabled(isEnabled))
            updatePermissionPolling()
        }
    }

    @Published private(set) var isAccessibilityGranted = false
    @Published private(set) var activationError: String?

    private static let storageKey = "pilp.commandVHoldEnabled"
    private static let permissionPollInterval: Duration = .seconds(1)

    private let defaults: UserDefaults
    private let monitor: CommandVHoldMonitor
    private var activationState: CommandVActivationState
    private var permissionPollTask: Task<Void, Never>?

    init(
        defaults: UserDefaults = .standard,
        onLongPress: @escaping () -> Void
    ) {
        self.defaults = defaults
        self.monitor = CommandVHoldMonitor(onLongPress: onLongPress)
        let isEnabled = defaults.object(forKey: Self.storageKey) == nil
            ? true
            : defaults.bool(forKey: Self.storageKey)
        let isPermissionGranted = AXIsProcessTrusted()
        self.isEnabled = isEnabled
        self.isAccessibilityGranted = isPermissionGranted
        self.activationState = CommandVActivationState(
            isEnabled: isEnabled,
            isPermissionGranted: isPermissionGranted
        )

        apply(activationState.action)
        updatePermissionPolling()
    }

    deinit {
        permissionPollTask?.cancel()
    }

    func requestAccessibilityPermission() {
        guard isEnabled else {
            return
        }

        let options = [
            "AXTrustedCheckOptionPrompt": true
        ] as CFDictionary
        let isGranted = AXIsProcessTrustedWithOptions(options)
        refreshPermissionStatus(isGranted: isGranted)
    }

    func openAccessibilitySettings() {
        guard let url = URL(
            string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
        ) else {
            return
        }

        NSWorkspace.shared.open(url)
    }

    func refreshPermissionStatus() {
        refreshPermissionStatus(isGranted: AXIsProcessTrusted())
    }

    private func refreshPermissionStatus(isGranted: Bool) {
        isAccessibilityGranted = isGranted
        apply(activationState.refreshPermission(isGranted: isGranted))
        updatePermissionPolling()
    }

    private func apply(_ action: CommandVActivationState.Action) {
        switch action {
        case .disabled, .waitForPermission, .stopMonitoring:
            monitor.stop()
            activationError = nil

        case .startMonitoring:
            let didStart = monitor.start()
            activationState.monitoringDidStart(succeeded: didStart)
            activationError = didStart
                ? nil
                : L10n.text("command_v.activation_error")

        case .monitoring:
            break
        }
    }

    private func updatePermissionPolling() {
        guard isEnabled else {
            permissionPollTask?.cancel()
            permissionPollTask = nil
            return
        }

        guard permissionPollTask == nil else {
            return
        }

        permissionPollTask = Task { @MainActor [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(
                    for: Self.permissionPollInterval
                )
                guard !Task.isCancelled else {
                    return
                }
                self?.refreshPermissionStatus()
            }
        }
    }
}
