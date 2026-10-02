import XCTest
@testable import MoyashiRecall

final class NotionConfigurationProfileTests: XCTestCase {
    func testLegacyProfileDecodesWithoutSelectedSources() throws {
        let id = UUID()

        let json = """
        {
          "id": "\(id.uuidString)",
          "name": "Legacy Notion",
          "rootPageID": "root-1",
          "rootPageTitle": "Learning Home",
          "credentialAccount": "notion-profile-test"
        }
        """

        let profile = try JSONDecoder().decode(
            NotionConfigurationProfile.self,
            from: Data(json.utf8)
        )

        XCTAssertEqual(profile.id, id)
        XCTAssertEqual(profile.name, "Legacy Notion")
        XCTAssertEqual(profile.rootPageID, "root-1")
        XCTAssertEqual(
            profile.rootPageTitle,
            "Learning Home"
        )
        XCTAssertEqual(profile.selectedSources, [])
        XCTAssertEqual(
            profile.credentialAccount,
            "notion-profile-test"
        )
    }

    func testSelectedSourcesRoundTrip() throws {
        let original = NotionConfigurationProfile(
            name: "Japanese",
            rootPageID: "root",
            rootPageTitle: "Learning Home",
            selectedSources: [
                NotionSelectedSource(
                    id: "page-1",
                    title: "办公室日语学习"
                ),
                NotionSelectedSource(
                    id: "page-2",
                    title: "日语训练营"
                )
            ]
        )

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(
            NotionConfigurationProfile.self,
            from: data
        )

        XCTAssertEqual(decoded, original)
    }

    func testActiveProfileRejectsUnknownID() throws {
        let suite =
            "NotionConfigurationProfileTests-\(UUID().uuidString)"

        guard let defaults = UserDefaults(
            suiteName: suite
        ) else {
            XCTFail("Could not create isolated UserDefaults.")
            return
        }

        defer {
            defaults.removePersistentDomain(
                forName: suite
            )
        }

        let store =
            NotionConfigurationProfileStore(
                defaults: defaults
            )

        let profile =
            NotionConfigurationProfile(
                name: "Test",
                rootPageID: "root"
            )

        try store.save(profile)

        store.setActiveProfile(id: UUID())
        XCTAssertNil(store.activeProfileID())

        store.setActiveProfile(id: profile.id)
        XCTAssertEqual(
            store.activeProfileID(),
            profile.id
        )
        XCTAssertEqual(
            store.activeProfile(),
            profile
        )
    }
}
