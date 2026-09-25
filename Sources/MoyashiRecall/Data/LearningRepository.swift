import Foundation
import SwiftData

public struct ReviewSessionCard: Identifiable, Equatable, Sendable {
    public let id: UUID
    public let cardType: String
    public let prompt: String
    public let answer: String
    public let explanation: String
    public let naturalEnglish: String
    public let sourceKey: String
    public let sourceDisplayPath: String
    public let sourceReference: String

    public var sourceDisplay: String {
        sourceDisplayPath.isEmpty
            ? sourceReference
            : sourceDisplayPath
    }

    public init(entity: FlashcardEntity) {
        self.id = entity.id
        self.cardType = entity.cardType
        self.prompt = entity.prompt
        self.answer = entity.answer
        self.explanation = entity.explanation
        self.naturalEnglish = entity.naturalEnglish
        self.sourceKey = entity.sourceKey
        self.sourceDisplayPath = entity.sourceDisplayPath
        self.sourceReference = entity.sourceReference
    }
}

public struct ImportedDocumentSummary: Identifiable, Equatable, Sendable {
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
    public let lastAIProviderID: String
    public let lastAIModelID: String
    public let needsAIRefresh: Bool

    public init(entity: SourceDocumentEntity) {
        self.id = entity.id
        self.title = entity.title
        self.content = entity.content
        self.sourceKind = entity.sourceKind
        self.externalSourceID = entity.externalSourceID
        self.parentExternalSourceID = entity.parentExternalSourceID
        self.rootExternalSourceID = entity.rootExternalSourceID
        self.sourcePath = entity.sourcePath
        self.sourceKey = entity.sourceKey
        self.hierarchyDepth = entity.hierarchyDepth
        self.isSourceActive = entity.isSourceActive
        self.sourceReference = entity.sourceReference
        self.sourceLastEditedAt = entity.sourceLastEditedAt
        self.lastSyncedAt = entity.lastSyncedAt
        self.lastAIProcessedAt = entity.lastAIProcessedAt
        self.lastAIProviderID = entity.lastAIProviderID
        self.lastAIModelID = entity.lastAIModelID
        self.needsAIRefresh =
            entity.lastAIProcessedAt == nil
            || entity.aiProcessedSourceUpdatedAt != entity.updatedAt
            || entity.lastAIExtractionVersion
                != KnowledgeExtractionService.extractionVersion
    }
}

public enum ImportMutation: String, Equatable, Sendable {
    case inserted
    case updated
    case unchanged
}

public struct ImportedDocumentUpsertResult {
    public let entity: SourceDocumentEntity
    public let mutation: ImportMutation

    public init(
        entity: SourceDocumentEntity,
        mutation: ImportMutation
    ) {
        self.entity = entity
        self.mutation = mutation
    }
}

public struct SourceDocumentSnapshot: Identifiable, Equatable, Sendable {
    public let id: UUID
    public let title: String
    public let content: String
    public let sourceKind: String
    public let sourceKey: String
    public let sourcePath: String
    public let sourceReference: String
    public let updatedAt: Date

    public init(entity: SourceDocumentEntity) {
        self.id = entity.id
        self.title = entity.title
        self.content = entity.content
        self.sourceKind = entity.sourceKind
        self.sourceKey = entity.sourceKey
        self.sourcePath = entity.sourcePath
        self.sourceReference = entity.sourceReference
        self.updatedAt = entity.updatedAt
    }

    public var importedDocument: ImportedDocument {
        ImportedDocument(
            id: id.uuidString,
            sourceKind: sourceKind,
            title: title,
            sourceReference: sourceReference,
            content: content,
            sourcePath: sourcePath
                .components(
                    separatedBy: " / "
                )
                .map {
                    $0.trimmingCharacters(
                        in: .whitespacesAndNewlines
                    )
                }
                .filter { !$0.isEmpty }
        )
    }
}

public struct GeneratedKnowledgeSummary: Identifiable, Equatable, Sendable {
    public let id: UUID
    public let kind: String
    public let title: String
    public let canonicalExpression: String
    public let meaning: String
    public let explanation: String
    public let naturalEnglish: String
    public let cardCount: Int

    public init(
        entity: KnowledgeItemEntity,
        cardCount: Int
    ) {
        self.id = entity.id
        self.kind = entity.knowledgeType
        self.title = entity.title
        self.canonicalExpression = entity.canonicalExpression
        self.meaning = entity.meaning
        self.explanation = entity.explanation
        self.naturalEnglish = entity.naturalEnglish
        self.cardCount = cardCount
    }
}

public struct GeneratedContentSummary: Equatable, Sendable {
    public let knowledgeCount: Int
    public let cardCount: Int

    public init(
        knowledgeCount: Int,
        cardCount: Int
    ) {
        self.knowledgeCount = knowledgeCount
        self.cardCount = cardCount
    }
}

