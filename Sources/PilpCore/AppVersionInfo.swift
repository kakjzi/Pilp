import Foundation

public enum AppVersionInfo {
    public static func displayVersion(
        shortVersion: String?,
        buildVersion: String?
    ) -> String {
        guard let shortVersion = nonEmpty(shortVersion) else {
            return "Development build"
        }

        guard let buildVersion = nonEmpty(buildVersion) else {
            return "Version \(shortVersion)"
        }

        return "Version \(shortVersion) (\(buildVersion))"
    }

    private static func nonEmpty(_ value: String?) -> String? {
        guard let value else {
            return nil
        }

        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
