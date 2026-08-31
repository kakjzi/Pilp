import Testing
@testable import PilpCore

@Suite("First launch presentation")
struct FirstLaunchPresentationStateTests {
    @Test("presents onboarding only once")
    func presentsOnlyOnce() {
        var state = FirstLaunchPresentationState(hasPresented: false)

        let firstPresentation = state.consumePresentation()
        let secondPresentation = state.consumePresentation()

        #expect(firstPresentation)
        #expect(!secondPresentation)
        #expect(state.hasPresented)
    }

    @Test("does not present onboarding after it was saved")
    func respectsSavedPresentation() {
        var state = FirstLaunchPresentationState(hasPresented: true)

        let shouldPresent = state.consumePresentation()

        #expect(!shouldPresent)
    }

    @Test("presents settings again when Command-V access needs recovery")
    func presentsForPermissionRecovery() {
        var state = FirstLaunchPresentationState(
            hasPresented: true,
            requiresPermissionRecovery: true
        )

        let shouldPresent = state.consumePresentation()

        #expect(shouldPresent)
    }
}
