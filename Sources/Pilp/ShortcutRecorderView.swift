import AppKit
import SwiftUI

struct ShortcutRecorderView: NSViewRepresentable {
    @Binding var shortcut: ShortcutDefinition?

    func makeCoordinator() -> Coordinator {
        Coordinator(shortcut: $shortcut)
    }

    func makeNSView(context: Context) -> ShortcutRecorderControl {
        let control = ShortcutRecorderControl()
        control.shortcut = shortcut
        control.onChange = { newShortcut in
            context.coordinator.shortcut.wrappedValue = newShortcut
        }
        return control
    }

    func updateNSView(
        _ nsView: ShortcutRecorderControl,
        context: Context
    ) {
        nsView.shortcut = shortcut
    }

    final class Coordinator {
        let shortcut: Binding<ShortcutDefinition?>

        init(shortcut: Binding<ShortcutDefinition?>) {
            self.shortcut = shortcut
        }
    }
}

final class ShortcutRecorderControl: NSControl {
    var shortcut: ShortcutDefinition? {
        didSet {
            needsDisplay = true
            setAccessibilityValue(shortcut?.displayString ?? "Not set")
        }
    }

    var onChange: ((ShortcutDefinition?) -> Void)?

    private var isRecording = false {
        didSet {
            needsDisplay = true
            needsUpdateConstraints = true
        }
    }

    override var acceptsFirstResponder: Bool { true }

    override var intrinsicContentSize: NSSize {
        NSSize(width: 158, height: 30)
    }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        configureAccessibility()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configureAccessibility()
    }

    override func mouseDown(with event: NSEvent) {
        let location = convert(event.locationInWindow, from: nil)

        if shortcut != nil, location.x > bounds.maxX - 30 {
            updateShortcut(nil)
            return
        }

        window?.makeFirstResponder(self)
        isRecording = true
    }

    override func accessibilityPerformPress() -> Bool {
        window?.makeFirstResponder(self)
        isRecording = true
        return true
    }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 {
            isRecording = false
            window?.makeFirstResponder(nil)
            return
        }

        if event.keyCode == 51, event.modifierFlags.intersection([
            .command,
            .option,
            .control,
            .shift
        ]).isEmpty {
            updateShortcut(nil)
            return
        }

        guard let shortcut = ShortcutDefinition(event: event) else {
            NSSound.beep()
            return
        }

        updateShortcut(shortcut)
    }

    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        guard isRecording else {
            return false
        }

        keyDown(with: event)
        return true
    }

    override func resignFirstResponder() -> Bool {
        isRecording = false
        return super.resignFirstResponder()
    }

    override func resetCursorRects() {
        addCursorRect(bounds, cursor: .pointingHand)
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        let background = NSBezierPath(
            roundedRect: bounds.insetBy(dx: 0.5, dy: 0.5),
            xRadius: 7,
            yRadius: 7
        )
        (isRecording
            ? NSColor.controlAccentColor.withAlphaComponent(0.14)
            : NSColor.controlBackgroundColor).setFill()
        background.fill()

        (isRecording
            ? NSColor.controlAccentColor
            : NSColor.separatorColor).setStroke()
        background.lineWidth = isRecording ? 2 : 1
        background.stroke()

        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        let text = isRecording
            ? "Press shortcut…"
            : shortcut?.displayString ?? "Record Shortcut"
        let textRect = bounds.insetBy(dx: 12, dy: 6)
        (text as NSString).draw(
            in: textRect,
            withAttributes: [
                .font: NSFont.systemFont(ofSize: 13, weight: .medium),
                .foregroundColor: NSColor.labelColor,
                .paragraphStyle: paragraph
            ]
        )

        if shortcut != nil, !isRecording {
            let symbol = NSImage(
                systemSymbolName: "xmark.circle.fill",
                accessibilityDescription: "Clear shortcut"
            )
            symbol?.isTemplate = true
            symbol?.draw(
                in: NSRect(
                    x: bounds.maxX - 24,
                    y: bounds.midY - 7,
                    width: 14,
                    height: 14
                )
            )
        }
    }

    private func updateShortcut(_ shortcut: ShortcutDefinition?) {
        self.shortcut = shortcut
        onChange?(shortcut)
        isRecording = false
        window?.makeFirstResponder(nil)
    }

    private func configureAccessibility() {
        setAccessibilityElement(true)
        setAccessibilityRole(.button)
        setAccessibilityLabel("Global shortcut")
        setAccessibilityValue(shortcut?.displayString ?? "Not set")
    }
}
