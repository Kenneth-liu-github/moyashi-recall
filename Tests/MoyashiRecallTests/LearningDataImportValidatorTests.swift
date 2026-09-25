import XCTest
@testable import MoyashiRecall

final class LearningDataImportValidatorTests: XCTestCase {
    func testValidPackagePassesValidation() throws {
        let package = makeValidPackage()

        let report = try LearningDataImportValidator.validate(
            package
        )

        XCTAssertEqual(report.sourceCount, 1)
        XCTAssertEqual(report.knowledgeItemCount, 1)
        XCTAssertEqual(report.flashcardCount, 1)
        XCTAssertEqual(report.reviewStateCount, 1)
        XCTAssertEqual(report.reviewHistoryCount, 1)
    }

    func testRejectsOversizedBackupBeforeDecoding() {
        let data = Data(repeating: 0x20, count: 32)
        let limits = LearningDataImportValidationLimits(
            maximumBytes: 16
        )

        XCTAssertThrowsError(
            try LearningDataImportValidator.decodeAndValidate(
                data,
                limits: limits
            )
        ) { error in
            XCTAssertEqual(
                error as? LearningDataImportValidationError,
                .backupTooLarge(32)
            )
        }
    }

    func testDecodeAndValidateRejectsMalformedJSON() {
        XCTAssertThrowsError(
            try LearningDataImportValidator.decodeAndValidate(
                Data("{not-json}".utf8)
            )
        ) { error in
            XCTAssertEqual(
                error as? LearningDataImportValidationError,
                .decodingFailed
            )
        }
    }

    func testRejectsUnsupportedSchema() {
        var package = makeValidPackage()
        package = LearningDataExportPackage(
            schemaVersion: "v99",
            exportedAt: package.exportedAt,
            sources: package.sources,
            knowledgeItems: package.knowledgeItems,
            flashcards: package.flashcards,
            reviewStates: package.reviewStates,
            reviewHistory: package.reviewHistory
        )

        XCTAssertThrowsError(
            try LearningDataImportValidator.validate(
                package
            )
        ) { error in
            XCTAssertEqual(
                error as? LearningDataImportValidationError,
                .unsupportedSchema("v99")
            )
        }
    }

    func testRejectsDuplicatePrimaryIDs() {
        let package = makeValidPackage()
        let duplicated = LearningDataExportPackage(
            schemaVersion: package.schemaVersion,
            exportedAt: package.exportedAt,
            sources: package.sources + package.sources,
            knowledgeItems: package.knowledgeItems,
            flashcards: package.flashcards,
            reviewStates: package.reviewStates,
            reviewHistory: package.reviewHistory
        )

        XCTAssertThrowsError(
            try LearningDataImportValidator.validate(
                duplicated
            )
        ) { error in
            XCTAssertEqual(
                error as? LearningDataImportValidationError,
                .duplicateSourceID(
                    package.sources[0].id
                )
            )
        }
    }

    func testRejectsDanglingCardKnowledgeReference() {
        let package = makeValidPackage()
        let card = package.flashcards[0]
        let missingKnowledge = UUID()
        let badCard = LearningDataExportPackage.FlashcardRecord(
            id: card.id,
            knowledgeItemID: missingKnowledge,
            sourceDocumentID: card.sourceDocumentID,
            generationKey: card.generationKey,
            cardType: card.cardType,
            prompt: card.prompt,
            answer: card.answer,
            explanation: card.explanation,
            naturalEnglish: card.naturalEnglish,
            sourceKey: card.sourceKey,
            sourceDisplayPath: card.sourceDisplayPath,
            sourceReference: card.sourceReference,
            isActive: card.isActive,
            createdAt: card.createdAt,
            updatedAt: card.updatedAt
        )
        let invalid = LearningDataExportPackage(
            schemaVersion: package.schemaVersion,
            exportedAt: package.exportedAt,
            sources: package.sources,
            knowledgeItems: package.knowledgeItems,
            flashcards: [badCard],
            reviewStates: [],
            reviewHistory: []
        )

        XCTAssertThrowsError(
            try LearningDataImportValidator.validate(
                invalid
            )
        ) { error in
            XCTAssertEqual(
                error as? LearningDataImportValidationError,
                .missingFlashcardKnowledge(
                    cardID: card.id,
                    knowledgeID: missingKnowledge
                )
            )
        }
    }

