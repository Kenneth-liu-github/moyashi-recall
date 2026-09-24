import Foundation

public enum ReviewCardType: String, Codable, CaseIterable, Identifiable, Sendable {
    case zhToJa = "zh-to-ja"
    case jaToZh = "ja-to-zh"
    case cloze
    case contrast
    case application

    public var id: String { rawValue }
}

public struct StudySource: Identifiable, Hashable {
    public let id: UUID
    public let key: String
    public let title: String
    public let detail: String

    public init(
        id: UUID = UUID(),
        key: String,
        title: String,
        detail: String
    ) {
        self.id = id
        self.key = key
        self.title = title
        self.detail = detail
    }
}
