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
