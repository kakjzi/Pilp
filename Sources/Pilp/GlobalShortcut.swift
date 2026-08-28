import AppKit
import Carbon.HIToolbox
import Combine
import Foundation

struct ShortcutDefinition: Codable, Equatable {
    let keyCode: UInt32
    let modifierFlagsRawValue: UInt
    let keyDisplay: String

    init?(event: NSEvent) {
        let modifiers = event.modifierFlags.intersection([
            .command,
            .option,
            .control,
            .shift
        ])

        guard !modifiers.isEmpty else {
            return nil
        }

        self.keyCode = UInt32(event.keyCode)
        self.modifierFlagsRawValue = modifiers.rawValue
        self.keyDisplay = Self.displayKey(for: event)
    }

    var displayString: String {
        let modifiers = NSEvent.ModifierFlags(
            rawValue: modifierFlagsRawValue
        )

        return [
            modifiers.contains(.control) ? "⌃" : "",
            modifiers.contains(.option) ? "⌥" : "",
            modifiers.contains(.shift) ? "⇧" : "",
            modifiers.contains(.command) ? "⌘" : "",
            keyDisplay
        ].joined()
    }

    var carbonModifiers: UInt32 {
        let modifiers = NSEvent.ModifierFlags(
            rawValue: modifierFlagsRawValue
        )
        var result: UInt32 = 0

        if modifiers.contains(.command) {
            result |= UInt32(cmdKey)
        }
        if modifiers.contains(.option) {
            result |= UInt32(optionKey)
        }
        if modifiers.contains(.control) {
            result |= UInt32(controlKey)
        }
        if modifiers.contains(.shift) {
            result |= UInt32(shiftKey)
        }

        return result
    }

    private static func displayKey(for event: NSEvent) -> String {
        switch event.keyCode {
        case 36:
            return "↩"
        case 48:
            return "⇥"
        case 49:
            return L10n.text("shortcut.key.space")
        case 51:
            return "⌫"
        case 53:
            return "esc"
        case 123:
            return "←"
        case 124:
            return "→"
        case 125:
            return "↓"
        case 126:
            return "↑"
        default:
            return event.charactersIgnoringModifiers?
                .uppercased() ?? "?"
        }
    }
}

@MainActor
final class ShortcutSettings: ObservableObject {
    @Published var shortcut: ShortcutDefinition? {
        didSet {
            guard shortcut != oldValue else {
                return
            }

            persistShortcut()
            registerShortcut()
        }
    }

    @Published private(set) var registrationError: String?

    private static let storageKey = "pilp.globalShortcut"

    private let defaults: UserDefaults
    private let monitor: GlobalShortcutMonitor

    init(
        defaults: UserDefaults = .standard,
        onTrigger: @escaping () -> Void
    ) {
        self.defaults = defaults
        self.monitor = GlobalShortcutMonitor(onTrigger: onTrigger)

        if
            let data = defaults.data(forKey: Self.storageKey),
            let shortcut = try? JSONDecoder().decode(
                ShortcutDefinition.self,
                from: data
            )
        {
            self.shortcut = shortcut
        } else {
            self.shortcut = nil
        }

        registerShortcut()
    }

    private func persistShortcut() {
        guard let shortcut else {
            defaults.removeObject(forKey: Self.storageKey)
            return
        }

        guard let data = try? JSONEncoder().encode(shortcut) else {
            return
        }

        defaults.set(data, forKey: Self.storageKey)
    }

    private func registerShortcut() {
        registrationError = monitor.register(shortcut)
            ? nil
            : L10n.text("shortcut.registration_error")
    }
}

private final class GlobalShortcutMonitor {
    private static let signature: OSType = 0x50494C50

    private let onTrigger: () -> Void
    private var eventHandler: EventHandlerRef?
    private var hotKey: EventHotKeyRef?

    init(onTrigger: @escaping () -> Void) {
        self.onTrigger = onTrigger

        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )
        let userData = Unmanaged.passUnretained(self).toOpaque()

        InstallEventHandler(
            GetApplicationEventTarget(),
            pilpGlobalHotKeyHandler,
            1,
            &eventType,
            userData,
            &eventHandler
        )
    }

    deinit {
        if let hotKey {
            UnregisterEventHotKey(hotKey)
        }
        if let eventHandler {
            RemoveEventHandler(eventHandler)
        }
    }

    func register(_ shortcut: ShortcutDefinition?) -> Bool {
        if let hotKey {
            UnregisterEventHotKey(hotKey)
            self.hotKey = nil
        }

        guard let shortcut else {
            return true
        }

        let hotKeyID = EventHotKeyID(
            signature: Self.signature,
            id: 1
        )
        let status = RegisterEventHotKey(
            shortcut.keyCode,
            shortcut.carbonModifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKey
        )

        return status == noErr
    }

    func handleTrigger() {
        onTrigger()
    }
}

private func pilpGlobalHotKeyHandler(
    _ nextHandler: EventHandlerCallRef?,
    _ event: EventRef?,
    _ userData: UnsafeMutableRawPointer?
) -> OSStatus {
    guard let userData else {
        return OSStatus(eventNotHandledErr)
    }

    let monitor = Unmanaged<GlobalShortcutMonitor>
        .fromOpaque(userData)
        .takeUnretainedValue()
    monitor.handleTrigger()

    return noErr
}
