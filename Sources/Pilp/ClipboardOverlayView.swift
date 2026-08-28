import AppKit
import PilpCore
import SwiftUI

struct ClipboardOverlayView: View {
    @ObservedObject var model: ClipboardModel
    let onDismiss: () -> Void

    @FocusState private var receivesKeyboardInput: Bool

    var body: some View {
        VStack(spacing: 0) {
            header

            Divider()
                .opacity(0.45)

            if model.items.isEmpty {
                emptyState
            } else {
                ribbon
            }

            Divider()
                .opacity(0.45)

            footer
        }
        .frame(width: 920, height: 340)
        .background {
            FrostedGlassView()
            Color.white.opacity(0.64)
        }
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .strokeBorder(.white.opacity(0.7), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.18), radius: 34, y: 18)
        .focusable()
        .focusEffectDisabled()
        .focused($receivesKeyboardInput)
        .onAppear {
            DispatchQueue.main.async {
                receivesKeyboardInput = true
            }
        }
        .onKeyPress(.leftArrow) {
            DispatchQueue.main.async {
                model.moveSelection(by: -1)
            }
            return .handled
        }
        .onKeyPress(.rightArrow) {
            DispatchQueue.main.async {
                model.moveSelection(by: 1)
            }
            return .handled
        }
        .onKeyPress(.return) {
            copyAndDismiss()
            return .handled
        }
        .onExitCommand(perform: onDismiss)
        .animation(
            .spring(duration: 0.24, bounce: 0.18),
            value: model.selectedPosition
        )
    }

    private var header: some View {
        ZStack {
            Capsule()
                .fill(.black.opacity(0.16))
                .frame(width: 40, height: 5)

            HStack(spacing: 10) {
                Image(systemName: "rectangle.stack.fill")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.black.opacity(0.88))

                Spacer()

                Text(L10n.format(
                    "overlay.position_format",
                    model.selectedPosition,
                    model.items.count
                ))
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.black.opacity(0.52))
            }
        }
        .padding(.horizontal, 28)
        .frame(height: 58)
    }

    private var ribbon: some View {
        HStack(spacing: 14) {
            ForEach(Array(model.ribbonItems.enumerated()), id: \.element.id) {
                position,
                item in
                let isSelected = item.id == model.selectedItem?.id
                let isOuterItem = position == 0
                    || position == model.ribbonItems.count - 1

                ClipboardRibbonCard(
                    item: item,
                    isSelected: isSelected
                )
                .frame(
                    width: isSelected ? 260 : 160,
                    height: isSelected ? 180 : 160
                )
                .scaleEffect(isSelected ? 1 : 0.94)
                .opacity(isSelected ? 1 : (isOuterItem ? 0.48 : 0.82))
                .zIndex(isSelected ? 1 : 0)
                .contentShape(Rectangle())
                .onTapGesture {
                    model.selectItem(id: item.id)
                    receivesKeyboardInput = true
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipped()
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "clipboard")
                .font(.system(size: 30, weight: .medium))
                .foregroundStyle(.black.opacity(0.34))

            Text(L10n.text("overlay.empty.title"))
                .font(.system(size: 18, weight: .semibold))

            Text(L10n.text("overlay.empty.description"))
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var footer: some View {
        ZStack {
            HStack(spacing: 34) {
                ShortcutHint(keys: "← →", label: L10n.text("overlay.move"))
                ShortcutHint(keys: "↵", label: L10n.text("overlay.copy"))
                ShortcutHint(keys: "esc", label: L10n.text("overlay.close"))
            }

            HStack {
                Spacer(minLength: 0)

                Text(L10n.text("overlay.then_paste"))
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.black.opacity(0.42))
            }
        }
        .padding(.horizontal, 28)
        .frame(height: 62)
    }

    private func copyAndDismiss() {
        guard model.copySelectedItem() else {
            return
        }

        onDismiss()
    }
}

private struct ClipboardRibbonCard: View {
    let item: ClipboardItem
    let isSelected: Bool

    var body: some View {
        ZStack(alignment: .topLeading) {
            cardContent

            Text(item.content.badgeTitle)
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .padding(.horizontal, 9)
                .padding(.vertical, 5)
                .background(.black.opacity(0.78), in: Capsule())
                .padding(12)

            VStack {
                Spacer()
                captureMetadata
            }
            .padding(12)
        }
        .background(.white.opacity(0.86))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(
                    isSelected
                        ? Color(red: 0.18, green: 0.58, blue: 1)
                        : .black.opacity(0.1),
                    lineWidth: isSelected ? 4 : 1
                )
        }
        .shadow(
            color: isSelected ? .blue.opacity(0.22) : .black.opacity(0.08),
            radius: isSelected ? 16 : 8,
            y: isSelected ? 7 : 4
        )
    }

    private var captureMetadata: some View {
        HStack(spacing: 5) {
            if let sourceAppName = item.sourceAppName {
                Text(sourceAppName)
                    .lineLimit(1)

                Text("·")
            }

            Text(item.capturedAt, style: .relative)
                .monospacedDigit()
        }
        .font(.system(size: 9, weight: .semibold, design: .rounded))
        .foregroundStyle(.black.opacity(0.62))
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(.ultraThinMaterial, in: Capsule())
        .frame(maxWidth: .infinity, alignment: .trailing)
    }

    @ViewBuilder
    private var cardContent: some View {
        switch item.content {
        case let .text(text):
            Text(text)
                .font(.system(
                    size: isSelected ? 17 : 14,
                    weight: .medium
                ))
                .foregroundStyle(.black.opacity(0.9))
                .lineLimit(isSelected ? 7 : 6)
                .multilineTextAlignment(.leading)
                .frame(
                    maxWidth: .infinity,
                    maxHeight: .infinity,
                    alignment: .center
                )
                .padding(.horizontal, isSelected ? 20 : 16)
                .padding(.top, 26)
                .padding(.bottom, 28)
        case let .image(image):
            if let nsImage = NSImage(data: image.data) {
                Image(nsImage: nsImage)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()
            } else {
                Image(systemName: "photo")
                    .font(.system(size: 28))
                    .foregroundStyle(.secondary)
            }
        }
    }
}

private struct ShortcutHint: View {
    let keys: String
    let label: String

    var body: some View {
        HStack(spacing: 8) {
            HStack(spacing: 2) {
                ForEach(keys.split(separator: " "), id: \.self) { key in
                    Text(String(key))
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(.black.opacity(0.78))
                        .padding(.horizontal, 9)
                        .padding(.vertical, 5)
                        .background(
                            .white.opacity(0.64),
                            in: RoundedRectangle(cornerRadius: 7)
                        )
                        .overlay {
                            RoundedRectangle(cornerRadius: 7)
                                .strokeBorder(.black.opacity(0.09), lineWidth: 1)
                        }
                }
            }

            Text(label)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.black.opacity(0.42))
        }
    }
}

private struct FrostedGlassView: NSViewRepresentable {
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = .popover
        view.blendingMode = .behindWindow
        view.state = .active
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
}

private extension ClipboardContent {
    var badgeTitle: String {
        switch self {
        case .text:
            L10n.text("content.text.badge")
        case .image:
            L10n.text("content.image.badge")
        }
    }
}
