import Foundation

public struct LearningDataImportValidationLimits: Equatable, Sendable {
    public let maximumBytes: Int
    public let maximumSources: Int
    public let maximumKnowledgeItems: Int
    public let maximumFlashcards: Int
    public let maximumReviewStates: Int
    public let maximumReviewHistory: Int

    public init(
        maximumBytes: Int = 100 * 1024 * 1024,
        maximumSources: Int = 10_000,
        maximumKnowledgeItems: Int = 100_000,
        maximumFlashcards: Int = 250_000,
        maximumReviewStates: Int = 250_000,
        maximumReviewHistory: Int = 500_000
    ) {
        self.maximumBytes = max(1, maximumBytes)
        self.maximumSources = max(1, maximumSources)
        self.maximumKnowledgeItems = max(1, maximumKnowledgeItems)
        self.maximumFlashcards = max(1, maximumFlashcards)
        self.maximumReviewStates = max(1, maximumReviewStates)
        self.maximumReviewHistory = max(1, maximumReviewHistory)
    }

    public static let standard =
        LearningDataImportValidationLimits()
}

public struct LearningDataImportValidationReport: Equatable, Sendable {
    public let sourceCount: Int
    public let knowledgeItemCount: Int
    public let flashcardCount: Int
    public let reviewStateCount: Int
    public let reviewHistoryCount: Int

    public init(
        sourceCount: Int,
        knowledgeItemCount: Int,
        flashcardCount: Int,
        reviewStateCount: Int,
        reviewHistoryCount: Int
    ) {
        self.sourceCount = sourceCount
        self.knowledgeItemCount = knowledgeItemCount
        self.flashcardCount = flashcardCount
        self.reviewStateCount = reviewStateCount
        self.reviewHistoryCount = reviewHistoryCount
    }
}

public enum LearningDataImportValidationError: Error, Equatable {
    case decodingFailed
    case unsupportedSchema(String)
    case backupTooLarge(Int)
    case tooManySources(Int)
    case tooManyKnowledgeItems(Int)
    case tooManyFlashcards(Int)
    case tooManyReviewStates(Int)
    case tooManyReviewHistory(Int)
    case duplicateSourceID(UUID)
    case duplicateKnowledgeID(UUID)
    case duplicateFlashcardID(UUID)
    case duplicateReviewStateCardID(UUID)
    case duplicateReviewHistoryID(UUID)
    case missingKnowledgeSource(
        knowledgeID: UUID,
        sourceID: UUID
    )
    case missingFlashcardKnowledge(
        cardID: UUID,
        knowledgeID: UUID
    )
    case missingFlashcardSource(
        cardID: UUID,
        sourceID: UUID
    )
    case missingReviewStateCard(UUID)
    case missingReviewHistoryCard(
        historyID: UUID,
        cardID: UUID
    )
    case invalidRating(
        historyID: UUID,
        value: Int
    )
    case invalidReviewState(
        cardID: UUID,
        value: String
    )
    case invalidNumericValue(String)
}

