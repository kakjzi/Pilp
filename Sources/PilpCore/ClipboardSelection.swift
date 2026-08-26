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

    public func centeredIndices(
        maximumCount: Int,
        itemCount: Int
    ) -> [Int] {
        guard maximumCount > 0, itemCount > 0 else {
            return []
        }

        let visibleCount = min(maximumCount, itemCount)
        let selectedIndex = min(index, itemCount - 1)
        let firstOffset = -(visibleCount / 2)

        return (0..<visibleCount).map { position in
            (selectedIndex + firstOffset + position).modulo(itemCount)
        }
    }
}

private extension Int {
    func modulo(_ divisor: Int) -> Int {
        let remainder = self % divisor
        return remainder >= 0 ? remainder : remainder + divisor
    }
}
