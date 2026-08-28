import Foundation
import Testing
@testable import PilpCore

@Suite("Clipboard history")
struct ClipboardHistoryTests {
    @Test("keeps the newest text first and trims entries to the limit")
    func keepsNewestEntriesWithinLimit() {
        var history = ClipboardHistory(limit: 3)

        history.capture("first")
        history.capture("second")
        history.capture("third")
        history.capture("fourth")

        #expect(history.items.compactMap(\.text) == ["fourth", "third", "second"])
    }

    @Test("ignores blank text")
    func ignoresBlankText() {
        var history = ClipboardHistory(limit: 10)

        history.capture("   \n\t")

        #expect(history.items.isEmpty)
    }

    @Test("moves a copied duplicate back to the front")
    func movesDuplicateToFront() {
        var history = ClipboardHistory(limit: 10)

        history.capture("first")
        history.capture("second")
        history.capture("first")

        #expect(history.items.compactMap(\.text) == ["first", "second"])
    }

    @Test("keeps image data with its pasteboard format")
    func capturesImages() {
        var history = ClipboardHistory(limit: 10)
        let image = ClipboardImage(
            bytes: [0x89, 0x50, 0x4E, 0x47],
            format: .png
        )

        history.capture(.image(image))

        #expect(history.items.first?.content == .image(image))
    }

    @Test("keeps capture source and time with an item")
    func keepsCaptureMetadata() {
        var history = ClipboardHistory(limit: 10)
        let capturedAt = Date(timeIntervalSince1970: 1_800_000_000)

        history.capture(
            .text("release notes"),
            at: capturedAt,
            sourceAppName: "Safari"
        )

        #expect(history.items.first?.capturedAt == capturedAt)
        #expect(history.items.first?.sourceAppName == "Safari")
    }

    @Test("trims the oldest images when their total memory exceeds the limit")
    func trimsImagesToTotalMemoryLimit() {
        var history = ClipboardHistory(
            limit: 10,
            maximumTotalImageBytes: 5
        )
        let olderImage = ClipboardImage(bytes: [1, 2, 3], format: .png)
        let newerImage = ClipboardImage(bytes: [4, 5, 6, 7], format: .png)

        history.capture(.image(olderImage))
        history.capture("keep this text")
        history.capture(.image(newerImage))

        #expect(history.items.map(\.content) == [
            .image(newerImage),
            .text("keep this text")
        ])
    }
}
