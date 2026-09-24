import Foundation
import SwiftData

@MainActor
public enum DemoDataSeeder {
    public static let knowledgeID = UUID(uuidString: "B95340F5-7F85-48A5-96B8-85524E53F502")!
    public static let cardID = UUID(uuidString: "7D4ED5E0-4E76-4C36-8D6B-9099F57A3101")!

    public static func seedIfNeeded(in context: ModelContext) throws {
        let cards = try context.fetch(FetchDescriptor<FlashcardEntity>())
        guard !cards.contains(where: { $0.id == cardID }) else { return }

        let items = try context.fetch(FetchDescriptor<KnowledgeItemEntity>())
        if !items.contains(where: { $0.id == knowledgeID }) {
            context.insert(
                KnowledgeItemEntity(
                    id: knowledgeID,
                    title: "進（すす）め方（かた）について",
                    content: "关于推进方式 / 关于如何推进",
                    sourceKind: "notion-demo",
                    sourceReference: "办公室日语学习 · 第二课"
                )
            )
        }

        context.insert(
            FlashcardEntity(
                id: cardID,
                knowledgeItemID: knowledgeID,
                cardType: "zh-to-ja",
                prompt: "“关于推进方式”用自然的商务日语怎么说？",
                answer: "進（すす）め方（かた）について",
                explanation: "关于推进方式 / 关于如何推进",
                naturalEnglish: "regarding how to proceed",
                sourceReference: "办公室日语学习 · 第二课"
            )
        )

        try context.save()
    }
}
