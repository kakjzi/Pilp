import Foundation
import Testing

@Suite("App icon resources")
struct AppIconResourcesTests {
    @Test("declares and ships the generated macOS icon")
    func declaresAndShipsGeneratedIcon() throws {
        let repositoryRoot = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let infoPlist = repositoryRoot
            .appendingPathComponent("Support/Info.plist")
        let icon = repositoryRoot
            .appendingPathComponent("Support/Assets/Pilp.icns")
        let master = repositoryRoot
            .appendingPathComponent("Support/Assets/PilpIcon-1024.png")

        let plistData = try Data(contentsOf: infoPlist)
        let plist = try #require(
            PropertyListSerialization.propertyList(
                from: plistData,
                options: [],
                format: nil
            ) as? [String: Any]
        )
        #expect(plist["CFBundleIconFile"] as? String == "Pilp.icns")

        let iconData = try Data(contentsOf: icon)
        #expect(iconData.starts(with: Data("icns".utf8)))

        let masterData = try Data(contentsOf: master)
        #expect(masterData.starts(with: Data([0x89, 0x50, 0x4E, 0x47])))
    }
}
