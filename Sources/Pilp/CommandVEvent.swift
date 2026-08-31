import CoreGraphics

enum CommandVEvent {
    static let pasteKeyCode: CGKeyCode = 9
    static let syntheticEventMarker: Int64 = 0x50494C50

    static func post() {
        let source = CGEventSource(stateID: .combinedSessionState)
        let keyDown = CGEvent(
            keyboardEventSource: source,
            virtualKey: pasteKeyCode,
            keyDown: true
        )
        let keyUp = CGEvent(
            keyboardEventSource: source,
            virtualKey: pasteKeyCode,
            keyDown: false
        )

        for event in [keyDown, keyUp].compactMap({ $0 }) {
            event.flags = .maskCommand
            event.setIntegerValueField(
                .eventSourceUserData,
                value: syntheticEventMarker
            )
            event.post(tap: .cghidEventTap)
        }
    }
}
