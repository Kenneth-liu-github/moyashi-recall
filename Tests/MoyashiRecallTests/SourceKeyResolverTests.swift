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
