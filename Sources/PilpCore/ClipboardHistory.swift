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

    public init(
        id: UUID = UUID(),
        content: ClipboardContent,
        capturedAt: Date = Date()
    ) {
        self.id = id
        self.content = content
        self.capturedAt = capturedAt
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
    public private(set) var items: [ClipboardItem]

    public init(limit: Int = 10) {
        precondition(limit > 0, "Clipboard history limit must be greater than zero")

        self.limit = limit
        self.items = []
    }

    public mutating func capture(_ text: String, at capturedAt: Date = Date()) {
        capture(.text(text), at: capturedAt)
    }

    public mutating func capture(
        _ content: ClipboardContent,
        at capturedAt: Date = Date()
    ) {
        guard content.shouldStore else {
            return
        }

        items.removeAll { $0.content == content }
        items.insert(
            ClipboardItem(content: content, capturedAt: capturedAt),
            at: 0
        )

        if items.count > limit {
            items.removeLast(items.count - limit)
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
