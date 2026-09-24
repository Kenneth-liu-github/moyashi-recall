import Foundation

public enum ReviewCardType: String, Codable, CaseIterable, Identifiable, Hashable, Sendable {
    case zhToJa = "zh-to-ja"
    case jaToZh = "ja-to-zh"
    case cloze
    case contrast
    case application

    public var id: String { rawValue }
}

public struct StudySource: Identifiable, Hashable, Sendable {
    public let key: String
    public let title: String
    public let detail: String
    public let cardCount: Int

    public var id: String { key }

    public init(
        key: String,
        title: String,
        detail: String,
        cardCount: Int
    ) {
        self.key = key
        self.title = title
        self.detail = detail
        self.cardCount = cardCount
    }
}
