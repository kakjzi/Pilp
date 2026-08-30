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

    @Test("granting permission after launch starts the listener")
    func permissionGrantedAfterLaunchStartsListener() {
        var activation = CommandVActivationState(
            isEnabled: true,
            isPermissionGranted: false
        )

        #expect(activation.action == .waitForPermission)
        #expect(
            activation.refreshPermission(isGranted: true)
                == .startMonitoring
        )
        activation.monitoringDidStart(succeeded: true)
        #expect(activation.action == .monitoring)
    }

    @Test("revoking permission stops an active listener")
    func revokedPermissionStopsListener() {
        var activation = CommandVActivationState(
            isEnabled: true,
            isPermissionGranted: true
        )
        activation.monitoringDidStart(succeeded: true)

        #expect(
            activation.refreshPermission(isGranted: false)
                == .stopMonitoring
        )
        #expect(activation.action == .waitForPermission)
    }

    @Test("enabling the gesture starts a listener when access exists")
    func enablingStartsListenerWhenAllowed() {
        var activation = CommandVActivationState(
            isEnabled: false,
            isPermissionGranted: true
        )

        #expect(activation.setEnabled(true) == .startMonitoring)
    }
}
