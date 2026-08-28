import AppKit
import PilpCore
import SwiftUI

struct ClipboardMenuView: View {
    @ObservedObject var model: ClipboardModel
    @ObservedObject var updater: AppUpdater
    let onShowPicker: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header

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
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Pilp")
                    .font(.headline)

                Text("Pick it. Paste it your way.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text("\(model.selectedPosition) / \(model.items.count)")
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
        }
    }

    private func deck(_ item: ClipboardItem) -> some View {
        VStack(spacing: 12) {
            HStack(spacing: 10) {
                navigationButton(systemImage: "chevron.left", offset: -1)

                clipboardCard(item)

                navigationButton(systemImage: "chevron.right", offset: 1)
            }

            Button {
                copyAndClose()
            } label: {
                Label("Copy selected clip", systemImage: "doc.on.doc")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .keyboardShortcut(.return, modifiers: [])
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
                Text(text)
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
                Label("Text", systemImage: "text.alignleft")
            case .image:
                Label("Image", systemImage: "photo")
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
            ContentUnavailableView("Preview unavailable", systemImage: "photo")
        }
    }

    private var emptyState: some View {
        ContentUnavailableView(
            "No clips yet",
            systemImage: "clipboard",
            description: Text("Copy text or an image while Pilp is running.")
        )
        .frame(height: 260)
    }

    private var footer: some View {
        HStack {
            Button {
                onShowPicker()
            } label: {
                Label("Show Picker", systemImage: "rectangle.stack")
            }

            Spacer()

            Button {
                updater.checkForUpdates()
            } label: {
                Image(systemName: "arrow.triangle.2.circlepath")
            }
            .disabled(!updater.canCheckForUpdates)
            .help("Check for Updates")
            .accessibilityLabel("Check for Updates")

            SettingsLink {
                Image(systemName: "gearshape")
            }
            .help("Settings")
            .accessibilityLabel("Settings")

            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q")
        }
    }

    private func copyAndClose() {
        guard model.copySelectedItem() else {
            return
        }

        NSApplication.shared.keyWindow?.orderOut(nil)
    }
}
