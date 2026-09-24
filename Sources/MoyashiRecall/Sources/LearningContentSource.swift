import Foundation

public struct ImportedDocument: Identifiable, Equatable, Sendable {
    public let id: String
    public let sourceKind: String
    public let title: String
    public let sourceReference: String
    public let content: String
    public let lastEditedAt: Date?

    public init(
        id: String,
        sourceKind: String,
        title: String,
        sourceReference: String,
        content: String,
        lastEditedAt: Date? = nil
    ) {
        self.id = id
        self.sourceKind = sourceKind
        self.title = title
        self.sourceReference = sourceReference
        self.content = content
        self.lastEditedAt = lastEditedAt
    }
}

public protocol LearningContentSource {
    var kind: String { get }
    func fetchDocument(id: String) async throws -> ImportedDocument
}
