import Foundation
import SwiftData

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
        public let sourcePath: String
        public let sourceKey: String
        public let isSourceActive: Bool
        public let sourceReference: String
        public let sourceLastEditedAt: Date?
        public let lastSyncedAt: Date?
        public let lastAIProcessedAt: Date?
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
        public let sourceKey: String
        public let sourceDisplayPath: String
        public let sourceReference: String
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

@MainActor
public struct LearningDataExportService {
    private let context: ModelContext

    public init(context: ModelContext) {
        self.context = context
    }

    public func makePackage(
        exportedAt: Date = .now
    ) throws -> LearningDataExportPackage {
        let sources = try context.fetch(
            FetchDescriptor<SourceDocumentEntity>()
        )
        let knowledge = try context.fetch(
            FetchDescriptor<KnowledgeItemEntity>()
        )
        let cards = try context.fetch(
            FetchDescriptor<FlashcardEntity>()
        )
        let states = try context.fetch(
            FetchDescriptor<ReviewStateEntity>()
        )
        let history = try context.fetch(
            FetchDescriptor<ReviewHistoryEntity>()
        )

        return LearningDataExportPackage(
            schemaVersion: "v1",
            exportedAt: exportedAt,
            sources: sources.map {
                .init(
                    id: $0.id,
                    title: $0.title,
                    content: $0.content,
                    sourceKind: $0.sourceKind,
                    externalSourceID: $0.externalSourceID,
                    sourcePath: $0.sourcePath,
                    sourceKey: $0.sourceKey,
                    isSourceActive: $0.isSourceActive,
                    sourceReference: $0.sourceReference,
                    sourceLastEditedAt: $0.sourceLastEditedAt,
                    lastSyncedAt: $0.lastSyncedAt,
                    lastAIProcessedAt: $0.lastAIProcessedAt,
                    lastAIProviderID: $0.lastAIProviderID,
                    lastAIModelID: $0.lastAIModelID,
                    createdAt: $0.createdAt,
                    updatedAt: $0.updatedAt
                )
            },
            knowledgeItems: knowledge.map {
                .init(
                    id: $0.id,
                    sourceDocumentID: $0.sourceDocumentID,
                    extractionKey: $0.extractionKey,
                    knowledgeType: $0.knowledgeType,
                    title: $0.title,
                    canonicalExpression: $0.canonicalExpression,
                    meaning: $0.meaning,
                    explanation: $0.explanation,
                    naturalEnglish: $0.naturalEnglish,
                    content: $0.content,
                    tags: $0.tags,
                    sourceKey: $0.sourceKey,
                    sourceDisplayPath: $0.sourceDisplayPath,
                    sourceReference: $0.sourceReference,
                    aiProvider: $0.aiProvider,
                    aiModel: $0.aiModel,
                    extractionVersion: $0.extractionVersion,
                    isActive: $0.isActive,
                    createdAt: $0.createdAt,
                    updatedAt: $0.updatedAt
                )
            },
            flashcards: cards.map {
                .init(
                    id: $0.id,
                    knowledgeItemID: $0.knowledgeItemID,
                    sourceDocumentID: $0.sourceDocumentID,
                    generationKey: $0.generationKey,
                    cardType: $0.cardType,
                    prompt: $0.prompt,
                    answer: $0.answer,
                    explanation: $0.explanation,
                    naturalEnglish: $0.naturalEnglish,
                    sourceKey: $0.sourceKey,
                    sourceDisplayPath: $0.sourceDisplayPath,
                    sourceReference: $0.sourceReference,
                    isActive: $0.isActive,
                    createdAt: $0.createdAt,
                    updatedAt: $0.updatedAt
                )
            },
            reviewStates: states.map {
                .init(
                    cardID: $0.cardID,
                    due: $0.due,
                    stability: $0.stability,
                    difficulty: $0.difficulty,
                    elapsedDays: $0.elapsedDays,
                    scheduledDays: $0.scheduledDays,
                    repetitions: $0.repetitions,
                    lapses: $0.lapses,
                    stateRawValue: $0.stateRawValue,
                    lastReview: $0.lastReview
                )
            },
            reviewHistory: history.map {
                .init(
                    id: $0.id,
                    cardID: $0.cardID,
                    reviewedAt: $0.reviewedAt,
                    ratingRawValue: $0.ratingRawValue,
                    elapsedDays: $0.elapsedDays,
                    scheduledDays: $0.scheduledDays,
                    stabilityBefore: $0.stabilityBefore,
                    stabilityAfter: $0.stabilityAfter,
                    difficultyBefore: $0.difficultyBefore,
                    difficultyAfter: $0.difficultyAfter
                )
            }
        )
    }

    public func makeJSONData(
        exportedAt: Date = .now
    ) throws -> Data {
        let package = try makePackage(
            exportedAt: exportedAt
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [
            .prettyPrinted,
            .sortedKeys,
            .withoutEscapingSlashes
        ]
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(package)
    }
}
