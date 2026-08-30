import Combine
import Foundation
import ServiceManagement

@MainActor
final class LaunchAtLoginSettings: ObservableObject {
    @Published private(set) var isEnabled = false
    @Published private(set) var errorMessage: String?

    init() {
        refresh()
    }

    func setEnabled(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            errorMessage = error.localizedDescription
            refresh(preservingError: true)
            return
        }
        refresh()
    }

    func refresh(preservingError: Bool = false) {
        switch SMAppService.mainApp.status {
        case .enabled:
            isEnabled = true
            if !preservingError {
                errorMessage = nil
            }
        case .requiresApproval:
            isEnabled = false
            if !preservingError {
                errorMessage = L10n.text(
                    "settings.launch_at_login.requires_approval"
                )
            }
        case .notFound, .notRegistered:
            isEnabled = false
            if !preservingError {
                errorMessage = nil
            }
        @unknown default:
            isEnabled = false
        }
    }
}
