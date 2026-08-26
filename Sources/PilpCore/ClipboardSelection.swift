public struct ClipboardSelection: Equatable, Sendable {
    public private(set) var index: Int

    public init(index: Int = 0) {
        self.index = max(0, index)
    }

    public mutating func move(by offset: Int, itemCount: Int) {
        guard itemCount > 0 else {
            index = 0
            return
        }

        let currentIndex = min(index, itemCount - 1)
        index = (currentIndex + offset).modulo(itemCount)
    }

    public mutating func reset() {
        index = 0
    }
}

private extension Int {
    func modulo(_ divisor: Int) -> Int {
        let remainder = self % divisor
        return remainder >= 0 ? remainder : remainder + divisor
    }
}
