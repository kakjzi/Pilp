public enum PickerCommitAction: Equatable, Sendable {
    case none
    case copyOnly
    case copyAndPaste
}

public enum PickerCommitPolicy {
    public static func action(
        copySucceeded: Bool,
        isDirectPasteAvailable: Bool
    ) -> PickerCommitAction {
        guard copySucceeded else {
            return .none
        }

        return isDirectPasteAvailable ? .copyAndPaste : .copyOnly
    }
}
