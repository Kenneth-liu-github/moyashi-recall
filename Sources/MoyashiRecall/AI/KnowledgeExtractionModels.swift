import Foundation

public enum KnowledgeKind: String, Codable, CaseIterable, Sendable {
    case vocabulary
    case expression
    case grammar
    case contrast
    case example
    case businessUsage
    case other
}

public enum GeneratedCardType: String, Codable, CaseIterable, Sendable {
    case zhToJa = "zh-to-ja"
    case jaToZh = "ja-to-zh"
    case cloze
    case contrast
    case application
}

public struct GeneratedFlashcard: Codable, Equatable, Sendable {
    public let key: String
    public let type: GeneratedCardType
    public let prompt: String
    public let answer: String
    public let explanation: String
    public let naturalEnglish: String

    public init(
        key: String,
        type: GeneratedCardType,
        prompt: String,
        answer: String,
        explanation: String = "",
        naturalEnglish: String = ""
    ) {
        self.key = key
        self.type = type
        self.prompt = prompt
        self.answer = answer
        self.explanation = explanation
        self.naturalEnglish = naturalEnglish
    }
}

public struct ExtractedKnowledgeItem: Codable, Equatable, Sendable {
    public let key: String
    public let kind: KnowledgeKind
    public let title: String
    public let canonicalExpression: String
    public let meaning: String
    public let explanation: String
    public let naturalEnglish: String
    public let tags: [String]
    public let cards: [GeneratedFlashcard]

    public init(
        key: String,
        kind: KnowledgeKind,
        title: String,
        canonicalExpression: String,
        meaning: String,
        explanation: String,
        naturalEnglish: String = "",
        tags: [String] = [],
        cards: [GeneratedFlashcard] = []
    ) {
        self.key = key
        self.kind = kind
        self.title = title
        self.canonicalExpression = canonicalExpression
        self.meaning = meaning
        self.explanation = explanation
        self.naturalEnglish = naturalEnglish
        self.tags = tags
        self.cards = cards
    }
}

public struct KnowledgeExtractionBundle: Codable, Equatable, Sendable {
    public let version: String
    public let items: [ExtractedKnowledgeItem]

    public init(
        version: String,
        items: [ExtractedKnowledgeItem]
    ) {
        self.version = version
        self.items = items
    }
}
