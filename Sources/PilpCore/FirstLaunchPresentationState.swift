public struct FirstLaunchPresentationState: Sendable {
    public private(set) var hasPresented: Bool
    private var requiresPermissionRecovery: Bool

    public init(
        hasPresented: Bool,
        requiresPermissionRecovery: Bool = false
    ) {
        self.hasPresented = hasPresented
        self.requiresPermissionRecovery = requiresPermissionRecovery
    }

    public mutating func consumePresentation() -> Bool {
        guard !hasPresented || requiresPermissionRecovery else {
            return false
        }

        hasPresented = true
        requiresPermissionRecovery = false
        return true
    }
}
