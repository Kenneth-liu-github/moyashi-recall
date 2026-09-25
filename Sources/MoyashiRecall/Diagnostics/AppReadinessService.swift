import Foundation
import SwiftData

public struct AppReadinessSnapshot: Equatable, Sendable {
    public let notionCredentialConfigured: Bool
    public let notionRootSelected: Bool
    public let syncedDocumentCount: Int
    public let aiProviderName: String
    public let aiModelConfigured: Bool
    public let aiCredentialConfigured: Bool
    public let activeCardCount: Int

    public init(
        notionCredentialConfigured: Bool,
        notionRootSelected: Bool,
        syncedDocumentCount: Int,
        aiProviderName: String,
        aiModelConfigured: Bool,
        aiCredentialConfigured: Bool,
        activeCardCount: Int
    ) {
        self.notionCredentialConfigured = notionCredentialConfigured
        self.notionRootSelected = notionRootSelected
        self.syncedDocumentCount = max(0, syncedDocumentCount)
        self.aiProviderName = aiProviderName
        self.aiModelConfigured = aiModelConfigured
        self.aiCredentialConfigured = aiCredentialConfigured
        self.activeCardCount = max(0, activeCardCount)
    }

    public var notionReady: Bool {
        notionCredentialConfigured
            && notionRootSelected
            && syncedDocumentCount > 0
    }

    public var aiReady: Bool {
        aiModelConfigured
            && aiCredentialConfigured
    }

    public var readyForReview: Bool {
        activeCardCount > 0
    }
}

@MainActor
public struct AppReadinessService {
    private let context: ModelContext
    private let credentialStore: KeychainCredentialStore
    private let defaults: UserDefaults

    public init(
        context: ModelContext,
        credentialStore: KeychainCredentialStore = KeychainCredentialStore(),
        defaults: UserDefaults = .standard
    ) {
        self.context = context
        self.credentialStore = credentialStore
        self.defaults = defaults
    }

    public func snapshot() throws -> AppReadinessSnapshot {
        let repository = LearningRepository(
            context: context
        )

        let notionSecret = try credentialStore.read(
            account: NotionCredential.tokenAccount
        )
        let notionConfigured = !(notionSecret ?? "")
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )
            .isEmpty

        let rootPageID = defaults.string(
            forKey: "notionRootPageID"
        ) ?? ""
        let rootSelected = !rootPageID
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )
            .isEmpty

        let documents = try repository.importedDocuments(
            sourceKind: "notion"
        )

        let aiConfiguration = AIConfigurationStore()
            .load(defaults: defaults)
        let aiModelConfigured = !aiConfiguration.modelID
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )
            .isEmpty

        let aiSecret = try credentialStore.read(
            account: AICredential.account(
                for: aiConfiguration.provider
            )
        )
        let aiCredentialConfigured = !(aiSecret ?? "")
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )
            .isEmpty

        let cards = try repository.allSessionCards()

        return AppReadinessSnapshot(
            notionCredentialConfigured: notionConfigured,
            notionRootSelected: rootSelected,
            syncedDocumentCount: documents.count,
            aiProviderName:
                aiConfiguration.provider.displayName,
            aiModelConfigured: aiModelConfigured,
            aiCredentialConfigured: aiCredentialConfigured,
            activeCardCount: cards.count
        )
    }
}