public struct ExtractionPersistenceReport: Equatable, Sendable {
    public let knowledgeInserted: Int
    public let knowledgeUpdated: Int
    public let knowledgeUnchanged: Int
    public let knowledgeDeactivated: Int
    public let cardsInserted: Int
    public let cardsUpdated: Int
    public let cardsUnchanged: Int
    public let cardsDeactivated: Int

    public init(
        knowledgeInserted: Int,
        knowledgeUpdated: Int,
        knowledgeUnchanged: Int,
        knowledgeDeactivated: Int,
        cardsInserted: Int,
        cardsUpdated: Int,
        cardsUnchanged: Int,
        cardsDeactivated: Int
    ) {
        self.knowledgeInserted = knowledgeInserted
        self.knowledgeUpdated = knowledgeUpdated
        self.knowledgeUnchanged = knowledgeUnchanged
        self.knowledgeDeactivated = knowledgeDeactivated
        self.cardsInserted = cardsInserted
        self.cardsUpdated = cardsUpdated
        self.cardsUnchanged = cardsUnchanged
        self.cardsDeactivated = cardsDeactivated
    }
}

public enum LearningRepositoryError: Error, Equatable {
    case sourceDocumentNotFound(UUID)
    case emptyExtractionWouldDeactivateExisting(UUID)
}

public struct ReviewHistorySummary: Identifiable, Equatable, Sendable {
    public let id: UUID
    public let cardID: UUID
    public let reviewedAt: Date
    public let rating: ReviewRating
    public let prompt: String
    public let answer: String
    public let sourceDisplay: String

    public init(
        id: UUID,
        cardID: UUID,
        reviewedAt: Date,
        rating: ReviewRating,
        prompt: String,
        answer: String,
        sourceDisplay: String
    ) {
        self.id = id
        self.cardID = cardID
        self.reviewedAt = reviewedAt
        self.rating = rating
        self.prompt = prompt
        self.answer = answer
        self.sourceDisplay = sourceDisplay
    }
}

public struct WeakKnowledgeSummary: Identifiable, Equatable, Sendable {
    public let id: UUID
    public let title: String
    public let sourceDisplay: String
    public let difficultReviews: Int
    public let totalReviews: Int

    public init(
        id: UUID,
        title: String,
        sourceDisplay: String,
        difficultReviews: Int,
        totalReviews: Int
    ) {
        self.id = id
        self.title = title
        self.sourceDisplay = sourceDisplay
        self.difficultReviews = difficultReviews
        self.totalReviews = totalReviews
    }
}

public struct HomeSnapshot: Equatable, Sendable {
    public let dueCount: Int
    public let streakDays: Int
    public let reviewedToday: Int
    public let reviewedLast7Days: Int
    public let successRateLast7Days: Double?
    public let latestReviewAt: Date?
    public let weakKnowledge: [WeakKnowledgeSummary]

    public init(
        dueCount: Int,
        streakDays: Int,
        reviewedToday: Int = 0,
        reviewedLast7Days: Int = 0,
        successRateLast7Days: Double? = nil,
        latestReviewAt: Date? = nil,
        weakKnowledge: [WeakKnowledgeSummary] = []
    ) {
        self.dueCount = dueCount
        self.streakDays = streakDays
        self.reviewedToday = reviewedToday
        self.reviewedLast7Days = reviewedLast7Days
        self.successRateLast7Days = successRateLast7Days
        self.latestReviewAt = latestReviewAt
        self.weakKnowledge = weakKnowledge
    }
}

@MainActor
public struct LearningRepository {
    private let context: ModelContext
    private let queueService: ReviewQueueService
    private let recorder: ReviewRecorder

    public init(
        context: ModelContext,
        scheduler: FSRSScheduler = FSRSScheduler()
    ) {
        self.context = context
        self.queueService = ReviewQueueService()
        self.recorder = ReviewRecorder(scheduler: scheduler)
    }

