import Foundation

public enum ClipboardCapturePolicy {
    public static func allowsCapture(
        now: Date,
        pausedUntil: Date?,
        sourceAppBundleIdentifier: String?,
        excludedBundleIdentifiers: Set<String>
    ) -> Bool {
        if let pausedUntil, now < pausedUntil {
            return false
        }

        guard let sourceAppBundleIdentifier else {
            return true
        }

        return !excludedBundleIdentifiers.contains(
            sourceAppBundleIdentifier
        )
    }
}

public enum ClipboardPasteMode: Equatable, Sendable {
    case plain
    case original
}
