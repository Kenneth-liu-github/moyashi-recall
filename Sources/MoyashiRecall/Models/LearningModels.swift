import Foundation

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
