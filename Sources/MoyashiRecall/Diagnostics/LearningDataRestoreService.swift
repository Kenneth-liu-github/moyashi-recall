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

public enum LearningDataRestoreError: Error, Equatable {
    case sourceIdentityConflict(UUID)
    case knowledgeIdentityConflict(UUID)
    case flashcardIdentityConflict(UUID)
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
        var sourcesByStableKey = Dictionary(
            grouping: localSources
                .filter {
                    !$0.externalSourceID.isEmpty
                },
            by: Self.sourceStableKey
        )
        var sourceIDMap: [UUID: UUID] = [:]

        for record in package.sources {
            let semanticMatches: [SourceDocumentEntity]
            if record.externalSourceID.isEmpty {
                semanticMatches = []
            } else {
                semanticMatches = sourcesByStableKey[
                    Self.sourceStableKey(record)
                ] ?? []
            }
            let semanticMatch = semanticMatches.count == 1
                ? semanticMatches[0]
                : nil

            if let idMatch = sourceByID[record.id],
               !Self.sameSourceIdentity(
                    idMatch,
                    record
               ) {
                throw LearningDataRestoreError
                    .sourceIdentityConflict(record.id)
            }

            if let existing =
                sourceByID[record.id] ?? semanticMatch {
                sourceIDMap[record.id] = existing.id

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
                sourceIDMap[record.id] = entity.id
                sourceCounts.inserted += 1

                if !record.externalSourceID.isEmpty {
                    sourcesByStableKey[
                        Self.sourceStableKey(record),
                        default: []
                    ].append(entity)
                }
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
        var knowledgeByStableKey = Dictionary(
            grouping: localKnowledge
                .filter {
                    $0.sourceDocumentID != nil
                        && !$0.extractionKey.isEmpty
                },
            by: Self.knowledgeStableKey
        )
        var knowledgeIDMap: [UUID: UUID] = [:]

        for record in package.knowledgeItems {
            let mappedSourceID = record.sourceDocumentID
                .flatMap {
                    sourceIDMap[$0] ?? $0
                }
            let stableKey = Self.knowledgeStableKey(
                sourceDocumentID: mappedSourceID,
                extractionKey: record.extractionKey
            )
            let semanticMatches = stableKey.flatMap {
                knowledgeByStableKey[$0]
            } ?? []
            let semanticMatch = semanticMatches.count == 1
                ? semanticMatches[0]
                : nil

            if let idMatch = knowledgeByID[record.id],
               !Self.sameKnowledgeIdentity(
                    idMatch,
                    mappedSourceID: mappedSourceID,
                    extractionKey: record.extractionKey
               ) {
                throw LearningDataRestoreError
                    .knowledgeIdentityConflict(record.id)
            }

            if let existing =
                knowledgeByID[record.id] ?? semanticMatch {
                knowledgeIDMap[record.id] = existing.id

                if record.updatedAt > existing.updatedAt {
                    apply(
                        record,
                        mappedSourceID: mappedSourceID,
                        to: existing
                    )
                    knowledgeCounts.updated += 1
                } else {
                    knowledgeCounts.unchanged += 1
                }
            } else {
                let entity = makeKnowledge(
                    record,
                    mappedSourceID: mappedSourceID
                )
                context.insert(entity)
                knowledgeByID[record.id] = entity
                knowledgeIDMap[record.id] = entity.id
                knowledgeCounts.inserted += 1

                if let stableKey {
                    knowledgeByStableKey[
                        stableKey,
                        default: []
                    ].append(entity)
                }
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
        var cardsByStableKey = Dictionary(
            grouping: localCards
                .filter {
                    !$0.generationKey.isEmpty
                },
            by: Self.cardStableKey
        )
        var cardIDMap: [UUID: UUID] = [:]

        for record in package.flashcards {
            let mappedKnowledgeID =
                knowledgeIDMap[record.knowledgeItemID]
                    ?? record.knowledgeItemID
            let mappedSourceID = record.sourceDocumentID
                .flatMap {
                    sourceIDMap[$0] ?? $0
                }
            let stableKey = Self.cardStableKey(
                knowledgeItemID: mappedKnowledgeID,
                generationKey: record.generationKey
            )
            let semanticMatches = stableKey.flatMap {
                cardsByStableKey[$0]
            } ?? []
            let semanticMatch = semanticMatches.count == 1
                ? semanticMatches[0]
                : nil

            if let idMatch = cardByID[record.id],
               !Self.sameFlashcardIdentity(
                    idMatch,
                    mappedKnowledgeID: mappedKnowledgeID,
                    generationKey: record.generationKey
               ) {
                throw LearningDataRestoreError
                    .flashcardIdentityConflict(record.id)
            }

            if let existing =
                cardByID[record.id] ?? semanticMatch {
                cardIDMap[record.id] = existing.id

                if record.updatedAt > existing.updatedAt {
                    apply(
                        record,
                        mappedKnowledgeID: mappedKnowledgeID,
                        mappedSourceID: mappedSourceID,
                        to: existing
                    )
                    cardCounts.updated += 1
                } else {
                    cardCounts.unchanged += 1
                }
            } else {
                let entity = makeFlashcard(
                    record,
                    mappedKnowledgeID: mappedKnowledgeID,
                    mappedSourceID: mappedSourceID
                )
                context.insert(entity)
                cardByID[record.id] = entity
                cardIDMap[record.id] = entity.id
                cardCounts.inserted += 1

                if let stableKey {
                    cardsByStableKey[
                        stableKey,
                        default: []
                    ].append(entity)
                }
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
            let mappedCardID =
                cardIDMap[record.cardID]
                    ?? record.cardID

            if let existing = stateByCardID[mappedCardID] {
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
                let entity = makeReviewState(
                    record,
                    mappedCardID: mappedCardID
                )
                context.insert(entity)
                stateByCardID[mappedCardID] = entity
                stateCounts.inserted += 1
            }
        }

        let localHistory = try context.fetch(
            FetchDescriptor<ReviewHistoryEntity>()
        )
        var historyIDs = Set(
            localHistory.map(\.id)
        )
        var historySemanticKeys = Set(
            localHistory.map(Self.historyStableKey)
        )

        for record in package.reviewHistory {
            let mappedCardID =
                cardIDMap[record.cardID]
                    ?? record.cardID
            let semanticKey = Self.historyStableKey(
                cardID: mappedCardID,
                reviewedAt: record.reviewedAt,
                ratingRawValue: record.ratingRawValue
            )

            if historyIDs.contains(record.id)
                || historySemanticKeys.contains(
                    semanticKey
                ) {
                historyCounts.unchanged += 1
            } else {
                context.insert(
                    makeReviewHistory(
                        record,
                        mappedCardID: mappedCardID
                    )
                )
                historyIDs.insert(record.id)
                historySemanticKeys.insert(semanticKey)
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
        let localReview = existing.lastReview
            ?? .distantPast
        let backupReview = record.lastReview
            ?? .distantPast

        if backupReview != localReview {
            return backupReview > localReview
        }

        if record.repetitions != existing.repetitions {
            return record.repetitions
                > existing.repetitions
        }

        if record.lapses != existing.lapses {
            return record.lapses > existing.lapses
        }

        return false
    }

    private static func sameSourceIdentity(
        _ entity: SourceDocumentEntity,
        _ record: LearningDataExportPackage.SourceRecord
    ) -> Bool {
        guard entity.sourceKind == record.sourceKind else {
            return false
        }

        if entity.externalSourceID == record.externalSourceID {
            return true
        }

        return entity.externalSourceID.isEmpty
            && !record.externalSourceID.isEmpty
    }

    private static func sameKnowledgeIdentity(
        _ entity: KnowledgeItemEntity,
        mappedSourceID: UUID?,
        extractionKey: String
    ) -> Bool {
        guard entity.sourceDocumentID == mappedSourceID else {
            return false
        }

        if entity.extractionKey == extractionKey {
            return true
        }

        return entity.extractionKey.isEmpty
            && !extractionKey.isEmpty
    }

    private static func sameFlashcardIdentity(
        _ entity: FlashcardEntity,
        mappedKnowledgeID: UUID,
        generationKey: String
    ) -> Bool {
        guard entity.knowledgeItemID == mappedKnowledgeID else {
            return false
        }

        if entity.generationKey == generationKey {
            return true
        }

        return entity.generationKey.isEmpty
            && !generationKey.isEmpty
    }

    private static func sourceStableKey(
        _ entity: SourceDocumentEntity
    ) -> String {
        sourceStableKey(
            sourceKind: entity.sourceKind,
            externalSourceID: entity.externalSourceID
        )
    }

    private static func sourceStableKey(
        _ record: LearningDataExportPackage.SourceRecord
    ) -> String {
        sourceStableKey(
            sourceKind: record.sourceKind,
            externalSourceID: record.externalSourceID
        )
    }

    private static func sourceStableKey(
        sourceKind: String,
        externalSourceID: String
    ) -> String {
        sourceKind + "\u{1F}" + externalSourceID
    }

    private static func knowledgeStableKey(
        _ entity: KnowledgeItemEntity
    ) -> String {
        knowledgeStableKey(
            sourceDocumentID: entity.sourceDocumentID,
            extractionKey: entity.extractionKey
        ) ?? ""
    }

    private static func knowledgeStableKey(
        sourceDocumentID: UUID?,
        extractionKey: String
    ) -> String? {
        guard let sourceDocumentID,
              !extractionKey.isEmpty
        else {
            return nil
        }

        return sourceDocumentID.uuidString
            + "\u{1F}"
            + extractionKey
    }

    private static func cardStableKey(
        _ entity: FlashcardEntity
    ) -> String {
        cardStableKey(
            knowledgeItemID: entity.knowledgeItemID,
            generationKey: entity.generationKey
        ) ?? ""
    }

    private static func cardStableKey(
        knowledgeItemID: UUID,
        generationKey: String
    ) -> String? {
        guard !generationKey.isEmpty else {
            return nil
        }

        return knowledgeItemID.uuidString
            + "\u{1F}"
            + generationKey
    }

    private static func historyStableKey(
        _ entity: ReviewHistoryEntity
    ) -> String {
        historyStableKey(
            cardID: entity.cardID,
            reviewedAt: entity.reviewedAt,
            ratingRawValue: entity.ratingRawValue
        )
    }

    private static func historyStableKey(
        cardID: UUID,
        reviewedAt: Date,
        ratingRawValue: Int
    ) -> String {
        cardID.uuidString
            + "\u{1F}"
            + String(
                reviewedAt.timeIntervalSinceReferenceDate
            )
            + "\u{1F}"
            + String(ratingRawValue)
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
            aiProcessedSourceUpdatedAt:
                record.aiProcessedSourceUpdatedAt,
            lastAIExtractionVersion:
                record.lastAIExtractionVersion,
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
        entity.parentExternalSourceID =
            record.parentExternalSourceID
        entity.rootExternalSourceID =
            record.rootExternalSourceID
        entity.sourcePath = record.sourcePath
        entity.sourceKey = record.sourceKey
        entity.hierarchyDepth = record.hierarchyDepth
        entity.isSourceActive = record.isSourceActive
        entity.sourceLastEditedAt =
            record.sourceLastEditedAt
        entity.lastSyncedAt = record.lastSyncedAt
        entity.lastAIProcessedAt =
            record.lastAIProcessedAt
        entity.aiProcessedSourceUpdatedAt =
            record.aiProcessedSourceUpdatedAt
        entity.lastAIExtractionVersion =
            record.lastAIExtractionVersion
        entity.lastAIProviderID =
            record.lastAIProviderID
        entity.lastAIModelID = record.lastAIModelID
        entity.sourceReference = record.sourceReference
        entity.createdAt = record.createdAt
        entity.updatedAt = record.updatedAt
    }

    private func makeKnowledge(
        _ record: LearningDataExportPackage.KnowledgeRecord,
        mappedSourceID: UUID?
    ) -> KnowledgeItemEntity {
        KnowledgeItemEntity(
            id: record.id,
            sourceDocumentID: mappedSourceID,
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
            parentExternalSourceID:
                record.parentExternalSourceID,
            rootExternalSourceID:
                record.rootExternalSourceID,
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
        mappedSourceID: UUID?,
        to entity: KnowledgeItemEntity
    ) {
        entity.sourceDocumentID = mappedSourceID
        entity.extractionKey = record.extractionKey
        entity.knowledgeType = record.knowledgeType
        entity.title = record.title
        entity.canonicalExpression =
            record.canonicalExpression
        entity.meaning = record.meaning
        entity.explanation = record.explanation
        entity.naturalEnglish = record.naturalEnglish
        entity.content = record.content
        entity.tags = record.tags
        entity.sourceKind = record.sourceKind
        entity.sourceKey = record.sourceKey
        entity.sourceDisplayPath =
            record.sourceDisplayPath
        entity.sourceReference = record.sourceReference
        entity.externalSourceID = record.externalSourceID
        entity.parentExternalSourceID =
            record.parentExternalSourceID
        entity.rootExternalSourceID =
            record.rootExternalSourceID
        entity.sourcePath = record.sourcePath
        entity.hierarchyDepth = record.hierarchyDepth
        entity.isSourceActive = record.isSourceActive
        entity.sourceLastEditedAt =
            record.sourceLastEditedAt
        entity.lastSyncedAt = record.lastSyncedAt
        entity.aiProvider = record.aiProvider
        entity.aiModel = record.aiModel
        entity.extractionVersion =
            record.extractionVersion
        entity.isActive = record.isActive
        entity.createdAt = record.createdAt
        entity.updatedAt = record.updatedAt
    }

    private func makeFlashcard(
        _ record: LearningDataExportPackage.FlashcardRecord,
        mappedKnowledgeID: UUID,
        mappedSourceID: UUID?
    ) -> FlashcardEntity {
        FlashcardEntity(
            id: record.id,
            knowledgeItemID: mappedKnowledgeID,
            sourceDocumentID: mappedSourceID,
            generationKey: record.generationKey,
            cardType: record.cardType,
            prompt: record.prompt,
            answer: record.answer,
            explanation: record.explanation,
            naturalEnglish: record.naturalEnglish,
            sourceKey: record.sourceKey,
            sourceDisplayPath:
                record.sourceDisplayPath,
            sourceReference: record.sourceReference,
            isActive: record.isActive,
            createdAt: record.createdAt,
            updatedAt: record.updatedAt
        )
    }

    private func apply(
        _ record: LearningDataExportPackage.FlashcardRecord,
        mappedKnowledgeID: UUID,
        mappedSourceID: UUID?,
        to entity: FlashcardEntity
    ) {
        entity.knowledgeItemID = mappedKnowledgeID
        entity.sourceDocumentID = mappedSourceID
        entity.generationKey = record.generationKey
        entity.cardType = record.cardType
        entity.prompt = record.prompt
        entity.answer = record.answer
        entity.explanation = record.explanation
        entity.naturalEnglish = record.naturalEnglish
        entity.sourceKey = record.sourceKey
        entity.sourceDisplayPath =
            record.sourceDisplayPath
        entity.sourceReference = record.sourceReference
        entity.isActive = record.isActive
        entity.createdAt = record.createdAt
        entity.updatedAt = record.updatedAt
    }

    private func makeReviewState(
        _ record: LearningDataExportPackage.ReviewStateRecord,
        mappedCardID: UUID
    ) -> ReviewStateEntity {
        ReviewStateEntity(
            cardID: mappedCardID,
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
        _ record: LearningDataExportPackage.ReviewHistoryRecord,
        mappedCardID: UUID
    ) -> ReviewHistoryEntity {
        ReviewHistoryEntity(
            id: record.id,
            cardID: mappedCardID,
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
