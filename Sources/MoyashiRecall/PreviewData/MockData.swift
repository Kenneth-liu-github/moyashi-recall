import Foundation

public enum MockData {
    public static let sources = [
        StudySource(key: "office-japanese", title: "办公室日语学习", detail: "Notion · 第二课", itemCount: 86),
        StudySource(key: "japanese-bootcamp", title: "日语训练营", detail: "Notion · 综合语法", itemCount: 124),
        StudySource(key: "japanese-speaking", title: "日语口语 私教", detail: "Notion · 口语表达", itemCount: 72)
    ]

    public static let reviewCard = ReviewCard(
        id: UUID(uuidString: "7D4ED5E0-4E76-4C36-8D6B-9099F57A3101")!,
        prompt: "“关于推进方式”用自然的商务日语怎么说？",
        answer: "進（すす）め方（かた）について",
        meaning: "关于推进方式 / 关于如何推进",
        naturalEnglish: "regarding how to proceed",
        source: "办公室日语学习 · 第二课"
    )
}
