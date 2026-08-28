import Combine
import Foundation
import Sparkle

@MainActor
final class AppUpdater: ObservableObject {
    let controller: SPUStandardUpdaterController

    @Published private(set) var canCheckForUpdates = false

    init(startingUpdater: Bool = true) {
        controller = SPUStandardUpdaterController(
            startingUpdater: startingUpdater,
            updaterDelegate: nil,
            userDriverDelegate: nil
        )

        controller.updater.publisher(for: \.canCheckForUpdates)
            .assign(to: &$canCheckForUpdates)
    }

    var automaticallyChecksForUpdates: Bool {
        get { controller.updater.automaticallyChecksForUpdates }
        set {
            objectWillChange.send()
            controller.updater.automaticallyChecksForUpdates = newValue
        }
    }

    var automaticallyDownloadsUpdates: Bool {
        get { controller.updater.automaticallyDownloadsUpdates }
        set {
            objectWillChange.send()
            controller.updater.automaticallyDownloadsUpdates = newValue
        }
    }

    var allowsAutomaticUpdates: Bool {
        controller.updater.allowsAutomaticUpdates
    }

    var currentVersionDescription: String {
        guard let shortVersion = nonEmptyBundleValue(
            forInfoDictionaryKey: "CFBundleShortVersionString"
        ) else {
            return L10n.text("version.development")
        }

        guard let buildVersion = nonEmptyBundleValue(
            forInfoDictionaryKey: "CFBundleVersion"
        ) else {
            return L10n.format("version.short_format", shortVersion)
        }

        return L10n.format(
            "version.full_format",
            shortVersion,
            buildVersion
        )
    }

    func checkForUpdates() {
        controller.checkForUpdates(nil)
    }

    private func nonEmptyBundleValue(
        forInfoDictionaryKey key: String
    ) -> String? {
        guard let value = Bundle.main.object(
            forInfoDictionaryKey: key
        ) as? String else {
            return nil
        }

        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