    func testRejectsInvalidRatingAndState() {
        let package = makeValidPackage()
        let state = package.reviewStates[0]
        let invalidState =
            LearningDataExportPackage.ReviewStateRecord(
                cardID: state.cardID,
                due: state.due,
                stability: state.stability,
                difficulty: state.difficulty,
                elapsedDays: state.elapsedDays,
                scheduledDays: state.scheduledDays,
                repetitions: state.repetitions,
                lapses: state.lapses,
                stateRawValue: "unknown",
                lastReview: state.lastReview
            )

        let statePackage = LearningDataExportPackage(
            schemaVersion: package.schemaVersion,
            exportedAt: package.exportedAt,
            sources: package.sources,
            knowledgeItems: package.knowledgeItems,
            flashcards: package.flashcards,
            reviewStates: [invalidState],
            reviewHistory: []
        )

        XCTAssertThrowsError(
            try LearningDataImportValidator.validate(
                statePackage
            )
        ) { error in
            XCTAssertEqual(
                error as? LearningDataImportValidationError,
                .invalidReviewState(
                    cardID: state.cardID,
                    value: "unknown"
                )
            )
        }

        let history = package.reviewHistory[0]
        let invalidHistory =
            LearningDataExportPackage.ReviewHistoryRecord(
                id: history.id,
                cardID: history.cardID,
                reviewedAt: history.reviewedAt,
                ratingRawValue: 99,
                elapsedDays: history.elapsedDays,
                scheduledDays: history.scheduledDays,
                stabilityBefore: history.stabilityBefore,
                stabilityAfter: history.stabilityAfter,
                difficultyBefore: history.difficultyBefore,
                difficultyAfter: history.difficultyAfter
            )

        let historyPackage = LearningDataExportPackage(
            schemaVersion: package.schemaVersion,
            exportedAt: package.exportedAt,
            sources: package.sources,
            knowledgeItems: package.knowledgeItems,
            flashcards: package.flashcards,
            reviewStates: [],
            reviewHistory: [invalidHistory]
        )

        XCTAssertThrowsError(
            try LearningDataImportValidator.validate(
                historyPackage
            )
        ) { error in
            XCTAssertEqual(
                error as? LearningDataImportValidationError,
                .invalidRating(
                    historyID: history.id,
                    value: 99
                )
            )
        }
    }

    func testRejectsNonFiniteOrNegativeSchedulingValues() {
        let package = makeValidPackage()
        let state = package.reviewStates[0]
        let invalidState =
            LearningDataExportPackage.ReviewStateRecord(
                cardID: state.cardID,
                due: state.due,
                stability: .infinity,
                difficulty: state.difficulty,
                elapsedDays: state.elapsedDays,
                scheduledDays: state.scheduledDays,
                repetitions: state.repetitions,
                lapses: state.lapses,
                stateRawValue: state.stateRawValue,
                lastReview: state.lastReview
            )

        let invalid = LearningDataExportPackage(
            schemaVersion: package.schemaVersion,
            exportedAt: package.exportedAt,
            sources: package.sources,
            knowledgeItems: package.knowledgeItems,
            flashcards: package.flashcards,
            reviewStates: [invalidState],
            reviewHistory: []
        )

        XCTAssertThrowsError(
            try LearningDataImportValidator.validate(
                invalid
            )
        ) { error in
            XCTAssertEqual(
                error as? LearningDataImportValidationError,
                .invalidNumericValue(
                    "reviewState.stability"
                )
            )
        }
    }

    func testLimitsAreEnforcedBeforeDeepValidation() {
        let package = makeValidPackage()
        let limits = LearningDataImportValidationLimits(
            maximumSources: 1,
            maximumKnowledgeItems: 1,
            maximumFlashcards: 1,
            maximumReviewStates: 1,
            maximumReviewHistory: 1
        )
        let oversized = LearningDataExportPackage(
            schemaVersion: package.schemaVersion,
            exportedAt: package.exportedAt,
            sources: package.sources + [
                makeSource(id: UUID())
            ],
            knowledgeItems: package.knowledgeItems,
            flashcards: package.flashcards,
            reviewStates: package.reviewStates,
            reviewHistory: package.reviewHistory
        )

        XCTAssertThrowsError(
            try LearningDataImportValidator.validate(
                oversized,
                limits: limits
            )
        ) { error in
            XCTAssertEqual(
                error as? LearningDataImportValidationError,
                .tooManySources(2)
            )
        }
    }

