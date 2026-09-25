import Foundation
import SwiftData

public enum MoyashiRecallModelContainerFactory {
    public static var schema: Schema {
        Schema(
            versionedSchema: MoyashiRecallSchemaV1.self
        )
    }

    public static func makeDefault() throws -> ModelContainer {
        try ModelContainer(
            for: schema,
            migrationPlan: MoyashiRecallMigrationPlan.self
        )
    }

    public static func make(
        storeURL: URL
    ) throws -> ModelContainer {
        let configuration = ModelConfiguration(
            "MoyashiRecall",
            schema: schema,
            url: storeURL,
            allowsSave: true,
            cloudKitDatabase: .none
        )

        return try ModelContainer(
            for: schema,
            migrationPlan: MoyashiRecallMigrationPlan.self,
            configurations: [
                configuration
            ]
        )
    }
}
