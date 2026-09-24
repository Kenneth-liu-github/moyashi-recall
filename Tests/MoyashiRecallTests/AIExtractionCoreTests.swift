import XCTest
@testable import MoyashiRecall

final class AIExtractionCoreTests: XCTestCase {
    func testRequestCarriesSourceContextAndSchema() {
        let request = KnowledgeExtractionService.request(
            for: ImportedDocument(
                id: "doc",
                sourceKind: "notion",
                title: "第二课",
                sourceReference: "notion://doc",
                content: "進（すす）め方（かた）について",
                sourcePath: [
                    "Learning Home",
                    "办公室日语学习",
                    "第二课"
                ]
            )
        )

        XCTAssertTrue(request.userPrompt.contains("第二课"))
        XCTAssertTrue(
            request.userPrompt.contains(
                "進（すす）め方（かた）について"
            )
        )
        XCTAssertTrue(
            request.responseSchemaJSON.contains(
                #""additionalProperties": false"#
            )
        )
    }

    func testNormalizationTrimsStableKeysBeforePersistence() {
        let bundle = KnowledgeExtractionBundle(
            version: " v1 ",
            items: [
                ExtractedKnowledgeItem(
                    key: " item-key ",
                    kind: .expression,
                    title: "T",
                    canonicalExpression: "T",
                    meaning: "M",
                    explanation: "E",
                    cards: [
                        GeneratedFlashcard(
                            key: " card-key ",
                            type: .zhToJa,
                            prompt: "Q",
                            answer: "A"
                        )
                    ]
                )
            ]
        )

        let normalized = KnowledgeExtractionService.normalize(
            bundle
        )

        XCTAssertEqual(normalized.version, "v1")
        XCTAssertEqual(
            normalized.items.first?.key,
            "item-key"
        )
        XCTAssertEqual(
            normalized.items.first?.cards.first?.key,
            "card-key"
        )
        XCTAssertEqual(
            normalized.items.first?.title,
            "T"
        )
        XCTAssertEqual(
            normalized.items.first?.tags,
            []
        )
    }

    func testValidationRejectsEmptyKnowledgeContent() {
        let item = ExtractedKnowledgeItem(
            key: "empty-item",
            kind: .other,
            title: " ",
            canonicalExpression: "",
            meaning: "",
            explanation: "   "
        )

        XCTAssertThrowsError(
            try KnowledgeExtractionService.validate(
                KnowledgeExtractionBundle(
                    version: "v1",
                    items: [item]
                )
            )
        ) { error in
            XCTAssertEqual(
                error as? KnowledgeExtractionError,
                .emptyKnowledgeContent("empty-item")
            )
        }
    }

    func testValidationRejectsDuplicateSemanticItemsWithDifferentKeys() {
        let first = ExtractedKnowledgeItem(
            key: "one",
            kind: .grammar,
            title: "～について",
            canonicalExpression: "～について",
            meaning: "关于……",
            explanation: "A"
        )
        let second = ExtractedKnowledgeItem(
            key: "two",
            kind: .grammar,
            title: "～について",
            canonicalExpression: "～について",
            meaning: "关于……",
            explanation: "B"
        )

        XCTAssertThrowsError(
            try KnowledgeExtractionService.validate(
                KnowledgeExtractionBundle(
                    version: "v1",
                    items: [first, second]
                )
            )
        ) { error in
            guard let extractionError =
                error as? KnowledgeExtractionError
            else {
                return XCTFail(
                    "Expected KnowledgeExtractionError"
                )
            }

            guard case .duplicateSemanticItem =
                extractionError
            else {
                return XCTFail(
                    "Expected duplicate semantic item"
                )
            }
        }
    }

    func testValidationRejectsDuplicateKnowledgeKeys() {
        let item = ExtractedKnowledgeItem(
            key: "duplicate",
            kind: .grammar,
            title: "A",
            canonicalExpression: "A",
            meaning: "A",
            explanation: "A"
        )

        XCTAssertThrowsError(
            try KnowledgeExtractionService.validate(
                KnowledgeExtractionBundle(
                    version: "v1",
                    items: [item, item]
                )
            )
        ) { error in
            XCTAssertEqual(
                error as? KnowledgeExtractionError,
                .duplicateKnowledgeKey("duplicate")
            )
        }
    }
}
