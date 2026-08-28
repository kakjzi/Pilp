import SwiftUI

struct PilpSettingsView: View {
    @ObservedObject var shortcutSettings: ShortcutSettings
    @ObservedObject var updater: AppUpdater

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            title
            gettingStartedSection
            Divider()
            shortcutSection
            Divider()
            updatesSection
            Divider()
            privacyNote
        }
        .padding(24)
        .frame(width: 480)
    }

    private var gettingStartedSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            SettingsSectionHeader(
                title: "Get started",
                description: "Three quick steps, entirely from the keyboard."
            )

            HStack(alignment: .top, spacing: 20) {
                OnboardingStep(
                    number: 1,
                    title: "Copy",
                    detail: "Copy text or an image normally."
                )
                OnboardingStep(
                    number: 2,
                    title: "Pick",
                    detail: "Open Pilp and move with ← →."
                )
                OnboardingStep(
                    number: 3,
                    title: "Paste",
                    detail: "Press Return, then ⌘V."
                )
            }
        }
    }

    private var title: some View {
        HStack(spacing: 12) {
            Image(systemName: "rectangle.stack.fill")
                .font(.system(size: 26, weight: .semibold))
                .foregroundStyle(.blue)

            VStack(alignment: .leading, spacing: 2) {
                Text("Pilp Settings")
                    .font(.title3.weight(.semibold))

                Text(updater.currentVersionDescription)
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var shortcutSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            SettingsSectionHeader(
                title: "Picker shortcut",
                description: "Open Pilp from any app."
            )

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
        }
    }

    private var updatesSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            SettingsSectionHeader(
                title: "Updates",
                description: "Stay current without downloading Pilp again by hand."
            )

            Toggle(
                "Automatically check for updates",
                isOn: Binding(
                    get: { updater.automaticallyChecksForUpdates },
                    set: { updater.automaticallyChecksForUpdates = $0 }
                )
            )

            Toggle(
                "Download updates automatically",
                isOn: Binding(
                    get: { updater.automaticallyDownloadsUpdates },
                    set: { updater.automaticallyDownloadsUpdates = $0 }
                )
            )
            .disabled(!updater.allowsAutomaticUpdates)

            HStack {
                Text("Downloaded updates are verified before installation.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                Button("Check Now") {
                    updater.checkForUpdates()
                }
                .disabled(!updater.canCheckForUpdates)
                .help("Check GitHub Releases for a newer version of Pilp")
            }
        }
    }

    private var privacyNote: some View {
        Label {
            Text("Clipboard history stays in memory on this Mac and clears when Pilp quits. Update checks only contact the Pilp release feed.")
        } icon: {
            Image(systemName: "lock.shield")
        }
        .font(.caption)
        .foregroundStyle(.secondary)
        .fixedSize(horizontal: false, vertical: true)
    }
}

private struct OnboardingStep: View {
    let number: Int
    let title: String
    let detail: String

    var body: some View {
        HStack(alignment: .top, spacing: 9) {
            Text("\(number)")
                .font(.caption.bold())
                .foregroundStyle(.white)
                .frame(width: 22, height: 22)
                .background(.blue, in: Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))

                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct SettingsSectionHeader: View {
    let title: String
    let description: String

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.headline)

            Text(description)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}