    @discardableResult
    public func migrateLegacyImportedKnowledgeIfNeeded(
        now: Date = .now
    ) throws -> Int {
        let legacyItems = try context.fetch(
            FetchDescriptor<KnowledgeItemEntity>()
        )
        .filter {
            $0.sourceDocumentID == nil
                && !$0.externalSourceID.isEmpty
                && $0.isSourceActive
        }

        guard !legacyItems.isEmpty else {
            return 0
        }

        let sourceDocuments = try context.fetch(
            FetchDescriptor<SourceDocumentEntity>()
        )
        let cards = try context.fetch(
            FetchDescriptor<FlashcardEntity>()
        )

        var migrated = 0

        for legacy in legacyItems {
            let existingSource = sourceDocuments.first {
                $0.sourceKind == legacy.sourceKind
                    && $0.externalSourceID
                        == legacy.externalSourceID
            }

            let source: SourceDocumentEntity
            if let existingSource {
                source = existingSource
            } else {
                source = SourceDocumentEntity(
                    title: legacy.title,
                    content: legacy.content,
                    sourceKind: legacy.sourceKind,
                    externalSourceID: legacy.externalSourceID,
                    parentExternalSourceID:
                        legacy.parentExternalSourceID,
                    rootExternalSourceID:
                        legacy.rootExternalSourceID,
                    sourcePath: legacy.sourcePath,
                    sourceKey: legacy.sourceKey,
                    hierarchyDepth: legacy.hierarchyDepth,
                    isSourceActive: legacy.isSourceActive,
                    sourceLastEditedAt:
                        legacy.sourceLastEditedAt,
                    lastSyncedAt: legacy.lastSyncedAt,
                    sourceReference: legacy.sourceReference,
                    createdAt: legacy.createdAt,
                    updatedAt: legacy.updatedAt
                )
                context.insert(source)
            }

            for card in cards where
                card.knowledgeItemID == legacy.id
                && card.sourceDocumentID == nil
            {
                card.sourceDocumentID = source.id
                if card.sourceDisplayPath.isEmpty {
                    card.sourceDisplayPath = legacy.sourcePath
                }
                card.updatedAt = now
            }

            legacy.isActive = false
            legacy.isSourceActive = false
            legacy.updatedAt = now
            migrated += 1
        }

        try context.save()
        return migrated
    }

    @discardableResult
    public func upsertImportedDocument(
        _ document: ImportedDocument,
        now: Date = .now
    ) throws -> SourceDocumentEntity {
        try upsertImportedDocumentWithResult(
            document,
            now: now
        ).entity
    }

    public func upsertImportedDocumentWithResult(
        _ document: ImportedDocument,
        now: Date = .now
    ) throws -> ImportedDocumentUpsertResult {
        let sourceKind = document.sourceKind
        let externalID = document.id
        var descriptor = FetchDescriptor<SourceDocumentEntity>(
            predicate: #Predicate { item in
                item.sourceKind == sourceKind
                    && item.externalSourceID == externalID
            }
        )
        descriptor.fetchLimit = 1

