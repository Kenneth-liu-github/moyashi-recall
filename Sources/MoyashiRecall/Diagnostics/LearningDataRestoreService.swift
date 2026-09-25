import Foundation
import SwiftData

public struct RestoreMutationCounts: Equatable, Sendable {
    public let inserted: Int
    public let updated: Int
    public let unchanged: Int

    public init(
        inserted: Int = 0,
        updated: Int = 0,
        unchanged: Int = 0
    ) {
        self.inserted = inserted
        self.updated = updated
        self.unchanged = unchanged
    }
}

public struct LearningDataRestoreReport: Equatable, Sendable {
    public let sources: RestoreMutationCounts
    public let knowledgeItems: RestoreMutationCounts
    public let flashcards: RestoreMutationCounts
    public let reviewStates: RestoreMutationCounts
    public let reviewHistory: RestoreMutationCounts

    public var insertedTotal: Int {
        sources.inserted
            + knowledgeItems.inserted
            + flashcards.inserted
            + reviewStates.inserted
            + reviewHistory.inserted
    }

    public var updatedTotal: Int {
        sources.updated
            + knowledgeItems.updated
            + flashcards.updated
            + reviewStates.updated
            + reviewHistory.updated
    }

    public init(
        sources: RestoreMutationCounts,
        knowledgeItems: RestoreMutationCounts,
        flashcards: RestoreMutationCounts,
        reviewStates: RestoreMutationCounts,
        reviewHistory: RestoreMutationCounts
    ) {
        self.sources = sources
        self.knowledgeItems = knowledgeItems
        self.flashcards = flashcards
        self.reviewStates = reviewStates
        self.reviewHistory = reviewHistory
    }
}

@MainActor
public struct LearningDataRestoreService {
    private let context: ModelContext

    public init(context: ModelContext) {
        self.context = context
    }

    public func restore(
        data: Data
    ) throws -> LearningDataRestoreReport {
        let validated = try LearningDataImportValidator
            .decodeAndValidate(data)
        return try restore(
            package: validated.package
        )
    }

    public func restore(
        package: LearningDataExportPackage
    ) throws -> LearningDataRestoreReport {
        _ = try LearningDataImportValidator.validate(
            package
        )

        do {
            let report = try mergeValidatedPackage(
                package
            )
            try context.save()
            return report
        } catch {
            context.rollback()
            throw error
        }
    }