public enum LearningDataImportValidator {
    public static func decodeAndValidate(
        _ data: Data,
        limits: LearningDataImportValidationLimits = .standard
    ) throws -> (
        package: LearningDataExportPackage,
        report: LearningDataImportValidationReport
    ) {
        guard data.count <= limits.maximumBytes else {
            throw LearningDataImportValidationError
                .backupTooLarge(data.count)
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        guard let package = try? decoder.decode(
            LearningDataExportPackage.self,
            from: data
        ) else {
            throw LearningDataImportValidationError.decodingFailed
        }

        let report = try validate(
            package,
            limits: limits
        )
        return (package, report)
    }

    public static func validate(
        _ package: LearningDataExportPackage,
        limits: LearningDataImportValidationLimits = .standard
    ) throws -> LearningDataImportValidationReport {
        guard package.schemaVersion == "v1" else {
            throw LearningDataImportValidationError
                .unsupportedSchema(
                    package.schemaVersion
                )
        }

        guard package.sources.count <= limits.maximumSources else {
            throw LearningDataImportValidationError
                .tooManySources(
                    package.sources.count
                )
        }
        guard package.knowledgeItems.count
            <= limits.maximumKnowledgeItems
        else {
            throw LearningDataImportValidationError
                .tooManyKnowledgeItems(
                    package.knowledgeItems.count
                )
        }
        guard package.flashcards.count <= limits.maximumFlashcards else {
            throw LearningDataImportValidationError
                .tooManyFlashcards(
                    package.flashcards.count
                )
        }
        guard package.reviewStates.count
            <= limits.maximumReviewStates
        else {
            throw LearningDataImportValidationError
                .tooManyReviewStates(
                    package.reviewStates.count
                )
        }
        guard package.reviewHistory.count
            <= limits.maximumReviewHistory
        else {
            throw LearningDataImportValidationError
                .tooManyReviewHistory(
                    package.reviewHistory.count
                )
        }

        let sourceIDs = try uniqueIDs(
            package.sources.map(\.id),
            duplicate: {
                .duplicateSourceID($0)
            }
        )
        let knowledgeIDs = try uniqueIDs(
            package.knowledgeItems.map(\.id),
            duplicate: {
                .duplicateKnowledgeID($0)
            }
        )
        let flashcardIDs = try uniqueIDs(
            package.flashcards.map(\.id),
            duplicate: {
                .duplicateFlashcardID($0)
            }
        )

        _ = try uniqueIDs(
            package.reviewStates.map(\.cardID),
            duplicate: {
                .duplicateReviewStateCardID($0)
            }
        )
        _ = try uniqueIDs(
            package.reviewHistory.map(\.id),
            duplicate: {
                .duplicateReviewHistoryID($0)
            }
        )

        for item in package.knowledgeItems {
            if let sourceID = item.sourceDocumentID,
               !sourceIDs.contains(sourceID) {
                throw LearningDataImportValidationError
                    .missingKnowledgeSource(
                        knowledgeID: item.id,
                        sourceID: sourceID
                    )
            }
        }

        for card in package.flashcards {
            guard knowledgeIDs.contains(card.knowledgeItemID) else {
                throw LearningDataImportValidationError
                    .missingFlashcardKnowledge(
                        cardID: card.id,
                        knowledgeID: card.knowledgeItemID
                    )
            }

            if let sourceID = card.sourceDocumentID,
               !sourceIDs.contains(sourceID) {
                throw LearningDataImportValidationError
                    .missingFlashcardSource(
                        cardID: card.id,
                        sourceID: sourceID
                    )
            }
        }

        let allowedStates = Set(
            [
                ReviewLearningState.new.rawValue,
                ReviewLearningState.learning.rawValue,
                ReviewLearningState.review.rawValue,
                ReviewLearningState.relearning.rawValue
            ]
        )

        for state in package.reviewStates {
            guard flashcardIDs.contains(state.cardID) else {
                throw LearningDataImportValidationError
                    .missingReviewStateCard(
                        state.cardID
                    )
            }

            guard allowedStates.contains(
                state.stateRawValue
            ) else {
                throw LearningDataImportValidationError
                    .invalidReviewState(
                        cardID: state.cardID,
                        value: state.stateRawValue
                    )
            }

            try validateFiniteNonNegative(
                state.stability,
                field: "reviewState.stability"
            )
            try validateFiniteNonNegative(
                state.difficulty,
                field: "reviewState.difficulty"
            )
            try validateNonNegative(
                state.elapsedDays,
                field: "reviewState.elapsedDays"
            )
            try validateNonNegative(
                state.scheduledDays,
                field: "reviewState.scheduledDays"
            )
            try validateNonNegative(
                state.repetitions,
                field: "reviewState.repetitions"
            )
            try validateNonNegative(
                state.lapses,
                field: "reviewState.lapses"
            )
        }

        for history in package.reviewHistory {
            guard flashcardIDs.contains(history.cardID) else {
                throw LearningDataImportValidationError
                    .missingReviewHistoryCard(
                        historyID: history.id,
                        cardID: history.cardID
                    )
            }

            guard ReviewRating(
                rawValue: history.ratingRawValue
            ) != nil else {
                throw LearningDataImportValidationError
                    .invalidRating(
                        historyID: history.id,
                        value: history.ratingRawValue
                    )
            }

            try validateNonNegative(
                history.elapsedDays,
                field: "reviewHistory.elapsedDays"
            )
            try validateNonNegative(
                history.scheduledDays,
                field: "reviewHistory.scheduledDays"
            )
            try validateFiniteNonNegative(
                history.stabilityBefore,
                field: "reviewHistory.stabilityBefore"
            )
            try validateFiniteNonNegative(
                history.stabilityAfter,
                field: "reviewHistory.stabilityAfter"
            )
            try validateFiniteNonNegative(
                history.difficultyBefore,
                field: "reviewHistory.difficultyBefore"
            )
            try validateFiniteNonNegative(
                history.difficultyAfter,
                field: "reviewHistory.difficultyAfter"
            )
        }

        return LearningDataImportValidationReport(
            sourceCount: package.sources.count,
            knowledgeItemCount: package.knowledgeItems.count,
            flashcardCount: package.flashcards.count,
            reviewStateCount: package.reviewStates.count,
            reviewHistoryCount: package.reviewHistory.count
        )
    }

    private static func uniqueIDs(
        _ values: [UUID],
        duplicate: (UUID)
            -> LearningDataImportValidationError
    ) throws -> Set<UUID> {
        var result = Set<UUID>()

        for value in values {
            guard result.insert(value).inserted else {
                throw duplicate(value)
            }
        }

        return result
    }

    private static func validateFiniteNonNegative(
        _ value: Double,
        field: String
    ) throws {
        guard value.isFinite,
              value >= 0
        else {
            throw LearningDataImportValidationError
                .invalidNumericValue(field)
        }
    }

    private static func validateNonNegative(
        _ value: Int,
        field: String
    ) throws {
        guard value >= 0 else {
            throw LearningDataImportValidationError
                .invalidNumericValue(field)
        }
    }
}
