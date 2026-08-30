import AppKit
import SwiftUI
import UniformTypeIdentifiers

struct PilpSettingsView: View {
    @ObservedObject var commandVSettings: CommandVHoldSettings
    @ObservedObject var shortcutSettings: ShortcutSettings
    @ObservedObject var privacySettings: ClipboardPrivacySettings
    @ObservedObject var launchAtLoginSettings: LaunchAtLoginSettings
    @ObservedObject var updater: AppUpdater

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                title
                gettingStartedSection
                Divider()
                shortcutSection
                Divider()
                generalSection
                Divider()
                privacySection
                Divider()
                updatesSection
                Divider()
                privacyNote
            }
            .padding(24)
        }
        .frame(width: 560, height: 720)
    }

    private var gettingStartedSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            SettingsSectionHeader(
                title: L10n.text("settings.get_started.title"),
                description: L10n.text("settings.get_started.description")
            )

            HStack(alignment: .top, spacing: 20) {
                OnboardingStep(
                    number: 1,
                    title: L10n.text("settings.step.copy.title"),
                    detail: L10n.text("settings.step.copy.detail")
                )
                OnboardingStep(
                    number: 2,
                    title: L10n.text("settings.step.pick.title"),
                    detail: L10n.text("settings.step.pick.detail")
                )
                OnboardingStep(
                    number: 3,
                    title: L10n.text("settings.step.paste.title"),
                    detail: L10n.text("settings.step.paste.detail")
                )
            }
        }
    }

    private var title: some View {
        HStack(spacing: 12) {
            Image(nsImage: NSApplication.shared.applicationIconImage)
                .resizable()
                .interpolation(.high)
                .frame(width: 38, height: 38)

            VStack(alignment: .leading, spacing: 2) {
                Text(L10n.text("settings.title"))
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
                title: L10n.text("settings.picker_controls.title"),
                description: L10n.text("settings.picker_controls.description")
            )

            Toggle(
                L10n.text("settings.command_v.toggle"),
                isOn: $commandVSettings.isEnabled
            )

            if commandVSettings.isEnabled,
                !commandVSettings.isAccessibilityGranted
            {
                HStack(alignment: .top, spacing: 10) {
                    Label(
                        L10n.text("settings.command_v.permission"),
                        systemImage: "hand.raised.fill"
                    )
                    .font(.caption)
                    .foregroundStyle(.orange)
                    .fixedSize(horizontal: false, vertical: true)

                    Spacer()

                    Button(L10n.text("settings.command_v.allow")) {
                        commandVSettings.requestAccessibilityPermission()
                    }
                }
            }

            if let activationError = commandVSettings.activationError {
                Label(
                    activationError,
                    systemImage: "exclamationmark.triangle.fill"
                )
                .font(.caption)
                .foregroundStyle(.red)
            }

            HStack {
                Text(L10n.text("settings.shortcut.custom"))

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
                title: L10n.text("settings.updates.title"),
                description: L10n.text("settings.updates.description")
            )

            Toggle(
                L10n.text("settings.updates.auto_check"),
                isOn: Binding(
                    get: { updater.automaticallyChecksForUpdates },
                    set: { updater.automaticallyChecksForUpdates = $0 }
                )
            )

            Toggle(
                L10n.text("settings.updates.auto_download"),
                isOn: Binding(
                    get: { updater.automaticallyDownloadsUpdates },
                    set: { updater.automaticallyDownloadsUpdates = $0 }
                )
            )
            .disabled(!updater.allowsAutomaticUpdates)

            HStack {
                Text(L10n.text("settings.updates.verified"))
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                Button(L10n.text("settings.updates.check_now")) {
                    updater.checkForUpdates()
                }
                .disabled(!updater.canCheckForUpdates)
                .help(L10n.text("settings.updates.check_help"))
            }
        }
    }

    private var generalSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            SettingsSectionHeader(
                title: L10n.text("settings.general.title"),
                description: L10n.text("settings.general.description")
            )

            Toggle(
                L10n.text("settings.launch_at_login"),
                isOn: Binding(
                    get: { launchAtLoginSettings.isEnabled },
                    set: { launchAtLoginSettings.setEnabled($0) }
                )
            )

            if let errorMessage = launchAtLoginSettings.errorMessage {
                Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
    }

    private var privacySection: some View {
        VStack(alignment: .leading, spacing: 14) {
            SettingsSectionHeader(
                title: L10n.text("settings.privacy.title"),
                description: L10n.text("settings.privacy.description")
            )

            HStack {
                Label(
                    privacySettings.isPaused
                        ? L10n.format(
                            "privacy.paused_countdown",
                            privacySettings.remainingPauseSeconds
                        )
                        : L10n.text("privacy.capture_active"),
                    systemImage: privacySettings.isPaused
                        ? "pause.circle.fill"
                        : "checkmark.shield.fill"
                )
                .foregroundStyle(privacySettings.isPaused ? .orange : .green)

                Spacer()

                Button(
                    privacySettings.isPaused
                        ? L10n.text("privacy.resume")
                        : L10n.text("privacy.pause_five_minutes")
                ) {
                    if privacySettings.isPaused {
                        privacySettings.resume()
                    } else {
                        privacySettings.pauseForFiveMinutes()
                    }
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(L10n.text("privacy.excluded_apps"))
                        .font(.subheadline.weight(.semibold))

                    Spacer()

                    Button(L10n.text("privacy.add_app")) {
                        chooseExcludedApplication()
                    }
                }

                if privacySettings.excludedApplications.isEmpty {
                    Text(L10n.text("privacy.no_excluded_apps"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(privacySettings.excludedApplications) { application in
                        HStack {
                            Image(systemName: "app.dashed")
                                .foregroundStyle(.secondary)

                            VStack(alignment: .leading, spacing: 1) {
                                Text(application.name)
                                Text(application.bundleIdentifier)
                                    .font(.caption2.monospaced())
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            Button(role: .destructive) {
                                privacySettings.removeApplication(
                                    id: application.id
                                )
                            } label: {
                                Image(systemName: "minus.circle.fill")
                            }
                            .buttonStyle(.borderless)
                        }
                        .padding(.vertical, 3)
                    }
                }
            }
            .padding(12)
            .background(.quaternary, in: RoundedRectangle(cornerRadius: 12))
        }
    }

    private var privacyNote: some View {
        Label {
            Text(L10n.text("settings.privacy"))
        } icon: {
            Image(systemName: "lock.shield")
        }
        .font(.caption)
        .foregroundStyle(.secondary)
        .fixedSize(horizontal: false, vertical: true)
    }

    private func chooseExcludedApplication() {
        let panel = NSOpenPanel()
        panel.title = L10n.text("privacy.choose_app")
        panel.prompt = L10n.text("privacy.exclude")
        panel.directoryURL = URL(fileURLWithPath: "/Applications")
        panel.allowedContentTypes = [.applicationBundle]
        panel.allowsMultipleSelection = false
        panel.canChooseFiles = true
        panel.canChooseDirectories = false

        panel.begin { response in
            guard response == .OK, let url = panel.url else {
                return
            }
            _ = privacySettings.addApplication(at: url)
        }
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
