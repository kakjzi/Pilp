import AppKit
import Combine
import PilpCore

@MainActor
final class ClipboardModel: NSObject, ObservableObject {
    @Published private(set) var items: [ClipboardItem] = []
    @Published private var selection = ClipboardSelection()
    @Published var searchQuery = "" {
        didSet {
            selection.reset()
            refreshVisibleItems()
        }
    }

    private static let maximumImageBytes = 20 * 1_024 * 1_024
    private static let maximumTotalImageBytes = 80 * 1_024 * 1_024
    private static let maximumRichTextBytes = 2 * 1_024 * 1_024

    private let pasteboard: NSPasteboard
    private var history: ClipboardHistory
    private var tracker: ClipboardChangeTracker
    private let privacySettings: ClipboardPrivacySettings
    private let sourceApplicationProvider: () -> ClipboardSourceApplication?
    private var timer: Timer?

    init(
        pasteboard: NSPasteboard = .general,
        historyLimit: Int = 10,
        privacySettings: ClipboardPrivacySettings,
        sourceApplicationProvider: @escaping () -> ClipboardSourceApplication? = {
            guard
                let app = NSWorkspace.shared.frontmostApplication,
                app.bundleIdentifier != Bundle.main.bundleIdentifier
            else {
                return nil
            }

            return ClipboardSourceApplication(
                name: app.localizedName,
                bundleIdentifier: app.bundleIdentifier
            )
        }
    ) {
        self.pasteboard = pasteboard
        self.history = ClipboardHistory(
            limit: historyLimit,
            maximumTotalImageBytes: Self.maximumTotalImageBytes
        )
        self.tracker = ClipboardChangeTracker(
            initialChangeCount: pasteboard.changeCount
        )
        self.privacySettings = privacySettings
        self.sourceApplicationProvider = sourceApplicationProvider

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

    var totalItemCount: Int {
        history.items.count
    }

    var shouldShowSearch: Bool {
        totalItemCount >= 6 || !searchQuery.isEmpty
    }

    var ribbonItems: [ClipboardItem] {
        selection.centeredIndices(
            maximumCount: 5,
            itemCount: items.count
        ).map { items[$0] }
    }

    func moveSelection(by offset: Int) {
        selection.move(by: offset, itemCount: items.count)
    }

    func selectItem(id: ClipboardItem.ID) {
        guard let index = items.firstIndex(where: { $0.id == id }) else {
            return
        }

        selection = ClipboardSelection(index: index)
    }

    @discardableResult
    func removeSelectedItem() -> Bool {
        guard let selectedItem else {
            return false
        }

        let didRemove = history.remove(id: selectedItem.id)
        refreshVisibleItems()
        selection.move(by: 0, itemCount: items.count)
        return didRemove
    }

    func clearHistory() {
        history.clear()
        searchQuery = ""
        selection.reset()
        refreshVisibleItems()
    }

    @discardableResult
    func togglePinSelectedItem() -> Bool {
        guard let selectedItem else {
            return false
        }

        let didToggle = history.togglePin(id: selectedItem.id)
        refreshVisibleItems(selecting: selectedItem.id)
        return didToggle
    }

    func togglePin(id: ClipboardItem.ID) {
        guard history.togglePin(id: id) else {
            return
        }
        refreshVisibleItems(selecting: id)
    }

    @discardableResult
    func copySelectedItem(mode: ClipboardPasteMode = .plain) -> Bool {
        guard let selectedItem else {
            return false
        }

        pasteboard.clearContents()

        let didWrite: Bool
        switch selectedItem.content {
        case let .text(text):
            didWrite = write(text: text, mode: mode)
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
        let candidate: ClipboardCaptureCandidate? = tracker.capture(
            changeCount: pasteboard.changeCount,
            value: makeCaptureCandidate()
        )

        guard let candidate else {
            return
        }

        history.capture(
            candidate.content,
            sourceAppName: candidate.sourceApplication?.name,
            sourceAppBundleIdentifier: candidate.sourceApplication?.bundleIdentifier
        )
        refreshVisibleItems()
        selection.reset()
    }

    private func makeCaptureCandidate() -> ClipboardCaptureCandidate? {
        let sourceApplication = sourceApplicationProvider()
        guard
            privacySettings.allowsCapture(from: sourceApplication),
            let content = readClipboardContent()
        else {
            return nil
        }

        return ClipboardCaptureCandidate(
            content: content,
            sourceApplication: sourceApplication
        )
    }

    private func readClipboardContent() -> ClipboardContent? {
        guard let type = pasteboard.availableType(
            from: [.png, .tiff, .string, .rtf, .html]
        ) else {
            return nil
        }

        switch type {
        case .png:
            return imageContent(for: .png, format: .png)
        case .tiff:
            return imageContent(for: .tiff, format: .tiff)
        case .string, .rtf, .html:
            return textContent()
        default:
            return nil
        }
    }

    private func textContent() -> ClipboardContent? {
        let rtfData = limitedRichTextData(for: .rtf, remainingBytes: nil)
        let htmlData = limitedRichTextData(
            for: .html,
            remainingBytes: Self.maximumRichTextBytes - (rtfData?.count ?? 0)
        )
        let plainText = pasteboard.string(forType: .string)
            ?? plainText(from: rtfData, documentType: .rtf)
            ?? plainText(from: htmlData, documentType: .html)

        guard let plainText else {
            return nil
        }

        return .text(ClipboardText(
            plainText: plainText,
            rtfData: rtfData,
            htmlData: htmlData
        ))
    }

    private func limitedRichTextData(
        for type: NSPasteboard.PasteboardType,
        remainingBytes: Int?
    ) -> Data? {
        let limit = min(
            Self.maximumRichTextBytes,
            max(0, remainingBytes ?? Self.maximumRichTextBytes)
        )
        guard
            limit > 0,
            let data = pasteboard.data(forType: type),
            data.count <= limit
        else {
            return nil
        }
        return data
    }

    private func plainText(
        from data: Data?,
        documentType: NSAttributedString.DocumentType
    ) -> String? {
        guard let data else {
            return nil
        }
        return try? NSAttributedString(
            data: data,
            options: [.documentType: documentType],
            documentAttributes: nil
        ).string
    }

    private func write(
        text: ClipboardText,
        mode: ClipboardPasteMode
    ) -> Bool {
        let representations = text.representations(for: mode)
        guard representations.hasRichText else {
            return pasteboard.setString(
                representations.plainText,
                forType: .string
            )
        }

        let item = NSPasteboardItem()
        item.setString(representations.plainText, forType: .string)
        if let rtfData = representations.rtfData {
            item.setData(rtfData, forType: .rtf)
        }
        if let htmlData = representations.htmlData {
            item.setData(htmlData, forType: .html)
        }
        return pasteboard.writeObjects([item])
    }

    private func refreshVisibleItems(
        selecting selectedID: ClipboardItem.ID? = nil
    ) {
        items = history.search(query: searchQuery)
        guard
            let selectedID,
            let index = items.firstIndex(where: { $0.id == selectedID })
        else {
            selection.move(by: 0, itemCount: items.count)
            return
        }
        selection = ClipboardSelection(index: index)
    }

    private func imageContent(
        for pasteboardType: NSPasteboard.PasteboardType,
        format: ClipboardImageFormat
    ) -> ClipboardContent? {
        guard
            let data = pasteboard.data(forType: pasteboardType),
            let image = NSImage(data: data)
        else {
            return nil
        }

        let storedImage: ClipboardImage
        switch format {
        case .png:
            storedImage = ClipboardImage(data: data, format: .png)
        case .tiff:
            guard
                let tiffData = image.tiffRepresentation,
                let bitmap = NSBitmapImageRep(data: tiffData),
                let pngData = bitmap.representation(
                    using: .png,
                    properties: [:]
                )
            else {
                return nil
            }
            storedImage = ClipboardImage(data: pngData, format: .png)
        }

        guard storedImage.byteCount <= Self.maximumImageBytes else {
            return nil
        }

        return .image(storedImage)
    }
}

private struct ClipboardCaptureCandidate {
    let content: ClipboardContent
    let sourceApplication: ClipboardSourceApplication?
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
