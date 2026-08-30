import Testing
@testable import PilpCore

@Suite("Picker commit policy")
struct PickerCommitPolicyTests {
    @Test("successful copy pastes immediately when access is available")
    func requestsDirectPasteAfterSuccessfulCopy() {
        #expect(
            PickerCommitPolicy.action(
                copySucceeded: true,
                isDirectPasteAvailable: true
            ) == .copyAndPaste
        )
    }

    @Test("successful copy falls back to copy only without access")
    func fallsBackToCopyOnlyWithoutAccess() {
        #expect(
            PickerCommitPolicy.action(
                copySucceeded: true,
                isDirectPasteAvailable: false
            ) == .copyOnly
        )
    }

    @Test("failed copy never requests a paste")
    func doesNothingAfterFailedCopy() {
        #expect(
            PickerCommitPolicy.action(
                copySucceeded: false,
                isDirectPasteAvailable: true
            ) == .none
        )
    }
}