    private func mergeValidatedPackage(
        _ package: LearningDataExportPackage
    ) throws -> LearningDataRestoreReport {
        var sourceCounts = MutableCounts()
        var knowledgeCounts = MutableCounts()
        var cardCounts = MutableCounts()
        var stateCounts = MutableCounts()
        var historyCounts = MutableCounts()

        let localSources = try context.fetch(
            FetchDescriptor<SourceDocumentEntity>()
        )
        var sourceByID = Dictionary(
            uniqueKeysWithValues: localSources.map {
                ($0.id, $0)
            }
        )

        for record in package.sources {
            if let existing = sourceByID[record.id] {
                if record.updatedAt > existing.updatedAt {
                    apply(record, to: existing)
                    sourceCounts.updated += 1
                } else {
                    sourceCounts.unchanged += 1
                }
            } else {
                let entity = makeSource(record)
                context.insert(entity)
                sourceByID[record.id] = entity
                sourceCounts.inserted += 1
            }
        }

        let localKnowledge = try context.fetch(
            FetchDescriptor<KnowledgeItemEntity>()
        )
        var knowledgeByID = Dictionary(
            uniqueKeysWithValues: localKnowledge.map {
                ($0.id, $0)
            }
        )

        for record in package.knowledgeItems {
            if let existing = knowledgeByID[record.id] {
                if record.updatedAt > existing.updatedAt {
                    apply(record, to: existing)
                    knowledgeCounts.updated += 1
                } else {
                    knowledgeCounts.unchanged += 1
                }
            } else {
                let entity = makeKnowledge(record)
                context.insert(entity)
                knowledgeByID[record.id] = entity
                knowledgeCounts.inserted += 1
            }
        }

        let localCards = try context.fetch(
            FetchDescriptor<FlashcardEntity>()
        )
        var cardByID = Dictionary(
            uniqueKeysWithValues: localCards.map {
                ($0.id, $0)
            }
        )

        for record in package.flashcards {
            if let existing = cardByID[record.id] {
                if record.updatedAt > existing.updatedAt {
                    apply(record, to: existing)
                    cardCounts.updated += 1
                } else {
                    cardCounts.unchanged += 1
                }
            } else {
                let entity = makeFlashcard(record)
                context.insert(entity)
                cardByID[record.id] = entity
                cardCounts.inserted += 1
            }
        }

        let localStates = try context.fetch(
            FetchDescriptor<ReviewStateEntity>()
        )
        var stateByCardID = Dictionary(
            uniqueKeysWithValues: localStates.map {
                ($0.cardID, $0)
            }
        )

        for record in package.reviewStates {
            if let existing = stateByCardID[record.cardID] {
                if shouldUpdate(
                    existing: existing,
                    from: record
                ) {
                    apply(record, to: existing)
                    stateCounts.updated += 1
                } else {
                    stateCounts.unchanged += 1
                }
            } else {
                let entity = makeReviewState(record)
                context.insert(entity)
                stateByCardID[record.cardID] = entity
                stateCounts.inserted += 1
            }
        }

        let localHistory = try context.fetch(
            FetchDescriptor<ReviewHistoryEntity>()
        )
        var historyIDs = Set(
            localHistory.map(\.id)
        )

        for record in package.reviewHistory {
            if historyIDs.contains(record.id) {
                historyCounts.unchanged += 1
            } else {
                context.insert(
                    makeReviewHistory(record)
                )
                historyIDs.insert(record.id)
                historyCounts.inserted += 1
            }
        }

        return LearningDataRestoreReport(
            sources: sourceCounts.snapshot,
            knowledgeItems: knowledgeCounts.snapshot,
            flashcards: cardCounts.snapshot,
            reviewStates: stateCounts.snapshot,
            reviewHistory: historyCounts.snapshot
        )
    }

    private func shouldUpdate(
        existing: ReviewStateEntity,
        from record: LearningDataExportPackage.ReviewStateRecord
    ) -> Bool {
        let localReview = existing.lastReview ?? .distantPast
        let backupReview = record.lastReview ?? .distantPast

        if backupReview != localReview {
            return backupReview > localReview
        }

        if record.repetitions != existing.repetitions {
            return record.repetitions > existing.repetitions
        }

        if record.lapses != existing.lapses {
            return record.lapses > existing.lapses
        }

        return false
    }

    private func makeSource(
        _ record: LearningDataExportPackage.SourceRecord
    ) -> SourceDocumentEntity {
        SourceDocumentEntity(
            id: record.id,
            title: record.title,
            content: record.content,
            sourceKind: record.sourceKind,
            externalSourceID: record.externalSourceID,
            parentExternalSourceID: record.parentExternalSourceID,
            rootExternalSourceID: record.rootExternalSourceID,
            sourcePath: record.sourcePath,
            sourceKey: record.sourceKey,
            hierarchyDepth: record.hierarchyDepth,
            isSourceActive: record.isSourceActive,
            sourceLastEditedAt: record.sourceLastEditedAt,
            lastSyncedAt: record.lastSyncedAt,
            lastAIProcessedAt: record.lastAIProcessedAt,
            aiProcessedSourceUpdatedAt: record.aiProcessedSourceUpdatedAt,
            lastAIExtractionVersion: record.lastAIExtractionVersion,
            lastAIProviderID: record.lastAIProviderID,
            lastAIModelID: record.lastAIModelID,
            sourceReference: record.sourceReference,
            createdAt: record.createdAt,
            updatedAt: record.updatedAt
        )
    }

