import Combine
import Foundation
import PilpCore
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
        AppVersionInfo.displayVersion(
            shortVersion: Bundle.main.object(
                forInfoDictionaryKey: "CFBundleShortVersionString"
            ) as? String,
            buildVersion: Bundle.main.object(
                forInfoDictionaryKey: "CFBundleVersion"
            ) as? String
        )
    }

    func checkForUpdates() {
        controller.checkForUpdates(nil)
    }
}
