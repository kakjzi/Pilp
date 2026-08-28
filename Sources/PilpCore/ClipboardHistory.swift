import Foundation

public enum ClipboardImageFormat: String, Equatable, Sendable {
    case png
    case tiff
}

public struct ClipboardImage: Equatable, Sendable {
    public let data: Data
    public let format: ClipboardImageFormat

    public init(data: Data, format: ClipboardImageFormat) {
        self.data = data
        self.format = format
    }

    public init(bytes: [UInt8], format: ClipboardImageFormat) {
        self.init(data: Data(bytes), format: format)
    }

    public var byteCount: Int {
        data.count
    }
}

public enum ClipboardContent: Equatable, Sendable {
    case text(String)
    case image(ClipboardImage)
}

public struct ClipboardItem: Identifiable, Equatable, Sendable {
    public let id: UUID
    public let content: ClipboardContent
    public let capturedAt: Date
    public let sourceAppName: String?

    public init(
        id: UUID = UUID(),
        content: ClipboardContent,
        capturedAt: Date = Date(),
        sourceAppName: String? = nil
    ) {
        self.id = id
        self.content = content
        self.capturedAt = capturedAt
        self.sourceAppName = sourceAppName
    }

    public var text: String? {
        guard case let .text(text) = content else {
            return nil
        }

        return text
    }
}

public struct ClipboardHistory: Sendable {
    public let limit: Int
    public let maximumTotalImageBytes: Int
    public private(set) var items: [ClipboardItem]

    public init(
        limit: Int = 10,
        maximumTotalImageBytes: Int = 80 * 1_024 * 1_024
    ) {
        precondition(limit > 0, "Clipboard history limit must be greater than zero")
        precondition(
            maximumTotalImageBytes > 0,
            "Image memory limit must be greater than zero"
        )

        self.limit = limit
        self.maximumTotalImageBytes = maximumTotalImageBytes
        self.items = []
    }

    public mutating func capture(
        _ text: String,
        at capturedAt: Date = Date(),
        sourceAppName: String? = nil
    ) {
        capture(
            .text(text),
            at: capturedAt,
            sourceAppName: sourceAppName
        )
    }

    public mutating func capture(
        _ content: ClipboardContent,
        at capturedAt: Date = Date(),
        sourceAppName: String? = nil
    ) {
        guard content.shouldStore else {
            return
        }

        items.removeAll { $0.content == content }
        items.insert(
            ClipboardItem(
                content: content,
                capturedAt: capturedAt,
                sourceAppName: sourceAppName
            ),
            at: 0
        )

        if items.count > limit {
            items.removeLast(items.count - limit)
        }

        trimImagesToMemoryLimit()
    }

    private mutating func trimImagesToMemoryLimit() {
        while totalImageBytes > maximumTotalImageBytes {
            guard let oldestImageIndex = items.lastIndex(where: {
                if case .image = $0.content {
                    return true
                }
                return false
            }) else {
                return
            }

            items.remove(at: oldestImageIndex)
        }
    }

    private var totalImageBytes: Int {
        items.reduce(into: 0) { total, item in
            if case let .image(image) = item.content {
                total += image.byteCount
            }
        }
    }
}

private extension ClipboardContent {
    var shouldStore: Bool {
        switch self {
        case let .text(text):
            text.contains(where: { !$0.isWhitespace })
        case let .image(image):
            !image.data.isEmpty
        }
    }
}
