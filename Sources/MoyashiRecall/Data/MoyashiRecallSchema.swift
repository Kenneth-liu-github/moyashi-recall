import SwiftData

public enum MoyashiRecallSchemaV1: VersionedSchema {
    public static var versionIdentifier: Schema.Version {
        Schema.Version(1, 0, 0)
    }

    public static var models: [any PersistentModel.Type] {
        [
            SourceDocumentEntity.self,
            KnowledgeItemEntity.self,
            FlashcardEntity.self,
            ReviewStateEntity.self,
            ReviewHistoryEntity.self
        ]
    }
}

public enum MoyashiRecallMigrationPlan: SchemaMigrationPlan {
    public static var schemas: [any VersionedSchema.Type] {
        [
            MoyashiRecallSchemaV1.self
        ]
    }

    public static var stages: [MigrationStage] {
        []
    }
}
