import CoreGraphics
import Foundation
import PilpCore

final class CommandVHoldMonitor {
    private static let pasteKeyCode: CGKeyCode = 9
    private static let syntheticEventMarker: Int64 = 0x50494C50
    private static let holdDelay: TimeInterval = 0.45

    private let onLongPress: () -> Void
    private var gesture = CommandVHoldGesture()
    private var holdWorkItem: DispatchWorkItem?
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?

    init(onLongPress: @escaping () -> Void) {
        self.onLongPress = onLongPress
    }

    deinit {
        stop()
    }

    func start() -> Bool {
        guard eventTap == nil else {
            return true
        }

        let eventMask = eventMask(for: .keyDown)
            | eventMask(for: .keyUp)
        guard let eventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: eventMask,
            callback: pilpCommandVEventTapCallback,
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else {
            return false
        }

        guard let runLoopSource = CFMachPortCreateRunLoopSource(
            kCFAllocatorDefault,
            eventTap,
            0
        ) else {
            CFMachPortInvalidate(eventTap)
            return false
        }

        self.eventTap = eventTap
        self.runLoopSource = runLoopSource
        CFRunLoopAddSource(
            CFRunLoopGetMain(),
            runLoopSource,
            .commonModes
        )
        CGEvent.tapEnable(tap: eventTap, enable: true)
        return true
    }

    func stop() {
        cancelPendingGesture()

        if let runLoopSource {
            CFRunLoopRemoveSource(
                CFRunLoopGetMain(),
                runLoopSource,
                .commonModes
            )
            self.runLoopSource = nil
        }

        if let eventTap {
            CFMachPortInvalidate(eventTap)
            self.eventTap = nil
        }
    }

    fileprivate func handle(
        proxy: CGEventTapProxy,
        type: CGEventType,
        event: CGEvent
    ) -> Unmanaged<CGEvent>? {
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            cancelPendingGesture()
            if let eventTap {
                CGEvent.tapEnable(tap: eventTap, enable: true)
            }
            return Unmanaged.passUnretained(event)
        }

        if event.getIntegerValueField(.eventSourceUserData)
            == Self.syntheticEventMarker
        {
            return Unmanaged.passUnretained(event)
        }

        let keyCode = CGKeyCode(
            event.getIntegerValueField(.keyboardEventKeycode)
        )
        guard keyCode == Self.pasteKeyCode else {
            return Unmanaged.passUnretained(event)
        }

        switch type {
        case .keyDown:
            guard isCommandV(event) else {
                return Unmanaged.passUnretained(event)
            }

            let wasPressed = gesture.isPressed
            _ = gesture.keyDown(
                isRepeat: event.getIntegerValueField(
                    .keyboardEventAutorepeat
                ) != 0
            )
            if !wasPressed, gesture.isPressed {
                scheduleHoldAction()
            }
            return nil

        case .keyUp:
            guard gesture.isPressed else {
                return Unmanaged.passUnretained(event)
            }

            holdWorkItem?.cancel()
            holdWorkItem = nil
            if gesture.keyUp() == .paste {
                postCommandV()
            }
            return nil

        default:
            return Unmanaged.passUnretained(event)
        }
    }

    private func scheduleHoldAction() {
        holdWorkItem?.cancel()
        let workItem = DispatchWorkItem { [weak self] in
            guard let self else {
                return
            }

            if gesture.holdThresholdReached() == .showPicker {
                onLongPress()
            }
        }
        holdWorkItem = workItem
        DispatchQueue.main.asyncAfter(
            deadline: .now() + Self.holdDelay,
            execute: workItem
        )
    }

    private func cancelPendingGesture() {
        holdWorkItem?.cancel()
        holdWorkItem = nil
        gesture.cancel()
    }

    private func isCommandV(_ event: CGEvent) -> Bool {
        let relevantFlags = event.flags.intersection([
            .maskCommand,
            .maskShift,
            .maskAlternate,
            .maskControl
        ])
        return relevantFlags == .maskCommand
    }

    private func postCommandV() {
        let source = CGEventSource(stateID: .combinedSessionState)
        let keyDown = CGEvent(
            keyboardEventSource: source,
            virtualKey: Self.pasteKeyCode,
            keyDown: true
        )
        let keyUp = CGEvent(
            keyboardEventSource: source,
            virtualKey: Self.pasteKeyCode,
            keyDown: false
        )

        for event in [keyDown, keyUp].compactMap({ $0 }) {
            event.flags = .maskCommand
            event.setIntegerValueField(
                .eventSourceUserData,
                value: Self.syntheticEventMarker
            )
            event.post(tap: .cgAnnotatedSessionEventTap)
        }
    }

    private func eventMask(for type: CGEventType) -> CGEventMask {
        CGEventMask(1) << type.rawValue
    }
}

private func pilpCommandVEventTapCallback(
    proxy: CGEventTapProxy,
    type: CGEventType,
    event: CGEvent,
    userInfo: UnsafeMutableRawPointer?
) -> Unmanaged<CGEvent>? {
    guard let userInfo else {
        return Unmanaged.passUnretained(event)
    }

    let monitor = Unmanaged<CommandVHoldMonitor>
        .fromOpaque(userInfo)
        .takeUnretainedValue()
    return monitor.handle(proxy: proxy, type: type, event: event)
}
