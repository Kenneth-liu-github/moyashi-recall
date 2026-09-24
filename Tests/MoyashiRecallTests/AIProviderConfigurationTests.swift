import XCTest
@testable import MoyashiRecall

final class AIProviderConfigurationTests: XCTestCase {
    func testModelIDsAreRememberedPerProvider() throws {
        let suiteName = "AIProviderConfigurationTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(
            UserDefaults(suiteName: suiteName)
        )
        defer {
            defaults.removePersistentDomain(
                forName: suiteName
            )
        }

        let store = AIConfigurationStore()

        try store.save(
            AIProviderConfiguration(
                provider: .openAI,
                modelID: "openai-model"
            ),
            defaults: defaults
        )
        try store.save(
            AIProviderConfiguration(
                provider: .anthropic,
                modelID: "anthropic-model"
            ),
            defaults: defaults
        )

        XCTAssertEqual(
            store.modelID(
                for: .openAI,
                defaults: defaults
            ),
            "openai-model"
        )
        XCTAssertEqual(
            store.modelID(
                for: .anthropic,
                defaults: defaults
            ),
            "anthropic-model"
        )

        let selected = store.load(defaults: defaults)
        XCTAssertEqual(selected.provider, .anthropic)
        XCTAssertEqual(
            selected.modelID,
            "anthropic-model"
        )
    }

    func testProviderKindsHaveIndependentCredentialAccounts() {
        XCTAssertNotEqual(
            AICredential.account(for: .openAI),
            AICredential.account(for: .anthropic)
        )
    }
}
