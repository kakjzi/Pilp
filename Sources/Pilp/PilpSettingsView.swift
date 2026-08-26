import SwiftUI

struct PilpSettingsView: View {
    @ObservedObject var shortcutSettings: ShortcutSettings

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(spacing: 12) {
                Image(systemName: "rectangle.stack.fill")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(.blue)

                VStack(alignment: .leading, spacing: 3) {
                    Text("Open Pilp")
                        .font(.headline)

                    Text("Choose a shortcut that works from any app.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            Divider()

            HStack {
                Text("Global shortcut")

                Spacer()

                ShortcutRecorderView(
                    shortcut: $shortcutSettings.shortcut
                )
            }

            if let registrationError = shortcutSettings.registrationError {
                Label(registrationError, systemImage: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            Text("Pilp does not need Accessibility permission to open the picker. After choosing a clip, press Command-V in the destination app.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(24)
        .frame(width: 440)
    }
}
