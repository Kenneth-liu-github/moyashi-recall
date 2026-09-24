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
    public let sourceReference: String

    public init(entity: FlashcardEntity) {
        self.id = entity.id
        self.cardType = entity.cardType
        self.prompt = entity.prompt
        self.answer = entity.answer
        self.explanation = entity.explanation
        self.naturalEnglish = entity.naturalEnglish
        self.sourceKey = entity.sourceKey
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

    public init(entity: SourceDocumentEntity) {
        self.id = entity.id
        self.title = entity.title
        self.content = entity.content
        self.sourceKind = entity.sourceKind
        self.sourceKey = entity.sourceKey
        self.sourcePath = entity.sourcePath
        self.sourceReference = entity.sourceReference
    }

    public var importedDocument: ImportedDocument {
        ImportedDocument(
            id: id.uuidString,
            sourceKind: sourceKind,
            title: title,
            sourceReference: sourceReference,
            content: content,
            sourcePath: sourcePath
                .split(separator: "/")
                .map {
                    $0.trimmingCharacters(
                        in: .whitespacesAndNewlines
                    )
                }
        )
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

public struct HomeSnapshot: Equatable, Sendable {
    public let dueCount: Int
    public let streakDays: Int

    public init(dueCount: Int, streakDays: Int) {
        self.dueCount = dueCount
        self.streakDays = streakDays
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

    public func seedDemoIfNeeded() throws {
        #if DEBUG
        try DemoDataSeeder.seedIfNeeded(in: context)
        #endif
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
        let sourceKey = SourceKeyResolver.resolve(
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

    public func persistExtraction(
        _ bundle: KnowledgeExtractionBundle,
        sourceDocumentID: UUID,
        providerID: String,
        modelID: String,
        now: Date = .now
    ) throws -> ExtractionPersistenceReport {
        guard let source = try sourceDocument(id: sourceDocumentID) else {
            throw AIProviderError.invalidResponse
        }

        let allKnowledge = try context.fetch(
            FetchDescriptor<KnowledgeItemEntity>()
        )
        let existingKnowledge = allKnowledge.filter {
            $0.sourceDocumentID == sourceDocumentID
        }

        var knowledgeInserted = 0
        var knowledgeUpdated = 0
        var knowledgeUnchanged = 0
        var cardsInserted = 0
        var cardsUpdated = 0
        var cardsUnchanged = 0
        var cardsDeactivated = 0

        let activeKeys = Set(bundle.items.map(\.key))

        for generated in bundle.items {
            let knowledge: KnowledgeItemEntity

            if let existing = existingKnowledge.first(
                where: { $0.extractionKey == generated.key }
            ) {
                let tags = generated.tags.joined(separator: "|")
                let unchanged =
                    existing.knowledgeType == generated.kind.rawValue
                    && existing.title == generated.title
                    && existing.canonicalExpression == generated.canonicalExpression
                    && existing.meaning == generated.meaning
                    && existing.explanation == generated.explanation
                    && existing.naturalEnglish == generated.naturalEnglish
                    && existing.tags == tags
                    && existing.isActive

                if unchanged {
                    knowledgeUnchanged += 1
                } else {
                    existing.knowledgeType = generated.kind.rawValue
                    existing.title = generated.title
                    existing.canonicalExpression = generated.canonicalExpression
                    existing.meaning = generated.meaning
                    existing.explanation = generated.explanation
                    existing.naturalEnglish = generated.naturalEnglish
                    existing.content = generated.explanation
                    existing.tags = tags
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

            let existingCards = try context.fetch(
                FetchDescriptor<FlashcardEntity>()
            ).filter {
                $0.knowledgeItemID == knowledge.id
            }
            let activeCardKeys = Set(generated.cards.map(\.key))

            for generatedCard in generated.cards {
                if let existing = existingCards.first(
                    where: { $0.generationKey == generatedCard.key }
                ) {
                    let unchanged =
                        existing.cardType == generatedCard.type.rawValue
                        && existing.prompt == generatedCard.prompt
                        && existing.answer == generatedCard.answer
                        && existing.explanation == generatedCard.explanation
                        && existing.naturalEnglish == generatedCard.naturalEnglish
                        && existing.isActive

                    if unchanged {
                        cardsUnchanged += 1
                    } else {
                        existing.cardType = generatedCard.type.rawValue
                        existing.prompt = generatedCard.prompt
                        existing.answer = generatedCard.answer
                        existing.explanation = generatedCard.explanation
                        existing.naturalEnglish = generatedCard.naturalEnglish
                        existing.sourceKey = source.sourceKey
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

            let cards = try context.fetch(
                FetchDescriptor<FlashcardEntity>()
            ).filter {
                $0.knowledgeItemID == item.id && $0.isActive
            }
            for card in cards {
                card.isActive = false
                card.updatedAt = now
                cardsDeactivated += 1
            }
        }

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
        limit: Int? = nil
    ) throws -> [ReviewSessionCard] {
        try queueService
            .dueCards(
                in: context,
                now: now,
                sourceKeys: sourceKeys,
                limit: limit
            )
            .map(ReviewSessionCard.init)
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
                    || $0.sourceReference.localizedCaseInsensitiveContains(normalized)
            }
        }
        return filtered.map(ReviewSessionCard.init)
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

    public func homeSnapshot(now: Date = .now) throws -> HomeSnapshot {
        let cards = try context.fetch(FetchDescriptor<FlashcardEntity>())
            .filter(\.isActive)
        let states = try context.fetch(FetchDescriptor<ReviewStateEntity>())
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
        let reviewDays = Set(
            history.map {
                calendar.startOfDay(for: $0.reviewedAt)
            }
        )
        var streak = 0

        if !reviewDays.isEmpty {
            var cursor = calendar.startOfDay(for: now)
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

        return HomeSnapshot(
            dueCount: dueCount,
            streakDays: streak
        )
    }
}
