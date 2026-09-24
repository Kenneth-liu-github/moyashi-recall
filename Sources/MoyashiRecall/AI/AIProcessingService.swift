import Foundation

public struct AIProcessingResult: Equatable, Sendable {
    public let sourceDocumentID: UUID
    public let providerID: String
    public let modelID: String
    public let extractedItems: Int
    public let persistence: ExtractionPersistenceReport

    public init(
        sourceDocumentID: UUID,
        providerID: String,
        modelID: String,
        extractedItems: Int,
        persistence: ExtractionPersistenceReport
    ) {
        self.sourceDocumentID = sourceDocumentID
        self.providerID = providerID
        self.modelID = modelID
        self.extractedItems = extractedItems
        self.persistence = persistence
    }
}

public enum AIProcessingError: Error, Equatable {
    case sourceDocumentNotFound(UUID)
}

@MainActor
public struct AIProcessingService {
    private let repository: LearningRepository
    private let extractor: KnowledgeExtractionService

    public init(
        repository: LearningRepository,
        provider: any AICompletionProvider
    ) {
        self.repository = repository
        self.extractor = KnowledgeExtractionService(
            provider: provider
        )
    }

    public func process(
        sourceDocumentID: UUID,
        now: Date = .now
    ) async throws -> AIProcessingResult {
        guard let source = try repository.sourceDocument(
            id: sourceDocumentID
        ) else {
            throw AIProcessingError.sourceDocumentNotFound(
                sourceDocumentID
            )
        }

        let extraction = try await extractor.extract(
            from: source.importedDocument
        )

        let persistence = try repository.persistExtraction(
            extraction.bundle,
            sourceDocumentID: sourceDocumentID,
            providerID: extraction.providerID,
            modelID: extraction.modelID,
            now: now
        )

        return AIProcessingResult(
            sourceDocumentID: sourceDocumentID,
            providerID: extraction.providerID,
            modelID: extraction.modelID,
            extractedItems: extraction.bundle.items.count,
            persistence: persistence
        )
    }
}
