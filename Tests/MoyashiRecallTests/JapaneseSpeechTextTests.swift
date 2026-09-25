import XCTest
@testable import MoyashiRecall

final class JapaneseSpeechTextTests: XCTestCase {
    func testRemovesKanaAnnotationsBeforeSpeech() {
        XCTAssertEqual(
            JapaneseSpeechText.normalized(
                "進（すす）め方（かた）について"
            ),
            "進め方について"
        )
    }

    func testPreservesNonReadingParentheses() {
        XCTAssertEqual(
            JapaneseSpeechText.normalized(
                "Version（V2）"
            ),
            "Version（V2）"
        )
    }

    func testDetectsJapaneseText() {
        XCTAssertTrue(
            JapaneseSpeechText.containsJapanese(
                "進（すす）め方（かた）について"
            )
        )
        XCTAssertTrue(
            JapaneseSpeechText.containsJapanese(
                "これはテストです"
            )
        )
        XCTAssertFalse(
            JapaneseSpeechText.containsJapanese(
                "This is English."
            )
        )
    }
}
