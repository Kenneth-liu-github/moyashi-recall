import XCTest
@testable import MoyashiRecall

final class StudyPresetStoreTests: XCTestCase {
    func testPresetCreateUpdateAndDelete() throws {
        let suiteName = "StudyPresetStoreTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(
            UserDefaults(suiteName: suiteName)
        )
        defer {
            defaults.removePersistentDomain(
                forName: suiteName
            )
        }

        let store = StudyPresetStore()
        let createdAt = Date(
            timeIntervalSince1970: 1_700_000_000
        )
        let created = try store.save(
            name: "办公室日语",
            sourceKeys: ["office-japanese"],
            cardTypes: [
                ReviewCardType.zhToJa.rawValue
            ],
            reviewCount: 20,
            now: createdAt,
            defaults: defaults
        )

        XCTAssertEqual(
            store.load(defaults: defaults).count,
            1
        )

        let updatedAt = createdAt.addingTimeInterval(60)
        let updated = try store.save(
            name: "办公室日语",
            sourceKeys: [
                "office-japanese",
                "japanese-bootcamp"
            ],
            cardTypes: [
                ReviewCardType.application.rawValue
            ],
            reviewCount: 30,
            now: updatedAt,
            defaults: defaults
        )

        XCTAssertEqual(created.id, updated.id)
        XCTAssertEqual(created.createdAt, updated.createdAt)
        XCTAssertEqual(updated.updatedAt, updatedAt)
        XCTAssertEqual(updated.reviewCount, 30)
        XCTAssertEqual(
            updated.sourceKeys,
            [
                "office-japanese",
                "japanese-bootcamp"
            ]
        )

        try store.delete(
            id: updated.id,
            defaults: defaults
        )
        XCTAssertTrue(
            store.load(defaults: defaults).isEmpty
        )
    }

    func testPresetNamesAreTrimmedAndCaseInsensitiveForUpdate() throws {
        let suiteName = "StudyPresetStoreTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(
            UserDefaults(suiteName: suiteName)
        )
        defer {
            defaults.removePersistentDomain(
                forName: suiteName
            )
        }

        let store = StudyPresetStore()
        let first = try store.save(
            name: "  Grammar  ",
            sourceKeys: ["a"],
            cardTypes: ["cloze"],
            reviewCount: 10,
            defaults: defaults
        )
        let second = try store.save(
            name: "grammar",
            sourceKeys: ["b"],
            cardTypes: ["application"],
            reviewCount: 20,
            defaults: defaults
        )

        XCTAssertEqual(first.id, second.id)
        XCTAssertEqual(
            store.load(defaults: defaults).count,
            1
        )
        XCTAssertEqual(second.name, "grammar")
    }

    func testEmptyPresetNameIsRejected() throws {
        let suiteName = "StudyPresetStoreTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(
            UserDefaults(suiteName: suiteName)
        )
        defer {
            defaults.removePersistentDomain(
                forName: suiteName
            )
        }

        XCTAssertThrowsError(
            try StudyPresetStore().save(
                name: "   ",
                sourceKeys: [],
                cardTypes: [],
                reviewCount: 20,
                defaults: defaults
            )
        ) { error in
            XCTAssertEqual(
                error as? StudyPresetStoreError,
                .emptyName
            )
        }
    }
    func testPresetPersistsDocumentIDs() throws {
        let suiteName = "StudyPresetDocumentIDs.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(
            UserDefaults(suiteName: suiteName)
        )
        defer {
            defaults.removePersistentDomain(
                forName: suiteName
            )
        }

        let first = UUID()
        let second = UUID()
        let saved = try StudyPresetStore().save(
            name: "第二课",
            sourceKeys: ["office-japanese"],
            cardTypes: [
                ReviewCardType.zhToJa.rawValue
            ],
            documentIDs: [first, second],
            reviewCount: 20,
            defaults: defaults
        )

        XCTAssertEqual(
            saved.documentIDs,
            [first, second]
        )
        XCTAssertEqual(
            StudyPresetStore()
                .load(defaults: defaults)
                .first?
                .documentIDs,
            [first, second]
        )
    }

    func testLegacyPresetWithoutDocumentIDsStillDecodes() throws {
        struct LegacyPreset: Codable {
            let id: UUID
            let name: String
            let sourceKeys: Set<String>
            let cardTypes: Set<String>
            let reviewCount: Int
            let createdAt: Date
            let updatedAt: Date
        }

        let suiteName = "StudyPresetLegacy.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(
            UserDefaults(suiteName: suiteName)
        )
        defer {
            defaults.removePersistentDomain(
                forName: suiteName
            )
        }

        let legacy = LegacyPreset(
            id: UUID(),
            name: "旧方案",
            sourceKeys: ["office-japanese"],
            cardTypes: [
                ReviewCardType.application.rawValue
            ],
            reviewCount: 10,
            createdAt: Date(
                timeIntervalSince1970: 1_700_000_000
            ),
            updatedAt: Date(
                timeIntervalSince1970: 1_700_000_100
            )
        )

        defaults.set(
            try JSONEncoder().encode([legacy]),
            forKey: "savedStudyPresets"
        )

        let loaded = try XCTUnwrap(
            StudyPresetStore()
                .load(defaults: defaults)
                .first
        )

        XCTAssertEqual(loaded.name, "旧方案")
        XCTAssertNil(loaded.documentIDs)
    }


    func testPresetSupportsAllDueCount() throws {
        let suiteName = "StudyPresetAllDue.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(
            UserDefaults(suiteName: suiteName)
        )
        defer {
            defaults.removePersistentDomain(
                forName: suiteName
            )
        }

        let preset = try StudyPresetStore().save(
            name: "全部到期",
            sourceKeys: ["office-japanese"],
            cardTypes: [
                ReviewCardType.zhToJa.rawValue
            ],
            reviewCount: 0,
            defaults: defaults
        )

        XCTAssertEqual(preset.reviewCount, 0)
    }


}
