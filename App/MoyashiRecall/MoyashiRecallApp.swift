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
            KnowledgeItemEntity.self,
            FlashcardEntity.self,
            ReviewStateEntity.self,
            ReviewHistoryEntity.self
        ])
    }
}
