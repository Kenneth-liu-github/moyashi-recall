import Foundation

public struct StudySource: Identifiable, Hashable {
    public let id = UUID()
    public let title: String
    public let detail: String
    public let itemCount: Int

    public init(title: String, detail: String, itemCount: Int) {
        self.title = title
        self.detail = detail
        self.itemCount = itemCount
    }
}

public struct ReviewCard: Identifiable, Hashable {
    public let id = UUID()
    public let prompt: String
    public let answer: String
    public let meaning: String
    public let naturalEnglish: String
    public let source: String

    public init(prompt: String, answer: String, meaning: String, naturalEnglish: String, source: String) {
        self.prompt = prompt
        self.answer = answer
        self.meaning = meaning
        self.naturalEnglish = naturalEnglish
        self.source = source
    }
}
