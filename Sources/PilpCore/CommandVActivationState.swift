public struct CommandVActivationState {
    public enum Action: Equatable {
        case disabled
        case waitForPermission
        case startMonitoring
        case monitoring
        case stopMonitoring
    }

    public private(set) var isEnabled: Bool
    public private(set) var isPermissionGranted: Bool
    private var isMonitoring = false

    public init(
        isEnabled: Bool,
        isPermissionGranted: Bool
    ) {
        self.isEnabled = isEnabled
        self.isPermissionGranted = isPermissionGranted
    }

    public var action: Action {
        guard isEnabled else {
            return .disabled
        }

        guard isPermissionGranted else {
            return .waitForPermission
        }

        return isMonitoring ? .monitoring : .startMonitoring
    }

    @discardableResult
    public mutating func setEnabled(_ isEnabled: Bool) -> Action {
        self.isEnabled = isEnabled
        if !isEnabled, isMonitoring {
            isMonitoring = false
            return .stopMonitoring
        }
        return action
    }

    @discardableResult
    public mutating func refreshPermission(
        isGranted: Bool
    ) -> Action {
        isPermissionGranted = isGranted
        if !isGranted, isMonitoring {
            isMonitoring = false
            return .stopMonitoring
        }
        return action
    }

    public mutating func monitoringDidStart(succeeded: Bool) {
        isMonitoring = succeeded
    }
}
