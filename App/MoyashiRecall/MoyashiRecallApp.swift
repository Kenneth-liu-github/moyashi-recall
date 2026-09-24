import SwiftUI
import SwiftData
import MoyashiRecall

@main
struct MoyashiRecallApp: App {
    var body: some Scene {
        WindowGroup {
            MoyashiRecallRootView()
        }
        .modelContainer(for: [
            SourceDocumentEntity.self,
            KnowledgeItemEntity.self,
            FlashcardEntity.self,
            ReviewStateEntity.self,
            ReviewHistoryEntity.self
        ])
    }
}