    private func makeValidPackage() -> LearningDataExportPackage {
        let now = Date(
            timeIntervalSince1970: 1_700_000_000
        )
        let sourceID = UUID()
        let knowledgeID = UUID()
        let cardID = UUID()
        let historyID = UUID()

        let source = makeSource(
            id: sourceID,
            now: now
        )

        let knowledge =
            LearningDataExportPackage.KnowledgeRecord(
                id: knowledgeID,
                sourceDocumentID: sourceID,
                extractionKey: "item-1",
                knowledgeType: "expression",
                title: "進（すす）め方（かた）について",
                canonicalExpression: "進（すす）め方（かた）について",
                meaning: "关于推进方式",
                explanation: "说明",
                naturalEnglish: "regarding how to proceed",
                content: "content",
                tags: "商务",
                sourceKind: "notion",
                sourceKey: "office-japanese",
                sourceDisplayPath: "Learning Home / 办公室日语学习 / 第二课",
                sourceReference: "notion://page-1",
                externalSourceID: "",
                parentExternalSourceID: "",
                rootExternalSourceID: "",
                sourcePath: "",
                hierarchyDepth: 0,
                isSourceActive: true,
                sourceLastEditedAt: nil,
                lastSyncedAt: nil,
                aiProvider: "openai",
                aiModel: "configured-model",
                extractionVersion: "v1",
                isActive: true,
                createdAt: now,
                updatedAt: now
            )

        let card =
            LearningDataExportPackage.FlashcardRecord(
                id: cardID,
                knowledgeItemID: knowledgeID,
                sourceDocumentID: sourceID,
                generationKey: "card-1",
                cardType: ReviewCardType.zhToJa.rawValue,
                prompt: "关于推进方式",
                answer: "進（すす）め方（かた）について",
                explanation: "",
                naturalEnglish: "",
                sourceKey: "office-japanese",
                sourceDisplayPath: "Learning Home / 办公室日语学习 / 第二课",
                sourceReference: "notion://page-1",
                isActive: true,
                createdAt: now,
                updatedAt: now
            )

        let state =
            LearningDataExportPackage.ReviewStateRecord(
                cardID: cardID,
                due: now,
                stability: 3,
                difficulty: 5,
                elapsedDays: 1,
                scheduledDays: 3,
                repetitions: 2,
                lapses: 0,
                stateRawValue: ReviewLearningState.review.rawValue,
                lastReview: now
            )

        let history =
            LearningDataExportPackage.ReviewHistoryRecord(
                id: historyID,
                cardID: cardID,
                reviewedAt: now,
                ratingRawValue: ReviewRating.good.rawValue,
                elapsedDays: 1,
                scheduledDays: 3,
                stabilityBefore: 2,
                stabilityAfter: 3,
                difficultyBefore: 5,
                difficultyAfter: 4
            )

        return LearningDataExportPackage(
            schemaVersion: "v1",
            exportedAt: now,
            sources: [source],
            knowledgeItems: [knowledge],
            flashcards: [card],
            reviewStates: [state],
            reviewHistory: [history]
        )
    }

    private func makeSource(
        id: UUID,
        now: Date = Date(
            timeIntervalSince1970: 1_700_000_000
        )
    ) -> LearningDataExportPackage.SourceRecord {
        LearningDataExportPackage.SourceRecord(
            id: id,
            title: "第二课",
            content: "source content",
            sourceKind: "notion",
            externalSourceID: "page-1",
            parentExternalSourceID: "",
            rootExternalSourceID: "root",
            sourcePath: "Learning Home / 办公室日语学习 / 第二课",
            sourceKey: "office-japanese",
            hierarchyDepth: 2,
            isSourceActive: true,
            sourceReference: "notion://page-1",
            sourceLastEditedAt: nil,
            lastSyncedAt: now,
            lastAIProcessedAt: now,
            aiProcessedSourceUpdatedAt: now,
            lastAIExtractionVersion: "v1",
            lastAIProviderID: "openai",
            lastAIModelID: "configured-model",
            createdAt: now,
            updatedAt: now
        )
    }
}
