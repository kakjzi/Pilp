import ApplicationServices
import Foundation

@MainActor
final class DirectPastePerformer {
    private static let focusRestorationDelay: TimeInterval = 0.08

    var isAvailable: Bool {
        AXIsProcessTrusted()
    }

    func pasteAfterOverlayDismissal() {
        guard isAvailable else {
            return
        }

        DispatchQueue.main.asyncAfter(
            deadline: .now() + Self.focusRestorationDelay
        ) {
            CommandVEvent.post()
        }
    }
}