    private func apply(
        _ record: LearningDataExportPackage.SourceRecord,
        to entity: SourceDocumentEntity
    ) {
        entity.title = record.title
        entity.content = record.content
        entity.sourceKind = record.sourceKind
        entity.externalSourceID = record.externalSourceID
        entity.parentExternalSourceID = record.parentExternalSourceID
        entity.rootExternalSourceID = record.rootExternalSourceID
        entity.sourcePath = record.sourcePath
        entity.sourceKey = record.sourceKey
        entity.hierarchyDepth = record.hierarchyDepth
        entity.isSourceActive = record.isSourceActive
        entity.sourceLastEditedAt = record.sourceLastEditedAt
        entity.lastSyncedAt = record.lastSyncedAt
        entity.lastAIProcessedAt = record.lastAIProcessedAt
        entity.aiProcessedSourceUpdatedAt =
            record.aiProcessedSourceUpdatedAt
        entity.lastAIExtractionVersion =
            record.lastAIExtractionVersion
        entity.lastAIProviderID = record.lastAIProviderID
        entity.lastAIModelID = record.lastAIModelID
        entity.sourceReference = record.sourceReference
        entity.createdAt = record.createdAt
        entity.updatedAt = record.updatedAt
    }

    private func makeKnowledge(
        _ record: LearningDataExportPackage.KnowledgeRecord
    ) -> KnowledgeItemEntity {
        KnowledgeItemEntity(
            id: record.id,
            sourceDocumentID: record.sourceDocumentID,
            extractionKey: record.extractionKey,
            knowledgeType: record.knowledgeType,
            title: record.title,
            canonicalExpression: record.canonicalExpression,
            meaning: record.meaning,
            explanation: record.explanation,
            naturalEnglish: record.naturalEnglish,
            content: record.content,
            tags: record.tags,
            sourceKind: record.sourceKind,
            sourceKey: record.sourceKey,
            sourceDisplayPath: record.sourceDisplayPath,
            sourceReference: record.sourceReference,
            externalSourceID: record.externalSourceID,
            parentExternalSourceID: record.parentExternalSourceID,
            rootExternalSourceID: record.rootExternalSourceID,
            sourcePath: record.sourcePath,
            hierarchyDepth: record.hierarchyDepth,
            isSourceActive: record.isSourceActive,
            sourceLastEditedAt: record.sourceLastEditedAt,
            lastSyncedAt: record.lastSyncedAt,
            aiProvider: record.aiProvider,
            aiModel: record.aiModel,
            extractionVersion: record.extractionVersion,
            isActive: record.isActive,
            createdAt: record.createdAt,
            updatedAt: record.updatedAt
        )
    }

    private func apply(
        _ record: LearningDataExportPackage.KnowledgeRecord,
        to entity: KnowledgeItemEntity
    ) {
        entity.sourceDocumentID = record.sourceDocumentID
        entity.extractionKey = record.extractionKey
        entity.knowledgeType = record.knowledgeType
        entity.title = record.title
        entity.canonicalExpression = record.canonicalExpression
        entity.meaning = record.meaning
        entity.explanation = record.explanation
        entity.naturalEnglish = record.naturalEnglish
        entity.content = record.content
        entity.tags = record.tags
        entity.sourceKind = record.sourceKind
        entity.sourceKey = record.sourceKey
        entity.sourceDisplayPath = record.sourceDisplayPath
        entity.sourceReference = record.sourceReference
        entity.externalSourceID = record.externalSourceID
        entity.parentExternalSourceID = record.parentExternalSourceID
        entity.rootExternalSourceID = record.rootExternalSourceID
        entity.sourcePath = record.sourcePath
        entity.hierarchyDepth = record.hierarchyDepth
        entity.isSourceActive = record.isSourceActive
        entity.sourceLastEditedAt = record.sourceLastEditedAt
        entity.lastSyncedAt = record.lastSyncedAt
        entity.aiProvider = record.aiProvider
        entity.aiModel = record.aiModel
        entity.extractionVersion = record.extractionVersion
        entity.isActive = record.isActive
        entity.createdAt = record.createdAt
        entity.updatedAt = record.updatedAt
    }

