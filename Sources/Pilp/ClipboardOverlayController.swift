import AppKit
import Combine
import PilpCore
import SwiftUI

@MainActor
final class ClipboardOverlayController {
    private static let panelSize = NSSize(width: 920, height: 340)
    private static let frameAutosaveName = "PilpClipboardOverlay"

    private let model: ClipboardModel
    private let session = ClipboardOverlaySession()
    private let directPastePerformer = DirectPastePerformer()
    private var panel: PilpOverlayPanel?

    init(model: ClipboardModel) {
        self.model = model
    }

    func toggle() {
        if panel?.isVisible == true {
            hide()
        } else {
            show()
        }
    }

    func show() {
        let panel = panel ?? makePanel()
        session.prepareForPresentation(
            isDirectPasteAvailable: directPastePerformer.isAvailable
        )
        panel.orderFrontRegardless()
        panel.makeKey()
        if let contentView = panel.contentViewController?.view {
            panel.makeFirstResponder(contentView)
        }
        session.requestKeyboardFocus()
    }

    func hide() {
        panel?.orderOut(nil)
    }

    private func makePanel() -> PilpOverlayPanel {
        let panel = PilpOverlayPanel(
            contentRect: NSRect(origin: .zero, size: Self.panelSize),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        panel.level = .popUpMenu
        panel.collectionBehavior = [
            .canJoinAllSpaces,
            .fullScreenAuxiliary,
            .transient
        ]
        panel.isFloatingPanel = true
        panel.becomesKeyOnlyIfNeeded = false
        panel.hidesOnDeactivate = false
        panel.isMovable = true
        panel.isMovableByWindowBackground = true
        panel.animationBehavior = .utilityWindow
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = false
        panel.onFind = { [weak session] in
            session?.requestSearchFocus()
        }
        panel.contentViewController = NSHostingController(
            rootView: ClipboardOverlayView(
                model: model,
                session: session,
                onCommit: { [weak self] mode in
                    self?.commitSelection(mode: mode)
                },
                onDismiss: { [weak self] in
                    self?.hide()
                }
            )
        )
        panel.setContentSize(Self.panelSize)

        let restoredSavedFrame = panel.setFrameUsingName(Self.frameAutosaveName)
        if !restoredSavedFrame {
            positionAtBottom(panel)
        }
        panel.setFrameAutosaveName(Self.frameAutosaveName)

        self.panel = panel
        return panel
    }

    private func commitSelection(mode: ClipboardPasteMode) {
        let action = PickerCommitPolicy.action(
            copySucceeded: model.copySelectedItem(mode: mode),
            isDirectPasteAvailable: directPastePerformer.isAvailable
        )

        switch action {
        case .none:
            return
        case .copyOnly:
            hide()
        case .copyAndPaste:
            hide()
            directPastePerformer.pasteAfterOverlayDismissal()
        }
    }

    private func positionAtBottom(_ panel: NSPanel) {
        let mouseLocation = NSEvent.mouseLocation
        let screen = NSScreen.screens.first {
            $0.frame.contains(mouseLocation)
        } ?? NSScreen.main

        guard let visibleFrame = screen?.visibleFrame else {
            panel.center()
            return
        }

        let origin = OverlayPlacement.bottomCenterOrigin(
            visibleFrame: visibleFrame,
            panelSize: Self.panelSize
        )
        panel.setFrameOrigin(origin)
    }
}

@MainActor
final class ClipboardOverlaySession: ObservableObject {
    @Published private(set) var keyboardFocusRequest = 0
    @Published private(set) var searchFocusRequest = 0
    @Published private(set) var isDirectPasteAvailable = false

    func prepareForPresentation(isDirectPasteAvailable: Bool) {
        self.isDirectPasteAvailable = isDirectPasteAvailable
    }

    func requestKeyboardFocus() {
        keyboardFocusRequest &+= 1
    }

    func requestSearchFocus() {
        searchFocusRequest &+= 1
    }
}

private final class PilpOverlayPanel: NSPanel {
    var onFind: (() -> Void)?

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }

    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        let relevantModifiers = event.modifierFlags.intersection([
            .command,
            .shift,
            .option,
            .control
        ])
        if relevantModifiers == .command,
            event.charactersIgnoringModifiers?.lowercased() == "f"
        {
            onFind?()
            return true
        }

        return super.performKeyEquivalent(with: event)
    }
}
