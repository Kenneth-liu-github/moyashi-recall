import Foundation
import SwiftData

@Model
public final class KnowledgeItemEntity {
    @Attribute(.unique) public var id: UUID
    public var title: String
    public var content: String
    public var sourceKind: String
    public var externalSourceID: String = ""
    public var sourceReference: String
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: UUID = UUID(),
        title: String,
        content: String,
        sourceKind: String,
        externalSourceID: String = "",
        sourceReference: String,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.title = title
        self.content = content
        self.sourceKind = sourceKind
        self.externalSourceID = externalSourceID
        self.sourceReference = sourceReference
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

@Model
public final class FlashcardEntity {
    @Attribute(.unique) public var id: UUID
    public var knowledgeItemID: UUID
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
        cardType: String,
        prompt: String,
        answer: String,
        explanation: String = "",
        naturalEnglish: String = "",
        sourceKey: String = "",
        sourceReference: String,
        createdAt: Date = .now
    ) {
        self.id = id
        self.knowledgeItemID = knowledgeItemID
        self.cardType = cardType
        self.prompt = prompt
        self.answer = answer
        self.explanation = explanation
        self.naturalEnglish = naturalEnglish
        self.sourceKey = sourceKey
        self.sourceReference = sourceReference
        self.createdAt = createdAt
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

public enum ReviewLearningState: String, Codable, Sendable {
    case new
    case learning
    case review
    case relearning
}
