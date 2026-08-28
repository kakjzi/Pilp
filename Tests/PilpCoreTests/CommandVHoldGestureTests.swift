import Testing
@testable import PilpCore

@Suite("Command-V hold gesture")
struct CommandVHoldGestureTests {
    @Test("a quick press keeps the normal paste behavior")
    func quickPressPastes() {
        var gesture = CommandVHoldGesture()

        #expect(gesture.keyDown(isRepeat: false) == .none)
        #expect(gesture.keyUp() == .paste)
    }

    @Test("holding opens the picker without pasting")
    func holdOpensPicker() {
        var gesture = CommandVHoldGesture()

        #expect(gesture.keyDown(isRepeat: false) == .none)
        #expect(gesture.holdThresholdReached() == .showPicker)
        #expect(gesture.keyUp() == .none)
    }

    @Test("key repeat cannot trigger duplicate actions")
    func repeatIsIgnored() {
        var gesture = CommandVHoldGesture()

        #expect(gesture.keyDown(isRepeat: false) == .none)
        #expect(gesture.keyDown(isRepeat: true) == .none)
        #expect(gesture.holdThresholdReached() == .showPicker)
        #expect(gesture.holdThresholdReached() == .none)
        #expect(gesture.keyUp() == .none)
    }
}
