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
}
