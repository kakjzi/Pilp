import Combine
import Foundation
import PilpCore

struct ClipboardSourceApplication: Equatable, Sendable {
    let name: String?
    let bundleIdentifier: String?
}

struct ExcludedApplication: Codable, Equatable, Identifiable, Sendable {
    let bundleIdentifier: String
    let name: String

    var id: String { bundleIdentifier }
}

@MainActor
final class ClipboardPrivacySettings: ObservableObject {
    @Published private(set) var pausedUntil: Date?
    @Published private(set) var excludedApplications: [ExcludedApplication]
    @Published private(set) var now = Date()

    private static let pausedUntilKey = "pilp.privacy.pausedUntil"
    private static let excludedApplicationsKey = "pilp.privacy.excludedApps"
    private static let pauseDuration: TimeInterval = 5 * 60

    private let defaults: UserDefaults
    private var clockTask: Task<Void, Never>?

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.pausedUntil = defaults.object(
            forKey: Self.pausedUntilKey
        ) as? Date
        self.excludedApplications = Self.loadExcludedApplications(
            from: defaults
        )
        removeExpiredPauseIfNeeded()

        clockTask = Task { @MainActor [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                guard !Task.isCancelled else {
                    return
                }
                self?.tick()
            }
        }
    }

    deinit {
        clockTask?.cancel()
    }

    var isPaused: Bool {
        guard let pausedUntil else {
            return false
        }
        return now < pausedUntil
    }

    var remainingPauseSeconds: Int {
        guard let pausedUntil else {
            return 0
        }
        return max(0, Int(ceil(pausedUntil.timeIntervalSince(now))))
    }

    func pauseForFiveMinutes() {
        now = Date()
        pausedUntil = now.addingTimeInterval(Self.pauseDuration)
        defaults.set(pausedUntil, forKey: Self.pausedUntilKey)
    }

    func resume() {
        pausedUntil = nil
        defaults.removeObject(forKey: Self.pausedUntilKey)
    }

    @discardableResult
    func addApplication(at url: URL) -> Bool {
        guard
            let bundle = Bundle(url: url),
            let bundleIdentifier = bundle.bundleIdentifier,
            bundleIdentifier != Bundle.main.bundleIdentifier
        else {
            return false
        }

        let name = bundle.object(
            forInfoDictionaryKey: "CFBundleDisplayName"
        ) as? String
            ?? bundle.object(forInfoDictionaryKey: "CFBundleName") as? String
            ?? url.deletingPathExtension().lastPathComponent
        let application = ExcludedApplication(
            bundleIdentifier: bundleIdentifier,
            name: name
        )

        excludedApplications.removeAll {
            $0.bundleIdentifier == bundleIdentifier
        }
        excludedApplications.append(application)
        excludedApplications.sort {
            $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
        }
        persistExcludedApplications()
        return true
    }

    func removeApplication(id: String) {
        excludedApplications.removeAll { $0.id == id }
        persistExcludedApplications()
    }

    func allowsCapture(from source: ClipboardSourceApplication?) -> Bool {
        ClipboardCapturePolicy.allowsCapture(
            now: Date(),
            pausedUntil: pausedUntil,
            sourceAppBundleIdentifier: source?.bundleIdentifier,
            excludedBundleIdentifiers: Set(
                excludedApplications.map(\.bundleIdentifier)
            )
        )
    }

    private func tick() {
        now = Date()
        removeExpiredPauseIfNeeded()
    }

    private func removeExpiredPauseIfNeeded() {
        guard let pausedUntil, pausedUntil <= Date() else {
            return
        }
        self.pausedUntil = nil
        defaults.removeObject(forKey: Self.pausedUntilKey)
    }

    private func persistExcludedApplications() {
        guard let data = try? JSONEncoder().encode(excludedApplications) else {
            return
        }
        defaults.set(data, forKey: Self.excludedApplicationsKey)
    }

    private static func loadExcludedApplications(
        from defaults: UserDefaults
    ) -> [ExcludedApplication] {
        guard
            let data = defaults.data(forKey: excludedApplicationsKey),
            let applications = try? JSONDecoder().decode(
                [ExcludedApplication].self,
                from: data
            )
        else {
            return []
        }
        return applications
    }
}
