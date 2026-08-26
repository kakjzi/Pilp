import Testing
@testable import PilpCore

@Suite("Clipboard change tracker")
struct ClipboardChangeTrackerTests {
    @Test("ignores the clipboard contents that existed before launch")
    func ignoresInitialClipboardContents() {
        var tracker = ClipboardChangeTracker(initialChangeCount: 4)

        let captured = tracker.captureText(changeCount: 4, text: "already copied")

        #expect(captured == nil)
    }

    @Test("does not read clipboard data until the change count advances")
    func avoidsUnchangedClipboardReads() {
        var tracker = ClipboardChangeTracker(initialChangeCount: 4)
        var readCount = 0

        func readText() -> String? {
            readCount += 1
            return "already copied"
        }

        let captured = tracker.captureText(changeCount: 4, text: readText())

        #expect(captured == nil)
        #expect(readCount == 0)
    }

    @Test("captures changed text once")
    func capturesChangedTextOnce() {
        var tracker = ClipboardChangeTracker(initialChangeCount: 4)

        let firstPoll = tracker.captureText(changeCount: 5, text: "new text")
        let secondPoll = tracker.captureText(changeCount: 5, text: "new text")

        #expect(firstPoll == "new text")
        #expect(secondPoll == nil)
    }

    @Test("advances past non-text changes")
    func advancesPastNonTextChanges() {
        var tracker = ClipboardChangeTracker(initialChangeCount: 4)

        let imagePoll = tracker.captureText(changeCount: 5, text: nil)
        let repeatedPoll = tracker.captureText(changeCount: 5, text: "stale text")

        #expect(imagePoll == nil)
        #expect(repeatedPoll == nil)
    }
}
