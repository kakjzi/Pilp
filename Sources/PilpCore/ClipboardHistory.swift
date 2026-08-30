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

public struct ClipboardText: Equatable, Sendable, ExpressibleByStringLiteral {
    public let plainText: String
    public let rtfData: Data?
    public let htmlData: Data?

    public init(
        plainText: String,
        rtfData: Data? = nil,
        htmlData: Data? = nil
    ) {
        self.plainText = plainText
        self.rtfData = rtfData
        self.htmlData = htmlData
    }

    public init(stringLiteral value: String) {
        self.init(plainText: value)
    }

    public var hasRichText: Bool {
        rtfData != nil || htmlData != nil
    }

    public func representations(
        for mode: ClipboardPasteMode
    ) -> ClipboardText {
        switch mode {
        case .plain:
            ClipboardText(plainText: plainText)
        case .original:
            self
        }
    }
}

public enum ClipboardContent: Equatable, Sendable {
    case text(ClipboardText)
    case image(ClipboardImage)
}

public struct ClipboardItem: Identifiable, Equatable, Sendable {
    public let id: UUID
    public let content: ClipboardContent
    public let capturedAt: Date
    public let sourceAppName: String?
    public let sourceAppBundleIdentifier: String?
    public internal(set) var isPinned: Bool

    public init(
        id: UUID = UUID(),
        content: ClipboardContent,
        capturedAt: Date = Date(),
        sourceAppName: String? = nil,
        sourceAppBundleIdentifier: String? = nil,
        isPinned: Bool = false
    ) {
        self.id = id
        self.content = content
        self.capturedAt = capturedAt
        self.sourceAppName = sourceAppName
        self.sourceAppBundleIdentifier = sourceAppBundleIdentifier
        self.isPinned = isPinned
    }

    public var text: String? {
        guard case let .text(text) = content else {
            return nil
        }

        return text.plainText
    }

    public var hasRichText: Bool {
        guard case let .text(text) = content else {
            return false
        }

        return text.hasRichText
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
            .text(ClipboardText(plainText: text)),
            at: capturedAt,
            sourceAppName: sourceAppName
        )
    }

    public mutating func capture(
        _ content: ClipboardContent,
        at capturedAt: Date = Date(),
        sourceAppName: String? = nil,
        sourceAppBundleIdentifier: String? = nil
    ) {
        guard content.shouldStore else {
            return
        }

        let wasPinned = items.first(where: {
            $0.content == content
        })?.isPinned ?? false
        items.removeAll { $0.content == content }
        let capturedItem = ClipboardItem(
            content: content,
            capturedAt: capturedAt,
            sourceAppName: sourceAppName,
            sourceAppBundleIdentifier: sourceAppBundleIdentifier,
            isPinned: wasPinned
        )
        items.insert(capturedItem, at: 0)

        sortItems()
        trimItemsToLimit(preserving: capturedItem.id)
        trimImagesToMemoryLimit()
    }

    @discardableResult
    public mutating func remove(id: ClipboardItem.ID) -> Bool {
        guard let index = items.firstIndex(where: { $0.id == id }) else {
            return false
        }

        items.remove(at: index)
        return true
    }

    public mutating func clear() {
        items.removeAll(keepingCapacity: false)
    }

    @discardableResult
    public mutating func togglePin(id: ClipboardItem.ID) -> Bool {
        guard let index = items.firstIndex(where: { $0.id == id }) else {
            return false
        }

        items[index].isPinned.toggle()
        sortItems()
        return true
    }

    public func search(query: String) -> [ClipboardItem] {
        let normalizedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedQuery.isEmpty else {
            return items
        }

        return items.filter { item in
            item.text?.localizedCaseInsensitiveContains(normalizedQuery) == true
                || item.sourceAppName?.localizedCaseInsensitiveContains(
                    normalizedQuery
                ) == true
        }
    }

    private mutating func sortItems() {
        items.sort { lhs, rhs in
            if lhs.isPinned != rhs.isPinned {
                return lhs.isPinned
            }
            return lhs.capturedAt > rhs.capturedAt
        }
    }

    private mutating func trimItemsToLimit(
        preserving capturedItemID: ClipboardItem.ID
    ) {
        while items.count > limit {
            let removalIndex = items.lastIndex(where: {
                !$0.isPinned && $0.id != capturedItemID
            }) ?? items.lastIndex(where: {
                $0.id != capturedItemID
            })
            guard let removalIndex else {
                return
            }
            items.remove(at: removalIndex)
        }
    }

    private mutating func trimImagesToMemoryLimit() {
        while totalImageBytes > maximumTotalImageBytes {
            let oldestImageIndex = items.lastIndex(where: {
                if case .image = $0.content, !$0.isPinned {
                    return true
                }
                return false
            }) ?? items.lastIndex(where: {
                if case .image = $0.content {
                    return true
                }
                return false
            })
            guard let oldestImageIndex else {
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
            text.plainText.contains(where: { !$0.isWhitespace })
        case let .image(image):
            !image.data.isEmpty
        }
    }
}
