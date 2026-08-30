import Foundation
import Testing
@testable import PilpCore

@Suite("Clipboard power features")
struct ClipboardPowerFeaturesTests {
    @Test("keeps rich text representations beside a plain fallback")
    func keepsRichTextRepresentations() {
        let text = ClipboardText(
            plainText: "Hello",
            rtfData: Data([1, 2]),
            htmlData: Data([3, 4])
        )

        #expect(text.plainText == "Hello")
        #expect(text.hasRichText)
        #expect(text.rtfData == Data([1, 2]))
        #expect(text.htmlData == Data([3, 4]))
    }

    @Test("plain strips rich representations and original preserves them")
    func choosesPasteRepresentations() {
        let text = ClipboardText(
            plainText: "Hello",
            rtfData: Data([1, 2]),
            htmlData: Data([3, 4])
        )

        let plain = text.representations(for: .plain)
        #expect(plain.plainText == "Hello")
        #expect(plain.rtfData == nil)
        #expect(plain.htmlData == nil)

        let original = text.representations(for: .original)
        #expect(original.rtfData == Data([1, 2]))
        #expect(original.htmlData == Data([3, 4]))
    }

    @Test("deletes one item and clears the remaining history")
    func deletesAndClearsHistory() throws {
        var history = ClipboardHistory(limit: 10)
        history.capture("first")
        history.capture("second")
        let firstID = try #require(
            history.items.first(where: { $0.text == "first" })?.id
        )

        let didRemove = history.remove(id: firstID)
        #expect(didRemove)
        #expect(history.items.compactMap(\.text) == ["second"])

        history.clear()
        #expect(history.items.isEmpty)
    }

    @Test("keeps pinned items first while limiting total history")
    func keepsPinnedItemsWithinTotalLimit() throws {
        var history = ClipboardHistory(limit: 2)
        let start = Date(timeIntervalSince1970: 1_800_000_000)
        history.capture("keep", at: start)
        let pinnedID = try #require(history.items.first?.id)
        let didPin = history.togglePin(id: pinnedID)
        #expect(didPin)

        history.capture("newer", at: start.addingTimeInterval(1))
        history.capture("newest", at: start.addingTimeInterval(2))
        history.capture("overflow", at: start.addingTimeInterval(3))

        #expect(history.items.compactMap(\.text) == [
            "keep",
            "overflow"
        ])
        #expect(history.items.count == history.limit)
        #expect(history.items.first?.isPinned == true)
    }

    @Test("a new copy survives when every existing item is pinned")
    func newestCopySurvivesFullyPinnedHistory() throws {
        var history = ClipboardHistory(limit: 2)
        let start = Date(timeIntervalSince1970: 1_800_000_000)

        history.capture("first", at: start)
        let firstID = try #require(history.items.first?.id)
        let didPinFirst = history.togglePin(id: firstID)
        #expect(didPinFirst)

        history.capture("second", at: start.addingTimeInterval(1))
        let secondID = try #require(
            history.items.first(where: { $0.text == "second" })?.id
        )
        let didPinSecond = history.togglePin(id: secondID)
        #expect(didPinSecond)

        history.capture("newest", at: start.addingTimeInterval(2))

        #expect(history.items.compactMap(\.text) == ["second", "newest"])
        #expect(history.items.count == history.limit)
        #expect(history.items.first?.isPinned == true)
        #expect(history.items.last?.isPinned == false)
    }

    @Test("searches text and source app without case sensitivity")
    func searchesTextAndSourceApp() {
        var history = ClipboardHistory(limit: 10)
        history.capture("Release Notes", sourceAppName: "Firefox")
        history.capture("회의 정리", sourceAppName: "Slack")

        #expect(history.search(query: "release").compactMap(\.text) == [
            "Release Notes"
        ])
        #expect(history.search(query: "FIREFOX").compactMap(\.text) == [
            "Release Notes"
        ])
        #expect(history.search(query: "없는 값").isEmpty)
    }

    @Test("a duplicate capture retains its pinned state")
    func duplicateRetainsPin() throws {
        var history = ClipboardHistory(limit: 10)
        history.capture("repeat")
        let itemID = try #require(history.items.first?.id)
        let didPin = history.togglePin(id: itemID)
        #expect(didPin)

        history.capture("repeat")

        #expect(history.items.count == 1)
        #expect(history.items.first?.isPinned == true)
    }
}
