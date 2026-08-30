import Foundation
import Testing
@testable import PilpCore

@Suite("Clipboard capture privacy policy")
struct ClipboardCapturePolicyTests {
    private let now = Date(timeIntervalSince1970: 1_800_000_000)

    @Test("blocks every app until a pause expires")
    func blocksDuringPause() {
        #expect(
            !ClipboardCapturePolicy.allowsCapture(
                now: now,
                pausedUntil: now.addingTimeInterval(300),
                sourceAppBundleIdentifier: "org.mozilla.firefox",
                excludedBundleIdentifiers: []
            )
        )
        #expect(
            ClipboardCapturePolicy.allowsCapture(
                now: now,
                pausedUntil: now,
                sourceAppBundleIdentifier: "org.mozilla.firefox",
                excludedBundleIdentifiers: []
            )
        )
    }

    @Test("blocks an excluded source app")
    func blocksExcludedApp() {
        #expect(
            !ClipboardCapturePolicy.allowsCapture(
                now: now,
                pausedUntil: nil,
                sourceAppBundleIdentifier: "com.1password.1password",
                excludedBundleIdentifiers: ["com.1password.1password"]
            )
        )
    }

    @Test("allows an unknown or non-excluded source app")
    func allowsOtherApps() {
        #expect(
            ClipboardCapturePolicy.allowsCapture(
                now: now,
                pausedUntil: nil,
                sourceAppBundleIdentifier: nil,
                excludedBundleIdentifiers: ["com.1password.1password"]
            )
        )
        #expect(
            ClipboardCapturePolicy.allowsCapture(
                now: now,
                pausedUntil: nil,
                sourceAppBundleIdentifier: "org.mozilla.firefox",
                excludedBundleIdentifiers: ["com.1password.1password"]
            )
        )
    }
}
