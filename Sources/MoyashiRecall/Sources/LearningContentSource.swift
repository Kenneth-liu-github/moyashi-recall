import Foundation

public struct ImportedDocument: Identifiable, Equatable, Sendable {
    public let id: String
    public let sourceKind: String
    public let title: String
    public let sourceReference: String
    public let content: String
    public let lastEditedAt: Date?
    public let parentExternalID: String?
    public let rootExternalID: String
    public let sourcePath: [String]
    public let hierarchyDepth: Int
    public let sourceKeyHint: String?

    public init(
        id: String,
        sourceKind: String,
        title: String,
        sourceReference: String,
        content: String,
        lastEditedAt: Date? = nil,
        parentExternalID: String? = nil,
        rootExternalID: String? = nil,
        sourcePath: [String] = [],
        hierarchyDepth: Int = 0,
        sourceKeyHint: String? = nil
    ) {
        self.id = id
        self.sourceKind = sourceKind
        self.title = title
        self.sourceReference = sourceReference
        self.content = content
        self.lastEditedAt = lastEditedAt
        self.parentExternalID = parentExternalID
        self.rootExternalID = rootExternalID ?? id
        self.sourcePath = sourcePath.isEmpty ? [title] : sourcePath
        self.hierarchyDepth = max(0, hierarchyDepth)
        self.sourceKeyHint = sourceKeyHint
    }
}

public protocol LearningContentSource {
    var kind: String { get }
    func fetchDocument(id: String) async throws -> ImportedDocument
}
