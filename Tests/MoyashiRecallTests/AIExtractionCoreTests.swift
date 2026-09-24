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
