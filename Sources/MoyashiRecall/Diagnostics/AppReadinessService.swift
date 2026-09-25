import Foundation
import SwiftData

public struct AppReadinessSnapshot: Equatable, Sendable {
    public let notionCredentialConfigured: Bool
    public let notionRootSelected: Bool
    public let syncedDocumentCount: Int
    public let aiProviderName: String
    public let aiModelConfigured: Bool
    public let aiCredentialConfigured: Bool
    public let activeKnowledgeCount: Int
    public let activeCardCount: Int
    public let dueCardCount: Int
    public let reviewHistoryCount: Int
    public let latestReviewAt: Date?

    public init(
        notionCredentialConfigured: Bool,
        notionRootSelected: Bool,
        syncedDocumentCount: Int,
        aiProviderName: String,
        aiModelConfigured: Bool,
        aiCredentialConfigured: Bool,
        activeKnowledgeCount: Int = 0,
        activeCardCount: Int,
        dueCardCount: Int = 0,
        reviewHistoryCount: Int = 0,
        latestReviewAt: Date? = nil
    ) {
        self.notionCredentialConfigured = notionCredentialConfigured
        self.notionRootSelected = notionRootSelected
        self.syncedDocumentCount = max(0, syncedDocumentCount)
        self.aiProviderName = aiProviderName
        self.aiModelConfigured = aiModelConfigured
        self.aiCredentialConfigured = aiCredentialConfigured
        self.activeKnowledgeCount = max(0, activeKnowledgeCount)
        self.activeCardCount = max(0, activeCardCount)
        self.dueCardCount = max(0, dueCardCount)
        self.reviewHistoryCount = max(0, reviewHistoryCount)
        self.latestReviewAt = latestReviewAt
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
        let knowledge = try context.fetch(
            FetchDescriptor<KnowledgeItemEntity>()
        )
        .filter(\.isActive)
        let history = try context.fetch(
            FetchDescriptor<ReviewHistoryEntity>()
        )
        let home = try repository.homeSnapshot()

        return AppReadinessSnapshot(
            notionCredentialConfigured: notionConfigured,
            notionRootSelected: rootSelected,
            syncedDocumentCount: documents.count,
            aiProviderName:
                aiConfiguration.provider.displayName,
            aiModelConfigured: aiModelConfigured,
            aiCredentialConfigured: aiCredentialConfigured,
            activeKnowledgeCount: knowledge.count,
            activeCardCount: cards.count,
            dueCardCount: home.dueCount,
            reviewHistoryCount: history.count,
            latestReviewAt: home.latestReviewAt
        )
    }
}
