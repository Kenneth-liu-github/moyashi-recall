import Foundation
import SwiftData

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
            FetchDescriptor<SourceDocumentEntity>(
                sortBy: [
                    SortDescriptor(
                        \.sourcePath,
                        order: .forward
                    )
                ]
            )
        )
        let knowledge = try context.fetch(
            FetchDescriptor<KnowledgeItemEntity>(
                sortBy: [
                    SortDescriptor(
                        \.createdAt,
                        order: .forward
                    )
                ]
            )
        )
        let cards = try context.fetch(
            FetchDescriptor<FlashcardEntity>(
                sortBy: [
                    SortDescriptor(
                        \.createdAt,
                        order: .forward
                    )
                ]
            )
        )
        let states = try context.fetch(
            FetchDescriptor<ReviewStateEntity>(
                sortBy: [
                    SortDescriptor(
                        \.due,
                        order: .forward
                    )
                ]
            )
        )
        let history = try context.fetch(
            FetchDescriptor<ReviewHistoryEntity>(
                sortBy: [
                    SortDescriptor(
                        \.reviewedAt,
                        order: .forward
                    )
                ]
            )
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
                    parentExternalSourceID: $0.parentExternalSourceID,
                    rootExternalSourceID: $0.rootExternalSourceID,
                    sourcePath: $0.sourcePath,
                    sourceKey: $0.sourceKey,
                    hierarchyDepth: $0.hierarchyDepth,
                    isSourceActive: $0.isSourceActive,
                    sourceReference: $0.sourceReference,
                    sourceLastEditedAt: $0.sourceLastEditedAt,
                    lastSyncedAt: $0.lastSyncedAt,
                    lastAIProcessedAt: $0.lastAIProcessedAt,
                    aiProcessedSourceUpdatedAt: $0.aiProcessedSourceUpdatedAt,
                    lastAIExtractionVersion: $0.lastAIExtractionVersion,
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
                    sourceKind: $0.sourceKind,
                    sourceKey: $0.sourceKey,
                    sourceDisplayPath: $0.sourceDisplayPath,
                    sourceReference: $0.sourceReference,
                    externalSourceID: $0.externalSourceID,
                    parentExternalSourceID: $0.parentExternalSourceID,
                    rootExternalSourceID: $0.rootExternalSourceID,
                    sourcePath: $0.sourcePath,
                    hierarchyDepth: $0.hierarchyDepth,
                    isSourceActive: $0.isSourceActive,
                    sourceLastEditedAt: $0.sourceLastEditedAt,
                    lastSyncedAt: $0.lastSyncedAt,
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
