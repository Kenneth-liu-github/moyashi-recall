import XCTest
import SwiftData
@testable import MoyashiRecall

final class VersionedSchemaCompatibilityTests: XCTestCase {
    @MainActor
    func testVersionedV1OpensLegacyUnversionedStoreWithoutDataLoss() throws {
        let directory = FileManager.default
            .temporaryDirectory
            .appendingPathComponent(
                UUID().uuidString,
                isDirectory: true
            )
        try FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true
        )
        defer {
            try? FileManager.default.removeItem(
                at: directory
            )
        }

        let storeURL = directory
            .appendingPathComponent("MoyashiRecall.store")
        let configurationName = "MoyashiRecallCompatibility"

        let legacySchema = Schema(
            MoyashiRecallSchemaV1.models
        )
        let legacyConfiguration = ModelConfiguration(
            configurationName,
            schema: legacySchema,
            url: storeURL,
            allowsSave: true,
            cloudKitDatabase: .none
        )

        do {
            let legacyContainer = try ModelContainer(
                for: legacySchema,
                configurations: [
                    legacyConfiguration
                ]
            )
            let context = legacyContainer.mainContext

            let source = SourceDocumentEntity(
                title: "Migration sentinel",
                content: "Preserve me",
                sourceKind: "local-file",
                externalSourceID: "migration-sentinel",
                sourceReference: "migration-sentinel"
            )
            context.insert(source)
            try context.save()

            let before = try context.fetch(
                FetchDescriptor<SourceDocumentEntity>()
            )
            XCTAssertEqual(before.count, 1)
            XCTAssertEqual(
                before.first?.title,
                "Migration sentinel"
            )
        }

        let versionedSchema = Schema(
            versionedSchema: MoyashiRecallSchemaV1.self
        )
        let versionedConfiguration = ModelConfiguration(
            configurationName,
            schema: versionedSchema,
            url: storeURL,
            allowsSave: true,
            cloudKitDatabase: .none
        )

        let versionedContainer = try ModelContainer(
            for: versionedSchema,
            migrationPlan: MoyashiRecallMigrationPlan.self,
            configurations: [
                versionedConfiguration
            ]
        )
        let after = try versionedContainer
            .mainContext
            .fetch(
                FetchDescriptor<SourceDocumentEntity>()
            )

        XCTAssertEqual(after.count, 1)
        XCTAssertEqual(
            after.first?.title,
            "Migration sentinel"
        )
        XCTAssertEqual(
            after.first?.content,
            "Preserve me"
        )
        XCTAssertEqual(
            after.first?.externalSourceID,
            "migration-sentinel"
        )
    }
}
