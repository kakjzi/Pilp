import AppKit
import PilpCore
import SwiftUI

struct ClipboardMenuView: View {
    @ObservedObject var model: ClipboardModel
    @ObservedObject var privacySettings: ClipboardPrivacySettings
    @ObservedObject var updater: AppUpdater
    let onShowPicker: () -> Void

    @State private var showsClearConfirmation = false

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header

            if model.shouldShowSearch {
                searchField
            }

            if let selectedItem = model.selectedItem {
                deck(selectedItem)
            } else {
                emptyState
            }

            Divider()

            footer
        }
        .padding(16)
        .frame(width: 460)
        .confirmationDialog(
            L10n.text("history.clear.confirmation"),
            isPresented: $showsClearConfirmation
        ) {
            Button(L10n.text("history.clear"), role: .destructive) {
                model.clearHistory()
            }
        }
    }

    private var header: some View {
        HStack {
            Image(nsImage: NSApplication.shared.applicationIconImage)
                .resizable()
                .interpolation(.high)
                .frame(width: 32, height: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text("Pilp")
                    .font(.headline)

                Text(L10n.text("tagline"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 5) {
                Text("\(model.selectedPosition) / \(model.items.count)")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)

                Button {
                    if privacySettings.isPaused {
                        privacySettings.resume()
                    } else {
                        privacySettings.pauseForFiveMinutes()
                    }
                } label: {
                    Label(
                        privacySettings.isPaused
                            ? L10n.format(
                                "privacy.resume_countdown",
                                privacySettings.remainingPauseSeconds
                            )
                            : L10n.text("privacy.pause_five_minutes"),
                        systemImage: privacySettings.isPaused
                            ? "play.fill"
                            : "pause.fill"
                    )
                }
                .buttonStyle(.borderless)
                .font(.caption.weight(.semibold))
                .foregroundStyle(privacySettings.isPaused ? .orange : .secondary)
            }
        }
    }

    private var searchField: some View {
        TextField(
            L10n.text("history.search.placeholder"),
            text: $model.searchQuery
        )
        .textFieldStyle(.roundedBorder)
    }

    private func deck(_ item: ClipboardItem) -> some View {
        VStack(spacing: 12) {
            HStack(spacing: 10) {
                navigationButton(systemImage: "chevron.left", offset: -1)

                clipboardCard(item)

                navigationButton(systemImage: "chevron.right", offset: 1)
            }

            HStack(spacing: 8) {
                Button {
                    model.togglePinSelectedItem()
                } label: {
                    Image(systemName: item.isPinned ? "pin.fill" : "pin")
                }
                .help(
                    L10n.text(item.isPinned ? "history.unpin" : "history.pin")
                )

                Button {
                    copyAndClose(mode: .plain)
                } label: {
                    Label(
                        L10n.text("paste.plain"),
                        systemImage: "textformat"
                    )
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.return, modifiers: [])

                if item.hasRichText {
                    Button {
                        copyAndClose(mode: .original)
                    } label: {
                        Label(
                            L10n.text("paste.original"),
                            systemImage: "paintbrush"
                        )
                    }
                    .keyboardShortcut(.return, modifiers: [.shift])
                }

                Button(role: .destructive) {
                    model.removeSelectedItem()
                } label: {
                    Image(systemName: "trash")
                }
                .help(L10n.text("history.delete"))
            }
        }
    }

    private func navigationButton(systemImage: String, offset: Int) -> some View {
        Button {
            model.moveSelection(by: offset)
        } label: {
            Image(systemName: systemImage)
                .font(.title3.weight(.semibold))
                .frame(width: 28, height: 72)
        }
        .buttonStyle(.borderless)
        .disabled(model.items.count < 2)
        .keyboardShortcut(
            offset < 0 ? .leftArrow : .rightArrow,
            modifiers: []
        )
    }

    @ViewBuilder
    private func clipboardCard(_ item: ClipboardItem) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                contentBadge(item.content)

                Spacer()

                captureMetadata(item)
            }

            switch item.content {
            case let .text(text):
                Text(text.plainText)
                    .font(.body)
                    .lineLimit(10)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            case let .image(image):
                imagePreview(image)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: 240, maxHeight: 240)
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 16))
    }

    private func captureMetadata(_ item: ClipboardItem) -> some View {
        HStack(spacing: 5) {
            if let sourceAppName = item.sourceAppName {
                Text(sourceAppName)
                    .lineLimit(1)

                Text("·")
            }

            Text(item.capturedAt, style: .relative)
                .monospacedDigit()
        }
        .font(.caption2)
        .foregroundStyle(.tertiary)
    }

    private func contentBadge(_ content: ClipboardContent) -> some View {
        Group {
            switch content {
            case .text:
                Label(
                    content.hasRichText
                        ? L10n.text("content.text.rich")
                        : L10n.text("content.text.badge"),
                    systemImage: "text.alignleft"
                )
            case .image:
                Label(L10n.text("content.image"), systemImage: "photo")
            }
        }
        .font(.caption.weight(.semibold))
        .foregroundStyle(.secondary)
    }

    @ViewBuilder
    private func imagePreview(_ image: ClipboardImage) -> some View {
        if let nsImage = NSImage(data: image.data) {
            VStack(spacing: 8) {
                Image(nsImage: nsImage)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: 160)

                Text(ByteCountFormatter.string(
                    fromByteCount: Int64(image.byteCount),
                    countStyle: .file
                ))
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
        } else {
            ContentUnavailableView(
                L10n.text("preview.unavailable"),
                systemImage: "photo"
            )
        }
    }

    private var emptyState: some View {
        ContentUnavailableView(
            model.totalItemCount == 0
                ? L10n.text("clips.empty.title")
                : L10n.text("history.search.empty"),
            systemImage: model.totalItemCount == 0
                ? "clipboard"
                : "magnifyingglass",
            description: Text(
                model.totalItemCount == 0
                    ? L10n.text("clips.empty.description")
                    : L10n.text("history.search.empty_description")
            )
        )
        .frame(height: 260)
    }

    private var footer: some View {
        HStack {
            Button {
                onShowPicker()
            } label: {
                Label(L10n.text("menu.show_picker"), systemImage: "rectangle.stack")
            }

            Spacer()

            Button(role: .destructive) {
                showsClearConfirmation = true
            } label: {
                Image(systemName: "trash.slash")
            }
            .disabled(model.totalItemCount == 0)
            .help(L10n.text("history.clear"))

            Button {
                updater.checkForUpdates()
            } label: {
                Image(systemName: "arrow.triangle.2.circlepath")
            }
            .disabled(!updater.canCheckForUpdates)
            .help(L10n.text("menu.check_updates"))
            .accessibilityLabel(L10n.text("menu.check_updates"))

            SettingsLink {
                Image(systemName: "gearshape")
            }
            .help(L10n.text("menu.settings"))
            .accessibilityLabel(L10n.text("menu.settings"))

            Button(L10n.text("menu.quit")) {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q")
        }
    }

    private func copyAndClose(mode: ClipboardPasteMode) {
        guard model.copySelectedItem(mode: mode) else {
            return
        }

        NSApplication.shared.keyWindow?.orderOut(nil)
    }
}

private extension ClipboardContent {
    var hasRichText: Bool {
        guard case let .text(text) = self else {
            return false
        }
        return text.hasRichText
    }
}
