public struct CommandVHoldGesture {
    public enum Action: Equatable {
        case none
        case paste
        case showPicker
    }

    public private(set) var isPressed = false
    private var didOpenPicker = false

    public init() {}

    public mutating func keyDown(isRepeat: Bool) -> Action {
        guard !isPressed else {
            return .none
        }

        guard !isRepeat else {
            return .none
        }

        isPressed = true
        didOpenPicker = false
        return .none
    }

    public mutating func holdThresholdReached() -> Action {
        guard isPressed, !didOpenPicker else {
            return .none
        }

        didOpenPicker = true
        return .showPicker
    }

    public mutating func keyUp() -> Action {
        guard isPressed else {
            return .none
        }

        isPressed = false
        defer { didOpenPicker = false }
        return didOpenPicker ? .none : .paste
    }

    public mutating func cancel() {
        isPressed = false
        didOpenPicker = false
    }
}
