import XCTest
@testable import MoyashiRecall

final class SourceKeyResolverTests: XCTestCase {
    func testKnownLearningHomeCategoriesUseStableKeys() {
        XCTAssertEqual(
            SourceKeyResolver.resolve(
                sourceKind: "notion",
                sourcePath: [
                    "Learning Home",
                    "办公室日语学习",
                    "第二课"
                ]
            ),
            "office-japanese"
        )

        XCTAssertEqual(
            SourceKeyResolver.resolve(
                sourceKind: "notion",
                sourcePath: [
                    "Learning Home",
                    "日语训练营"
                ]
            ),
            "japanese-bootcamp"
        )

        XCTAssertEqual(
            SourceKeyResolver.resolve(
                sourceKind: "notion",
                sourcePath: [
                    "Learning Home",
                    "日语口语 私教"
                ]
            ),
            "japanese-speaking"
        )
    }

    func testUnknownNonLatinCategoriesDoNotCollide() {
        let grammar = SourceKeyResolver.resolve(
            sourceKind: "notion",
            sourcePath: ["Learning Home", "语法笔记"]
        )
        let vocabulary = SourceKeyResolver.resolve(
            sourceKind: "notion",
            sourcePath: ["Learning Home", "词汇笔记"]
        )

        XCTAssertNotEqual(grammar, vocabulary)
        XCTAssertTrue(grammar.hasPrefix("notion-u"))
        XCTAssertTrue(vocabulary.hasPrefix("notion-u"))
    }

    func testUnknownCategoryGetsDeterministicFallback() {
        XCTAssertEqual(
            SourceKeyResolver.resolve(
                sourceKind: "notion",
                sourcePath: ["Learning Home", "Grammar Notes"]
            ),
            "notion-grammar-notes"
        )
    }
}