    private func makeFlashcard(
        _ record: LearningDataExportPackage.FlashcardRecord
    ) -> FlashcardEntity {
        FlashcardEntity(
            id: record.id,
            knowledgeItemID: record.knowledgeItemID,
            sourceDocumentID: record.sourceDocumentID,
            generationKey: record.generationKey,
            cardType: record.cardType,
            prompt: record.prompt,
            answer: record.answer,
            explanation: record.explanation,
            naturalEnglish: record.naturalEnglish,
            sourceKey: record.sourceKey,
            sourceDisplayPath: record.sourceDisplayPath,
            sourceReference: record.sourceReference,
            isActive: record.isActive,
            createdAt: record.createdAt,
            updatedAt: record.updatedAt
        )
    }

    private func apply(
        _ record: LearningDataExportPackage.FlashcardRecord,
        to entity: FlashcardEntity
    ) {
        entity.knowledgeItemID = record.knowledgeItemID
        entity.sourceDocumentID = record.sourceDocumentID
        entity.generationKey = record.generationKey
        entity.cardType = record.cardType
        entity.prompt = record.prompt
        entity.answer = record.answer
        entity.explanation = record.explanation
        entity.naturalEnglish = record.naturalEnglish
        entity.sourceKey = record.sourceKey
        entity.sourceDisplayPath = record.sourceDisplayPath
        entity.sourceReference = record.sourceReference
        entity.isActive = record.isActive
        entity.createdAt = record.createdAt
        entity.updatedAt = record.updatedAt
    }

    private func makeReviewState(
        _ record: LearningDataExportPackage.ReviewStateRecord
    ) -> ReviewStateEntity {
        ReviewStateEntity(
            cardID: record.cardID,
            due: record.due,
            stability: record.stability,
            difficulty: record.difficulty,
            elapsedDays: record.elapsedDays,
            scheduledDays: record.scheduledDays,
            repetitions: record.repetitions,
            lapses: record.lapses,
            stateRawValue: record.stateRawValue,
            lastReview: record.lastReview
        )
    }

    private func apply(
        _ record: LearningDataExportPackage.ReviewStateRecord,
        to entity: ReviewStateEntity
    ) {
        entity.due = record.due
        entity.stability = record.stability
        entity.difficulty = record.difficulty
        entity.elapsedDays = record.elapsedDays
        entity.scheduledDays = record.scheduledDays
        entity.repetitions = record.repetitions
        entity.lapses = record.lapses
        entity.stateRawValue = record.stateRawValue
        entity.lastReview = record.lastReview
    }

    private func makeReviewHistory(
        _ record: LearningDataExportPackage.ReviewHistoryRecord
    ) -> ReviewHistoryEntity {
        ReviewHistoryEntity(
            id: record.id,
            cardID: record.cardID,
            reviewedAt: record.reviewedAt,
            ratingRawValue: record.ratingRawValue,
            elapsedDays: record.elapsedDays,
            scheduledDays: record.scheduledDays,
            stabilityBefore: record.stabilityBefore,
            stabilityAfter: record.stabilityAfter,
            difficultyBefore: record.difficultyBefore,
            difficultyAfter: record.difficultyAfter
        )
    }
}

private struct MutableCounts {
    var inserted = 0
    var updated = 0
    var unchanged = 0

    var snapshot: RestoreMutationCounts {
        RestoreMutationCounts(
            inserted: inserted,
            updated: updated,
            unchanged: unchanged
        )
    }
}
