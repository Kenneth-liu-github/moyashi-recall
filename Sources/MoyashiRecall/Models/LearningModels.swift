import Foundation

public struct StudySource: Identifiable, Hashable {
    public let id: UUID
    public let key: String
    public let title: String
    public let detail: String
    public let itemCount: Int

    public init(
        id: UUID = UUID(),
        key: String,
        title: String,
        detail: String,
        itemCount: Int
    ) {
        self.id = id
        self.key = key
        self.title = title
        self.detail = detail
        self.itemCount = itemCount
    }
}

public struct ReviewCard: Identifiable, Hashable {
    public let id: UUID
    public let prompt: String
    public let answer: String
    public let meaning: String
    public let naturalEnglish: String
    public let source: String

    public init(
        id: UUID = UUID(),
        prompt: String,
        answer: String,
        meaning: String,
        naturalEnglish: String,
        source: String
    ) {
        self.id = id
        self.prompt = prompt
        self.answer = answer
        self.meaning = meaning
        self.naturalEnglish = naturalEnglish
        self.source = source
    }
}
