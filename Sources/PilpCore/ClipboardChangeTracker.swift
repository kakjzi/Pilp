public struct ClipboardChangeTracker: Sendable {
    private var lastChangeCount: Int

    public init(initialChangeCount: Int) {
        self.lastChangeCount = initialChangeCount
    }

    public mutating func capture<Value>(
        changeCount: Int,
        value: @autoclosure () -> Value?
    ) -> Value? {
        guard changeCount != lastChangeCount else {
            return nil
        }

        lastChangeCount = changeCount
        return value()
    }

    public mutating func captureText(
        changeCount: Int,
        text: @autoclosure () -> String?
    ) -> String? {
        capture(changeCount: changeCount, value: text())
    }
}
