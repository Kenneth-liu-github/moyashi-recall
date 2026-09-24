import Foundation
import SwiftData

@Model
public final class SourceDocumentEntity {
    @Attribute(.unique) public var id: UUID
    public var title: String
    public var content: String
    public var sourceDocumentID: UUID?
    public var extractionKey: String = ""
    public var knowledgeType: String = ""
    public var canonicalExpression: String = ""
    public var meaning: String = ""
    public var explanation: String = ""
    public var naturalEnglish: String = ""
    public var tags: String = ""
    public var aiProvider: String = ""
    public var aiModel: String = ""
    public var extractionVersion: String = ""
    public var sourceKind: String
    public var externalSourceID: String
    public var parentExternalSourceID: String
    public var rootExternalSourceID: String
    public var sourcePath: String
    public var sourceKey: String
    public var hierarchyDepth: Int
    public var isSourceActive: Bool
    public var sourceLastEditedAt: Date?
    public var lastSyncedAt: Date?
    public var sourceReference: String
    public var isActive: Bool = true
    public var createdAt: Date
    public var updatedAt: Date
    public var updatedAt: Date

    public init(
        id: UUID = UUID(),
        title: String,
        content: String,
        sourceDocumentID: UUID? = nil,
        extractionKey: String = "",
        knowledgeType: String = "",
        canonicalExpression: String = "",
        meaning: String = "",
        explanation: String = "",
        naturalEnglish: String = "",
        tags: String = "",
        aiProvider: String = "",
        aiModel: String = "",
        extractionVersion: String = "",
        sourceKind: String,
        externalSourceID: String,
        parentExternalSourceID: String = "",
        rootExternalSourceID: String = "",
        sourcePath: String = "",
        sourceKey: String = "",
        hierarchyDepth: Int = 0,
        isSourceActive: Bool = true,
        sourceLastEditedAt: Date? = nil,
        lastSyncedAt: Date? = nil,
        sourceReference: String,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.title = title
        self.content = content
        self.sourceDocumentID = sourceDocumentID
        self.extractionKey = extractionKey
        self.knowledgeType = knowledgeType
        self.canonicalExpression = canonicalExpression
        self.meaning = meaning
        self.explanation = explanation
        self.naturalEnglish = naturalEnglish
        self.tags = tags
        self.aiProvider = aiProvider
        self.aiModel = aiModel
        self.extractionVersion = extractionVersion
        self.sourceKind = sourceKind
        self.externalSourceID = externalSourceID
        self.parentExternalSourceID = parentExternalSourceID
        self.rootExternalSourceID = rootExternalSourceID
        self.sourcePath = sourcePath
        self.sourceKey = sourceKey
        self.hierarchyDepth = hierarchyDepth
        self.isSourceActive = isSourceActive
        self.sourceLastEditedAt = sourceLastEditedAt
        self.lastSyncedAt = lastSyncedAt
        self.sourceReference = sourceReference
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

@Model
public final class KnowledgeItemEntity {
    @Attribute(.unique) public var id: UUID
    public var title: String
    public var content: String
    public var sourceKind: String
    public var externalSourceID: String = ""
    public var parentExternalSourceID: String = ""
    public var rootExternalSourceID: String = ""
    public var sourcePath: String = ""
    public var sourceKey: String = ""
    public var hierarchyDepth: Int = 0
    public var isSourceActive: Bool = true
    public var sourceLastEditedAt: Date?
    public var lastSyncedAt: Date?
    public var sourceReference: String
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: UUID = UUID(),
        title: String,
        content: String,
        sourceKind: String,
        externalSourceID: String = "",
        parentExternalSourceID: String = "",
        rootExternalSourceID: String = "",
        sourcePath: String = "",
        sourceKey: String = "",
        hierarchyDepth: Int = 0,
        isSourceActive: Bool = true,
        sourceLastEditedAt: Date? = nil,
        lastSyncedAt: Date? = nil,
        sourceReference: String,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.title = title
        self.content = content
        self.sourceKind = sourceKind
        self.externalSourceID = externalSourceID
        self.parentExternalSourceID = parentExternalSourceID
        self.rootExternalSourceID = rootExternalSourceID
        self.sourcePath = sourcePath
        self.sourceKey = sourceKey
        self.hierarchyDepth = hierarchyDepth
        self.isSourceActive = isSourceActive
        self.sourceLastEditedAt = sourceLastEditedAt
        self.lastSyncedAt = lastSyncedAt
        self.sourceReference = sourceReference
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

@Model
public final class FlashcardEntity {
    @Attribute(.unique) public var id: UUID
    public var knowledgeItemID: UUID
    public var sourceDocumentID: UUID?
    public var generationKey: String = ""
    public var cardType: String
    public var prompt: String
    public var answer: String
    public var explanation: String
    public var naturalEnglish: String
    public var sourceKey: String = ""
    public var sourceReference: String
    public var createdAt: Date

    public init(
        id: UUID = UUID(),
        knowledgeItemID: UUID,
        sourceDocumentID: UUID? = nil,
        generationKey: String = "",
        cardType: String,
        prompt: String,
        answer: String,
        explanation: String = "",
        naturalEnglish: String = "",
        sourceKey: String = "",
        sourceReference: String,
        isActive: Bool = true,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.knowledgeItemID = knowledgeItemID
        self.sourceDocumentID = sourceDocumentID
        self.generationKey = generationKey
        self.cardType = cardType
        self.prompt = prompt
        self.answer = answer
        self.explanation = explanation
        self.naturalEnglish = naturalEnglish
        self.sourceKey = sourceKey
        self.sourceReference = sourceReference
        self.isActive = isActive
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

@Model
public final class ReviewStateEntity {
    @Attribute(.unique) public var cardID: UUID
    public var due: Date
    public var stability: Double
    public var difficulty: Double
    public var elapsedDays: Int
    public var scheduledDays: Int
    public var repetitions: Int
    public var lapses: Int
    public var stateRawValue: String
    public var lastReview: Date?

    public init(
        cardID: UUID,
        due: Date = .now,
        stability: Double = 0,
        difficulty: Double = 5,
        elapsedDays: Int = 0,
        scheduledDays: Int = 0,
        repetitions: Int = 0,
        lapses: Int = 0,
        stateRawValue: String = ReviewLearningState.new.rawValue,
        lastReview: Date? = nil
    ) {
        self.cardID = cardID
        self.due = due
        self.stability = stability
        self.difficulty = difficulty
        self.elapsedDays = elapsedDays
        self.scheduledDays = scheduledDays
        self.repetitions = repetitions
        self.lapses = lapses
        self.stateRawValue = stateRawValue
        self.lastReview = lastReview
    }
}

@Model
public final class ReviewHistoryEntity {
    @Attribute(.unique) public var id: UUID
    public var cardID: UUID
    public var reviewedAt: Date
    public var ratingRawValue: Int
    public var elapsedDays: Int
    public var scheduledDays: Int
    public var stabilityBefore: Double
    public var stabilityAfter: Double
    public var difficultyBefore: Double
    public var difficultyAfter: Double

    public init(
        id: UUID = UUID(),
        cardID: UUID,
        reviewedAt: Date,
        ratingRawValue: Int,
        elapsedDays: Int,
        scheduledDays: Int,
        stabilityBefore: Double,
        stabilityAfter: Double,
        difficultyBefore: Double,
        difficultyAfter: Double
    ) {
        self.id = id
        self.cardID = cardID
        self.reviewedAt = reviewedAt
        self.ratingRawValue = ratingRawValue
        self.elapsedDays = elapsedDays
        self.scheduledDays = scheduledDays
        self.stabilityBefore = stabilityBefore
        self.stabilityAfter = stabilityAfter
        self.difficultyBefore = difficultyBefore
        self.difficultyAfter = difficultyAfter
    }
}