import AppKit
import PilpCore
import SwiftUI

@MainActor
final class ClipboardOverlayController {
    private static let panelSize = NSSize(width: 920, height: 340)
    private static let frameAutosaveName = "PilpClipboardOverlay"

    private let model: ClipboardModel
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
        panel.orderFrontRegardless()
        DispatchQueue.main.async {
            panel.makeKey()
        }
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
        panel.contentViewController = NSHostingController(
            rootView: ClipboardOverlayView(
                model: model,
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

private final class PilpOverlayPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}