        let sourcePath = document.sourcePath.joined(separator: " / ")
        let hintedSourceKey = document.sourceKeyHint?
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )
        let sourceKey = hintedSourceKey?.isEmpty == false
            ? hintedSourceKey!
            : SourceKeyResolver.resolve(
                sourceKind: document.sourceKind,
                sourcePath: document.sourcePath
            )
        let parentExternalID = document.parentExternalID ?? ""
        let rootExternalID = document.rootExternalID

        if let existing = try context.fetch(descriptor).first {
            let unchanged =
                existing.title == document.title
                && existing.content == document.content
                && existing.parentExternalSourceID == parentExternalID
                && existing.rootExternalSourceID == rootExternalID
                && existing.sourcePath == sourcePath
                && existing.sourceKey == sourceKey
                && existing.hierarchyDepth == document.hierarchyDepth
                && existing.sourceLastEditedAt == document.lastEditedAt
                && existing.sourceReference == document.sourceReference
                && existing.isSourceActive

            existing.lastSyncedAt = now

            if unchanged {
                try context.save()
                return ImportedDocumentUpsertResult(
                    entity: existing,
                    mutation: .unchanged
                )
            }

            existing.title = document.title
            existing.content = document.content
            existing.parentExternalSourceID = parentExternalID
            existing.rootExternalSourceID = rootExternalID
            existing.sourcePath = sourcePath
            existing.sourceKey = sourceKey
            existing.hierarchyDepth = document.hierarchyDepth
            existing.isSourceActive = true
            existing.sourceLastEditedAt = document.lastEditedAt
            existing.sourceReference = document.sourceReference
            existing.updatedAt = now
            try context.save()

            return ImportedDocumentUpsertResult(
                entity: existing,
                mutation: .updated
            )
        }

        let item = SourceDocumentEntity(
            title: document.title,
            content: document.content,
            sourceKind: document.sourceKind,
            externalSourceID: document.id,
            parentExternalSourceID: parentExternalID,
            rootExternalSourceID: rootExternalID,
            sourcePath: sourcePath,
            sourceKey: sourceKey,
            hierarchyDepth: document.hierarchyDepth,
            isSourceActive: true,
            sourceLastEditedAt: document.lastEditedAt,
            lastSyncedAt: now,
            sourceReference: document.sourceReference,
            createdAt: now,
            updatedAt: now
        )
        context.insert(item)
        try context.save()

        return ImportedDocumentUpsertResult(
            entity: item,
            mutation: .inserted
        )
    }

    public func importedDocuments(
        sourceKind: String? = nil
    ) throws -> [ImportedDocumentSummary] {
        let items = try context.fetch(
            FetchDescriptor<SourceDocumentEntity>(
                sortBy: [
                    SortDescriptor(\.sourcePath, order: .forward)
                ]
            )
        )

        return items
            .filter { item in
                item.isSourceActive
                    && (sourceKind == nil || item.sourceKind == sourceKind)
            }
            .map(ImportedDocumentSummary.init)
    }

    @discardableResult
    public func reconcileImportedTree(
        sourceKind: String,
        rootExternalID: String,
        activeExternalIDs: Set<String>,
        now: Date = .now
    ) throws -> Int {
        let items = try context.fetch(
            FetchDescriptor<SourceDocumentEntity>()
        )
        let knowledge = try context.fetch(
            FetchDescriptor<KnowledgeItemEntity>()
        )
        let cards = try context.fetch(
            FetchDescriptor<FlashcardEntity>()
        )

        var deactivated = 0
        for item in items where
            item.sourceKind == sourceKind
            && item.rootExternalSourceID == rootExternalID
            && !activeExternalIDs.contains(item.externalSourceID)
            && item.isSourceActive
        {
            item.isSourceActive = false
            item.lastSyncedAt = now
            item.updatedAt = now
            deactivated += 1

            for knowledgeItem in knowledge where
                knowledgeItem.sourceDocumentID == item.id
                && knowledgeItem.isActive
            {
                knowledgeItem.isActive = false
                knowledgeItem.updatedAt = now
            }

            for card in cards where
                card.sourceDocumentID == item.id
                && card.isActive
            {
                card.isActive = false
                card.updatedAt = now
            }
        }

        if deactivated > 0 {
            try context.save()
        }
        return deactivated
    }

    public func sourceDocument(
        id: UUID
    ) throws -> SourceDocumentSnapshot? {
        let targetID = id
        var descriptor = FetchDescriptor<SourceDocumentEntity>(
            predicate: #Predicate { document in
                document.id == targetID
            }
        )
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
            .map(SourceDocumentSnapshot.init)
    }

    public func generatedKnowledgeItems(
        sourceDocumentID: UUID
    ) throws -> [GeneratedKnowledgeSummary] {
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
        .filter {
            $0.sourceDocumentID == sourceDocumentID
                && $0.isActive
        }

        let cards = try context.fetch(
            FetchDescriptor<FlashcardEntity>()
        )
        .filter {
            $0.sourceDocumentID == sourceDocumentID
                && $0.isActive
        }

        let counts = cards.reduce(
            into: [UUID: Int]()
        ) { result, card in
            result[card.knowledgeItemID, default: 0] += 1
        }

        return knowledge.map {
            GeneratedKnowledgeSummary(
                entity: $0,
                cardCount: counts[$0.id, default: 0]
            )
        }
    }

    public func generatedContentSummary(
        sourceDocumentID: UUID
    ) throws -> GeneratedContentSummary {
        let knowledge = try context.fetch(
            FetchDescriptor<KnowledgeItemEntity>()
        )
        .filter {
            $0.sourceDocumentID == sourceDocumentID
                && $0.isActive
        }

        let cards = try context.fetch(
            FetchDescriptor<FlashcardEntity>()
        )
        .filter {
            $0.sourceDocumentID == sourceDocumentID
                && $0.isActive
        }

        return GeneratedContentSummary(
            knowledgeCount: knowledge.count,
            cardCount: cards.count
        )
    }

    public func persistExtraction(
        _ bundle: KnowledgeExtractionBundle,
        sourceDocumentID: UUID,
        providerID: String,
        modelID: String,
        now: Date = .now
    ) throws -> ExtractionPersistenceReport {
        guard let source = try sourceDocument(id: sourceDocumentID) else {
            throw LearningRepositoryError.sourceDocumentNotFound(
                sourceDocumentID
            )
        }

        let targetSourceID = sourceDocumentID
        var sourceDescriptor = FetchDescriptor<SourceDocumentEntity>(
            predicate: #Predicate { document in
                document.id == targetSourceID
            }
        )
        sourceDescriptor.fetchLimit = 1
        guard let sourceEntity = try context.fetch(
            sourceDescriptor
        ).first else {
            throw LearningRepositoryError.sourceDocumentNotFound(
                sourceDocumentID
            )
        }

        let allKnowledge = try context.fetch(
            FetchDescriptor<KnowledgeItemEntity>()
        )
        let existingKnowledge = allKnowledge.filter {
            $0.sourceDocumentID == sourceDocumentID
        }
        let allCards = try context.fetch(
            FetchDescriptor<FlashcardEntity>()
        )

        var knowledgeInserted = 0
        var knowledgeUpdated = 0
        var knowledgeUnchanged = 0
        var cardsInserted = 0
        var cardsUpdated = 0
        var cardsUnchanged = 0
        var cardsDeactivated = 0

        if bundle.items.isEmpty,
           existingKnowledge.contains(where: \.isActive) {
            throw LearningRepositoryError
                .emptyExtractionWouldDeactivateExisting(
                    sourceDocumentID
                )
        }

        let activeKeys = Set(bundle.items.map(\.key))

        for generated in bundle.items {
            let knowledge: KnowledgeItemEntity

            if let existing = existingKnowledge.first(
                where: { $0.extractionKey == generated.key }
            ) ?? existingKnowledge.first(
                where: {
                    $0.knowledgeType == generated.kind.rawValue
                        && $0.title == generated.title
                        && $0.canonicalExpression
                            == generated.canonicalExpression
                        && $0.meaning == generated.meaning
                }
            ) {
                let tags = generated.tags.joined(separator: "|")
                let unchanged =
                    existing.extractionKey == generated.key
                    && existing.knowledgeType == generated.kind.rawValue
                    && existing.title == generated.title
                    && existing.canonicalExpression == generated.canonicalExpression
                    && existing.meaning == generated.meaning
                    && existing.explanation == generated.explanation
                    && existing.naturalEnglish == generated.naturalEnglish
                    && existing.tags == tags
                    && existing.sourceDocumentID == sourceDocumentID
                    && existing.sourceKind == source.sourceKind
                    && existing.sourceKey == source.sourceKey
                    && existing.sourceDisplayPath == source.sourcePath
                    && existing.sourceReference == source.sourceReference
                    && existing.isActive

                if unchanged {
                    knowledgeUnchanged += 1
                } else {
                    existing.extractionKey = generated.key
                    existing.knowledgeType = generated.kind.rawValue
                    existing.title = generated.title
                    existing.canonicalExpression = generated.canonicalExpression
                    existing.meaning = generated.meaning
                    existing.explanation = generated.explanation
                    existing.naturalEnglish = generated.naturalEnglish
                    existing.content = generated.explanation
                    existing.tags = tags
                    existing.sourceDocumentID = sourceDocumentID
                    existing.sourceKind = source.sourceKind
                    existing.sourceKey = source.sourceKey
                    existing.sourceDisplayPath = source.sourcePath
                    existing.sourceReference = source.sourceReference
                    existing.isActive = true
                    existing.updatedAt = now
                    knowledgeUpdated += 1
                }

                existing.aiProvider = providerID
                existing.aiModel = modelID
                existing.extractionVersion = bundle.version
                knowledge = existing
            } else {
                knowledge = KnowledgeItemEntity(
                    sourceDocumentID: sourceDocumentID,
                    extractionKey: generated.key,
                    knowledgeType: generated.kind.rawValue,
                    title: generated.title,
                    canonicalExpression: generated.canonicalExpression,
                    meaning: generated.meaning,
                    explanation: generated.explanation,
                    naturalEnglish: generated.naturalEnglish,
                    content: generated.explanation,
                    tags: generated.tags.joined(separator: "|"),
                    sourceKind: source.sourceKind,
                    sourceKey: source.sourceKey,
                    sourceDisplayPath: source.sourcePath,
                    sourceReference: source.sourceReference,
                    aiProvider: providerID,
                    aiModel: modelID,
                    extractionVersion: bundle.version,
                    isActive: true,
                    createdAt: now,
                    updatedAt: now
                )
                context.insert(knowledge)
                knowledgeInserted += 1
            }

            let existingCards = allCards.filter {
                $0.knowledgeItemID == knowledge.id
            }
            let activeCardKeys = Set(generated.cards.map(\.key))

            for generatedCard in generated.cards {
                if let existing = existingCards.first(
                    where: { $0.generationKey == generatedCard.key }
                ) ?? existingCards.first(
                    where: {
                        $0.cardType == generatedCard.type.rawValue
                            && $0.prompt == generatedCard.prompt
                            && $0.answer == generatedCard.answer
                    }
                ) {
                    let unchanged =
                        existing.generationKey == generatedCard.key
                        && existing.cardType == generatedCard.type.rawValue
                        && existing.prompt == generatedCard.prompt
                        && existing.answer == generatedCard.answer
                        && existing.explanation == generatedCard.explanation
                        && existing.naturalEnglish == generatedCard.naturalEnglish
                        && existing.sourceDocumentID == sourceDocumentID
                        && existing.sourceKey == source.sourceKey
                        && existing.sourceDisplayPath == source.sourcePath
                        && existing.sourceReference == source.sourceReference
                        && existing.isActive

                    if unchanged {
                        cardsUnchanged += 1
                    } else {
                        existing.generationKey = generatedCard.key
                        existing.cardType = generatedCard.type.rawValue
                        existing.prompt = generatedCard.prompt
                        existing.answer = generatedCard.answer
                        existing.explanation = generatedCard.explanation
                        existing.naturalEnglish = generatedCard.naturalEnglish
                        existing.sourceDocumentID = sourceDocumentID
                        existing.sourceKey = source.sourceKey
                        existing.sourceDisplayPath = source.sourcePath
                        existing.sourceReference = source.sourceReference
                        existing.isActive = true
                        existing.updatedAt = now
                        cardsUpdated += 1
                    }
                } else {
                    context.insert(
                        FlashcardEntity(
                            knowledgeItemID: knowledge.id,
                            sourceDocumentID: sourceDocumentID,
                            generationKey: generatedCard.key,
                            cardType: generatedCard.type.rawValue,
                            prompt: generatedCard.prompt,
                            answer: generatedCard.answer,
                            explanation: generatedCard.explanation,
                            naturalEnglish: generatedCard.naturalEnglish,
                            sourceKey: source.sourceKey,
                            sourceDisplayPath: source.sourcePath,
                            sourceReference: source.sourceReference,
                            isActive: true,
                            createdAt: now,
                            updatedAt: now
                        )
                    )
                    cardsInserted += 1
                }
            }

            for card in existingCards where
                !activeCardKeys.contains(card.generationKey)
                && card.isActive
            {
                card.isActive = false
                card.updatedAt = now
                cardsDeactivated += 1
            }
        }

        var knowledgeDeactivated = 0
        for item in existingKnowledge where
            !activeKeys.contains(item.extractionKey)
            && item.isActive
        {
            item.isActive = false
            item.updatedAt = now
            knowledgeDeactivated += 1

            let cards = allCards.filter {
                $0.knowledgeItemID == item.id && $0.isActive
            }
            for card in cards {
                card.isActive = false
                card.updatedAt = now
                cardsDeactivated += 1
            }
        }

        sourceEntity.lastAIProcessedAt = now
        sourceEntity.aiProcessedSourceUpdatedAt = sourceEntity.updatedAt
        sourceEntity.lastAIExtractionVersion = bundle.version
        sourceEntity.lastAIProviderID = providerID
        sourceEntity.lastAIModelID = modelID
        try context.save()

        return ExtractionPersistenceReport(
            knowledgeInserted: knowledgeInserted,
            knowledgeUpdated: knowledgeUpdated,
            knowledgeUnchanged: knowledgeUnchanged,
            knowledgeDeactivated: knowledgeDeactivated,
            cardsInserted: cardsInserted,
            cardsUpdated: cardsUpdated,
            cardsUnchanged: cardsUnchanged,
            cardsDeactivated: cardsDeactivated
        )
    }

    public func dueSessionCards(
        now: Date = .now,
        sourceKeys: Set<String>? = nil,
        cardTypes: Set<String>? = nil,
        knowledgeItemIDs: Set<UUID>? = nil,
        limit: Int? = nil
    ) throws -> [ReviewSessionCard] {
        try queueService
            .dueCards(
                in: context,
                now: now,
                sourceKeys: sourceKeys,
                cardTypes: cardTypes,
                knowledgeItemIDs: knowledgeItemIDs,
                limit: limit
            )
            .map(ReviewSessionCard.init)
    }

    public func dueCardCount(
        now: Date = .now,
        sourceKeys: Set<String>? = nil,
        cardTypes: Set<String>? = nil,
        knowledgeItemIDs: Set<UUID>? = nil
    ) throws -> Int {
        try queueService.dueCards(
            in: context,
            now: now,
            sourceKeys: sourceKeys,
            cardTypes: cardTypes,
            knowledgeItemIDs: knowledgeItemIDs,
            limit: nil
        ).count
    }

    public func allSessionCards(
        searchText: String = ""
    ) throws -> [ReviewSessionCard] {
        let entities = try context.fetch(
            FetchDescriptor<FlashcardEntity>(
                sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
            )
        )
        let normalized = searchText.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        let activeEntities = entities.filter(\.isActive)
        let filtered: [FlashcardEntity]
        if normalized.isEmpty {
            filtered = activeEntities
        } else {
            filtered = activeEntities.filter {
                $0.prompt.localizedCaseInsensitiveContains(normalized)
                    || $0.answer.localizedCaseInsensitiveContains(normalized)
                    || $0.explanation.localizedCaseInsensitiveContains(normalized)
                    || $0.sourceDisplayPath.localizedCaseInsensitiveContains(normalized)
                    || $0.sourceReference.localizedCaseInsensitiveContains(normalized)
            }
        }
        return filtered.map(ReviewSessionCard.init)
    }

    public func reviewSources(
        now: Date = .now,
        cardTypes: Set<String>? = nil
    ) throws -> [StudySource] {
        let cards = try context.fetch(
            FetchDescriptor<FlashcardEntity>()
        )
        .filter(\.isActive)

        let states = try context.fetch(
            FetchDescriptor<ReviewStateEntity>()
        )

        let stateByCard = states.reduce(
            into: [UUID: ReviewStateEntity]()
        ) { result, state in
            if let existing = result[state.cardID] {
                if state.due < existing.due {
                    result[state.cardID] = state
                }
            } else {
                result[state.cardID] = state
            }
        }

        let counts = cards.reduce(
            into: [String: (all: Int, due: Int)]()
        ) { result, card in
            guard !card.sourceKey.isEmpty else {
                return
            }

            result[card.sourceKey, default: (0, 0)].all += 1

            let matchesCardType =
                cardTypes == nil
                || cardTypes?.isEmpty == true
                || cardTypes?.contains(card.cardType) == true

            let isDue: Bool
            if let state = stateByCard[card.id] {
                isDue = state.due <= now
            } else {
                isDue = true
            }

            if matchesCardType && isDue {
                result[card.sourceKey, default: (0, 0)].due += 1
            }
        }

        let documents = try context.fetch(
            FetchDescriptor<SourceDocumentEntity>()
        )
        .filter(\.isSourceActive)

        var documentByKey: [
            String: SourceDocumentEntity
        ] = [:]
        for document in documents
        where documentByKey[document.sourceKey] == nil {
            documentByKey[document.sourceKey] = document
        }

        return counts.map { key, count in
            let document = documentByKey[key]
            let title = document
                .map {
                    Self.categoryTitle(
                        from: $0.sourcePath
                    )
                }
                ?? Self.fallbackSourceTitle(
                    for: key
                )

            let detail = document?.sourceKind
                .capitalized
                ?? "Local"

            return StudySource(
                key: key,
                title: title,
                detail: detail,
                cardCount: count.all,
                dueCardCount: count.due
            )
        }
        .sorted {
            $0.title.localizedCompare(
                $1.title
            ) == .orderedAscending
        }
    }

    public func recentReviewHistory(
        limit: Int = 100
    ) throws -> [ReviewHistorySummary] {
        let safeLimit = min(max(limit, 1), 500)
        var descriptor = FetchDescriptor<ReviewHistoryEntity>(
            sortBy: [
                SortDescriptor(
                    \.reviewedAt,
                    order: .reverse
                )
            ]
        )
        descriptor.fetchLimit = safeLimit

        let history = try context.fetch(descriptor)
        let cards = try context.fetch(
            FetchDescriptor<FlashcardEntity>()
        )
        let cardByID = Dictionary(
            uniqueKeysWithValues: cards.map {
                ($0.id, $0)
            }
        )

        return history.compactMap { event in
            guard
                let rating = ReviewRating(
                    rawValue: event.ratingRawValue
                ),
                let card = cardByID[event.cardID]
            else {
                return nil
            }

            return ReviewHistorySummary(
                id: event.id,
                cardID: event.cardID,
                reviewedAt: event.reviewedAt,
                rating: rating,
                prompt: card.prompt,
                answer: card.answer,
                sourceDisplay: card.sourceDisplayPath.isEmpty
                    ? card.sourceReference
                    : card.sourceDisplayPath
            )
        }
    }

    public func cardCountsBySourceKey() throws -> [String: Int] {
        let cards = try context.fetch(FetchDescriptor<FlashcardEntity>())
            .filter(\.isActive)
        return cards.reduce(into: [String: Int]()) { result, card in
            result[card.sourceKey, default: 0] += 1
        }
    }

    @discardableResult
    public func recordReview(
        cardID: UUID,
        rating: ReviewRating,
        now: Date = .now
    ) throws -> FSRSScheduleResult {
        try recorder.record(
            cardID: cardID,
            rating: rating,
            in: context,
            now: now
        )
    }

    private static func categoryTitle(
        from sourcePath: String
    ) -> String {
        let components = sourcePath
            .components(
                separatedBy: " / "
            )
            .filter { !$0.isEmpty }

        if components.first == "Learning Home",
           components.count >= 2 {
            return components[1]
        }

        return components.first ?? sourcePath
    }

    private static func fallbackSourceTitle(
        for key: String
    ) -> String {
        switch key {
        case "office-japanese":
            return "办公室日语学习"
        case "japanese-bootcamp":
            return "日语训练营"
        case "japanese-speaking":
            return "日语口语 私教"
        default:
            return key
        }
    }

    public func homeSnapshot(now: Date = .now) throws -> HomeSnapshot {
        let cards = try context.fetch(
            FetchDescriptor<FlashcardEntity>()
        )
        .filter(\.isActive)
        let states = try context.fetch(
            FetchDescriptor<ReviewStateEntity>()
        )
        let history = try context.fetch(
            FetchDescriptor<ReviewHistoryEntity>(
                sortBy: [
                    SortDescriptor(
                        \.reviewedAt,
                        order: .reverse
                    )
                ]
            )
        )
        let knowledge = try context.fetch(
            FetchDescriptor<KnowledgeItemEntity>()
        )
        .filter(\.isActive)

        let activeCardIDs = Set(cards.map(\.id))
        let activeHistory = history.filter {
            activeCardIDs.contains($0.cardID)
        }

        let stateByCard = states.reduce(
            into: [UUID: ReviewStateEntity]()
        ) { result, state in
            if let existing = result[state.cardID] {
                if state.due < existing.due {
                    result[state.cardID] = state
                }
            } else {
                result[state.cardID] = state
            }
        }

        let dueCount = cards.reduce(0) { count, card in
            guard let state = stateByCard[card.id] else {
                return count + 1
            }
            return count + (state.due <= now ? 1 : 0)
        }

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: now)
        let sevenDaysAgo = calendar.date(
            byAdding: .day,
            value: -6,
            to: today
        ) ?? today
        let fourteenDaysAgo = calendar.date(
            byAdding: .day,
            value: -13,
            to: today
        ) ?? today

        let reviewDays = Set(
            history.map {
                calendar.startOfDay(for: $0.reviewedAt)
            }
        )
        var streak = 0

        if !reviewDays.isEmpty {
            var cursor = today
            if !reviewDays.contains(cursor) {
                cursor = calendar.date(
                    byAdding: .day,
                    value: -1,
                    to: cursor
                ) ?? cursor
            }

            while reviewDays.contains(cursor) {
                streak += 1
                cursor = calendar.date(
                    byAdding: .day,
                    value: -1,
                    to: cursor
                ) ?? cursor
            }
        }

        let todayHistory = history.filter {
            calendar.isDate($0.reviewedAt, inSameDayAs: now)
        }
        let recentHistory = history.filter {
            $0.reviewedAt >= sevenDaysAgo
                && $0.reviewedAt <= now
        }

        let successfulReviews = recentHistory.filter {
            $0.ratingRawValue != ReviewRating.again.rawValue
        }.count
        let successRate = recentHistory.isEmpty
            ? nil
            : Double(successfulReviews)
                / Double(recentHistory.count)

        let cardByID = Dictionary(
            uniqueKeysWithValues: cards.map {
                ($0.id, $0)
            }
        )
        let knowledgeByID = Dictionary(
            uniqueKeysWithValues: knowledge.map {
                ($0.id, $0)
            }
        )

        let dueKnowledgeIDs = Set(
            cards.compactMap { card -> UUID? in
                if let state = stateByCard[card.id],
                   state.due > now {
                    return nil
                }
                return card.knowledgeItemID
            }
        )

        var weaknessByKnowledge: [
            UUID: (
                difficult: Int,
                total: Int
            )
        ] = [:]

        for review in activeHistory
        where review.reviewedAt >= fourteenDaysAgo
            && review.reviewedAt <= now {
            guard let card = cardByID[review.cardID] else {
                continue
            }

            weaknessByKnowledge[
                card.knowledgeItemID,
                default: (0, 0)
            ].total += 1

            if review.ratingRawValue == ReviewRating.again.rawValue
                || review.ratingRawValue == ReviewRating.hard.rawValue {
                weaknessByKnowledge[
                    card.knowledgeItemID,
                    default: (0, 0)
                ].difficult += 1
            }
        }

        let weakKnowledge = weaknessByKnowledge
            .compactMap { knowledgeID, values
                -> WeakKnowledgeSummary? in
                guard values.difficult > 0,
                      dueKnowledgeIDs.contains(knowledgeID),
                      let item = knowledgeByID[knowledgeID]
                else {
                    return nil
                }

                let sourceDisplay = item.sourceDisplayPath.isEmpty
                    ? item.sourceReference
                    : item.sourceDisplayPath

                return WeakKnowledgeSummary(
                    id: item.id,
                    title: item.canonicalExpression.isEmpty
                        ? item.title
                        : item.canonicalExpression,
                    sourceDisplay: sourceDisplay,
                    difficultReviews: values.difficult,
                    totalReviews: values.total
                )
            }
            .sorted {
                let lhsRate = Double($0.difficultReviews)
                    / Double(max($0.totalReviews, 1))
                let rhsRate = Double($1.difficultReviews)
                    / Double(max($1.totalReviews, 1))

                if lhsRate == rhsRate {
                    return $0.difficultReviews
                        > $1.difficultReviews
                }
                return lhsRate > rhsRate
            }

        return HomeSnapshot(
            dueCount: dueCount,
            streakDays: streak,
            reviewedToday: todayHistory.count,
            reviewedLast7Days: recentHistory.count,
            successRateLast7Days: successRate,
            latestReviewAt: history.first?.reviewedAt,
            weakKnowledge: Array(
                weakKnowledge.prefix(3)
            )
        )
    }
}
