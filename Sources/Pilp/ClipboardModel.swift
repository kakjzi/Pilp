import AppKit
import Combine
import PilpCore

@MainActor
final class ClipboardModel: NSObject, ObservableObject {
    @Published private(set) var items: [ClipboardItem] = []
    @Published private var selection = ClipboardSelection()

    private static let maximumImageBytes = 20 * 1_024 * 1_024

    private let pasteboard: NSPasteboard
    private var history: ClipboardHistory
    private var tracker: ClipboardChangeTracker
    private var timer: Timer?

    init(pasteboard: NSPasteboard = .general, historyLimit: Int = 10) {
        self.pasteboard = pasteboard
        self.history = ClipboardHistory(limit: historyLimit)
        self.tracker = ClipboardChangeTracker(
            initialChangeCount: pasteboard.changeCount
        )

        super.init()

        timer = Timer.scheduledTimer(
            timeInterval: 0.5,
            target: self,
            selector: #selector(pollPasteboard),
            userInfo: nil,
            repeats: true
        )
        timer?.tolerance = 0.1
    }

    var selectedItem: ClipboardItem? {
        guard items.indices.contains(selection.index) else {
            return nil
        }

        return items[selection.index]
    }

    var selectedPosition: Int {
        selectedItem == nil ? 0 : selection.index + 1
    }

    func moveSelection(by offset: Int) {
        selection.move(by: offset, itemCount: items.count)
    }

    @discardableResult
    func copySelectedItem() -> Bool {
        guard let selectedItem else {
            return false
        }

        pasteboard.clearContents()

        let didWrite: Bool
        switch selectedItem.content {
        case let .text(text):
            didWrite = pasteboard.setString(text, forType: .string)
        case let .image(image):
            didWrite = pasteboard.setData(
                image.data,
                forType: image.format.pasteboardType
            )
        }

        tracker = ClipboardChangeTracker(
            initialChangeCount: pasteboard.changeCount
        )

        return didWrite
    }

    @objc
    private func pollPasteboard() {
        let content: ClipboardContent? = tracker.capture(
            changeCount: pasteboard.changeCount,
            value: readClipboardContent()
        )

        guard let content else {
            return
        }

        history.capture(content)
        items = history.items
        selection.reset()
    }

    private func readClipboardContent() -> ClipboardContent? {
        guard let type = pasteboard.availableType(
            from: [.png, .tiff, .string]
        ) else {
            return nil
        }

        switch type {
        case .png:
            return imageContent(for: .png, format: .png)
        case .tiff:
            return imageContent(for: .tiff, format: .tiff)
        case .string:
            return pasteboard.string(forType: .string).map(ClipboardContent.text)
        default:
            return nil
        }
    }

    private func imageContent(
        for pasteboardType: NSPasteboard.PasteboardType,
        format: ClipboardImageFormat
    ) -> ClipboardContent? {
        guard
            let data = pasteboard.data(forType: pasteboardType),
            data.count <= Self.maximumImageBytes,
            NSImage(data: data) != nil
        else {
            return nil
        }

        return .image(ClipboardImage(data: data, format: format))
    }
}

private extension ClipboardImageFormat {
    var pasteboardType: NSPasteboard.PasteboardType {
        switch self {
        case .png:
            .png
        case .tiff:
            .tiff
        }
    }
}
