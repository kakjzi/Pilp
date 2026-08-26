import Testing
@testable import PilpCore

@Suite("Clipboard deck selection")
struct ClipboardSelectionTests {
    @Test("moves right and wraps to the first item")
    func movesRightWithWrapping() {
        var selection = ClipboardSelection()

        selection.move(by: 1, itemCount: 3)
        selection.move(by: 1, itemCount: 3)
        selection.move(by: 1, itemCount: 3)

        #expect(selection.index == 0)
    }

    @Test("moves left from the first item to the last item")
    func movesLeftWithWrapping() {
        var selection = ClipboardSelection()

        selection.move(by: -1, itemCount: 3)

        #expect(selection.index == 2)
    }

    @Test("stays at zero when there are no items")
    func handlesEmptyHistory() {
        var selection = ClipboardSelection()

        selection.move(by: 1, itemCount: 0)

        #expect(selection.index == 0)
    }
}
