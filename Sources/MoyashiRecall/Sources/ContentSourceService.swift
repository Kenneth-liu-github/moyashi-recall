import Foundation

public enum ContentSourceKind: String, Codable, Sendable {
    case notion
    case pdf
    case word
    case image
    case manual
}

public struct SourceDocument: Identifiable, Equatable, Sendable {
    public let id: String
    public let sourceKind: ContentSourceKind
    public let title: String
    public let parentID: String?
    public let path: [String]
    public let plainText: String
    public let sourceReference: String
    public let lastEditedAt: Date?

    public init(
        id: String,
        sourceKind: ContentSourceKind,
        title: String,
        parentID: String?,
        path: [String],
        plainText: String,
        sourceReference: String,
        lastEditedAt: Date?
    ) {
        self.id = id
        self.sourceKind = sourceKind
        self.title = title
        self.parentID = parentID
        self.path = path
        self.plainText = plainText
        self.sourceReference = sourceReference
        self.lastEditedAt = lastEditedAt
    }
}

public protocol ContentSourceService: Sendable {
    func fetchDocument(id: String) async throws -> SourceDocument
}
