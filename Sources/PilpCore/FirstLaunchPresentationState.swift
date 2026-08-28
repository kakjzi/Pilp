public struct FirstLaunchPresentationState: Sendable {
    public private(set) var hasPresented: Bool

    public init(hasPresented: Bool) {
        self.hasPresented = hasPresented
    }

    public mutating func consumePresentation() -> Bool {
        guard !hasPresented else {
            return false
        }

        hasPresented = true
        return true
    }
}
