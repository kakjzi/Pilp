import Testing
@testable import PilpCore

@Suite("App version presentation")
struct AppVersionInfoTests {
    @Test("shows the release version and build number")
    func showsReleaseVersionAndBuildNumber() {
        #expect(
            AppVersionInfo.displayVersion(
                shortVersion: "0.2.0",
                buildVersion: "2"
            ) == "Version 0.2.0 (2)"
        )
    }

    @Test("uses a clear fallback outside an app bundle")
    func showsDevelopmentBuildFallback() {
        #expect(
            AppVersionInfo.displayVersion(
                shortVersion: nil,
                buildVersion: nil
            ) == "Development build"
        )
    }
}
