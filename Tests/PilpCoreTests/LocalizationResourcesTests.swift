import Foundation
import Testing

@Suite("App localization resources")
struct LocalizationResourcesTests {
    @Test("ships matching English and Korean catalogs")
    func shipsMatchingEnglishAndKoreanCatalogs() throws {
        let english = try catalog(for: "en")
        let korean = try catalog(for: "ko")

        #expect(Set(english.keys) == Set(korean.keys))
        #expect(english["settings.title"] == "Pilp Settings")
        #expect(korean["settings.title"] == "Pilp 설정")
        #expect(english["overlay.empty.title"] == "Copy something first")
        #expect(korean["overlay.empty.title"] == "먼저 복사해 보세요")
        #expect(english["shortcut.registration_error"] != nil)
        #expect(korean["shortcut.registration_error"] != nil)
    }

    private func catalog(for language: String) throws -> [String: String] {
        let testFile = URL(fileURLWithPath: #filePath)
        let repositoryRoot = testFile
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let resource = repositoryRoot
            .appendingPathComponent("Support/Localization")
            .appendingPathComponent("\(language).lproj")
            .appendingPathComponent("Localizable.strings")
        let data = try Data(contentsOf: resource)
        let propertyList = try PropertyListSerialization.propertyList(
            from: data,
            options: [],
            format: nil
        )

        guard let catalog = propertyList as? [String: String] else {
            throw LocalizationFixtureError.invalidCatalog(resource)
        }

        return catalog
    }
}

private enum LocalizationFixtureError: Error {
    case invalidCatalog(URL)
}
