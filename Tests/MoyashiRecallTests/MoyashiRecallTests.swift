import XCTest
@testable import MoyashiRecall

final class MoyashiRecallTests: XCTestCase {
    @MainActor
    func testDefaultLanguageIsChinese() {
        let store = LanguageStore()
        XCTAssertEqual(
            store.text("首页", "ホーム"),
            store.language == .zhHans ? "首页" : "ホーム"
        )
    }
}
