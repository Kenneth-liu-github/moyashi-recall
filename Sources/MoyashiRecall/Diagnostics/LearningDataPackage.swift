import Foundation

public struct LearningDataExportPackage: Codable, Equatable, Sendable {
    public let schemaVersion: String
    public let exportedAt: Date
    public let sources: [SourceRecord]
    public let knowledgeItems: [KnowledgeRecord]
    public let flashcards: [FlashcardRecord]
    public let reviewStates: [ReviewStateRecord]
    public let reviewHistory: [ReviewHistoryRecord]

    public struct SourceRecord: Codable, Equatable, Sendable {
        public let id: UUID
        public let title: String
        public let content: String
        public let sourceKind: String
        public let externalSourceID: String
        public let parentExternalSourceID: String
        public let rootExternalSourceID: String
        public let sourcePath: String
        public let sourceKey: String
        public let hierarchyDepth: Int
        public let isSourceActive: Bool
        public let sourceReference: String
        public let sourceLastEditedAt: Date?
        public let lastSyncedAt: Date?
        public let lastAIProcessedAt: Date?
        public let aiProcessedSourceUpdatedAt: Date?
        public let lastAIExtractionVersion: String
        public let lastAIProviderID: String
        public let lastAIModelID: String
        public let createdAt: Date
        public let updatedAt: Date
    }

    public struct KnowledgeRecord: Codable, Equatable, Sendable {
        public let id: UUID
        public let sourceDocumentID: UUID?
        public let extractionKey: String
        public let knowledgeType: String
        public let title: String
        public let canonicalExpression: String
        public let meaning: String
        public let explanation: String
        public let naturalEnglish: String
        public let content: String
        public let tags: String
        public let sourceKind: String
        public let sourceKey: String
        public let sourceDisplayPath: String
        public let sourceReference: String
        public let externalSourceID: String
        public let parentExternalSourceID: String
        public let rootExternalSourceID: String
        public let sourcePath: String
        public let hierarchyDepth: Int
        public let isSourceActive: Bool
        public let sourceLastEditedAt: Date?
        public let lastSyncedAt: Date?
        public let aiProvider: String
        public let aiModel: String
        public let extractionVersion: String
        public let isActive: Bool
        public let createdAt: Date
        public let updatedAt: Date
    }

    public struct FlashcardRecord: Codable, Equatable, Sendable {
        public let id: UUID
        public let knowledgeItemID: UUID
        public let sourceDocumentID: UUID?
        public let generationKey: String
        public let cardType: String
        public let prompt: String
        public let answer: String
        public let explanation: String
        public let naturalEnglish: String
        public let sourceKey: String
        public let sourceDisplayPath: String
        public let sourceReference: String
        public let isActive: Bool
        public let createdAt: Date
        public let updatedAt: Date
    }

    public struct ReviewStateRecord: Codable, Equatable, Sendable {
        public let cardID: UUID
        public let due: Date
        public let stability: Double
        public let difficulty: Double
        public let elapsedDays: Int
        public let scheduledDays: Int
        public let repetitions: Int
        public let lapses: Int
        public let stateRawValue: String
        public let lastReview: Date?
    }

    public struct ReviewHistoryRecord: Codable, Equatable, Sendable {
        public let id: UUID
        public let cardID: UUID
        public let reviewedAt: Date
        public let ratingRawValue: Int
        public let elapsedDays: Int
        public let scheduledDays: Int
        public let stabilityBefore: Double
        public let stabilityAfter: Double
        public let difficultyBefore: Double
        public let difficultyAfter: Double
    }
}
