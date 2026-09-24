import Foundation

public struct KnowledgeExtractionService {
    public static let extractionVersion = "v1"

    private let provider: any AICompletionProvider

    public init(provider: any AICompletionProvider) {
        self.provider = provider
    }

    public func extract(
        from document: ImportedDocument
    ) async throws -> (
        bundle: KnowledgeExtractionBundle,
        providerID: String,
        modelID: String
    ) {
        let request = AICompletionRequest(
            systemPrompt: Self.systemPrompt,
            userPrompt: Self.userPrompt(for: document),
            responseSchemaName: "moyashi_knowledge_extraction_v1"
        )

        let response = try await provider.complete(request: request)

        guard let data = response.text.data(using: .utf8) else {
            throw AIProviderError.invalidResponse
        }

        do {
            let bundle = try JSONDecoder().decode(
                KnowledgeExtractionBundle.self,
                from: data
            )
            return (
                bundle,
                response.providerID,
                response.modelID
            )
        } catch {
            throw AIProviderError.decodingFailed
        }
    }

    private static let systemPrompt = """
    You extract Japanese-learning knowledge from source material.
    Return JSON only.

    Rules:
    - Do not invent facts not supported by the source.
    - Preserve source meaning and business context.
    - Split content into reusable semantic knowledge items.
    - For Japanese learning output, annotate kanji with kana in the form 漢字（かんじ） whenever practical.
    - Keep Chinese explanations concise and natural.
    - Natural English is optional but should be idiomatic when present.
    - Generate only useful cards, avoiding near-duplicates.
    - Each knowledge item and card must have a stable textual key.
    """

    private static func userPrompt(
        for document: ImportedDocument
    ) -> String {
        """
        SOURCE TITLE:
        (document.title)

        SOURCE PATH:
        (document.sourcePath.joined(separator: " / "))

        SOURCE CONTENT:
        (document.content)

        Extract a JSON object matching:
        {
          "version": "v1",
          "items": [
            {
              "key": "stable-key",
              "kind": "vocabulary|expression|grammar|contrast|example|businessUsage|other",
              "title": "...",
              "canonicalExpression": "...",
              "meaning": "...",
              "explanation": "...",
              "naturalEnglish": "...",
              "tags": ["..."],
              "cards": [
                {
                  "key": "stable-card-key",
                  "type": "zh-to-ja|ja-to-zh|cloze|contrast|application",
                  "prompt": "...",
                  "answer": "...",
                  "explanation": "...",
                  "naturalEnglish": "..."
                }
              ]
            }
          ]
        }
        """
    }
}
