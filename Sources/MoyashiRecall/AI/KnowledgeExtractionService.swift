import Foundation

public enum KnowledgeExtractionError: Error, Equatable {
    case invalidVersion(String)
    case tooManyItems(Int)
    case tooManyCards(itemKey: String, count: Int)
    case emptyKnowledgeKey
    case duplicateKnowledgeKey(String)
    case emptyCardKey(itemKey: String)
    case duplicateCardKey(itemKey: String, cardKey: String)
    case emptyCardContent(itemKey: String, cardKey: String)
}

public struct KnowledgeExtractionService {
    public static let extractionVersion = "v1"
    public static let maximumItems = 100
    public static let maximumCardsPerItem = 10

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
        let request = Self.request(for: document)

        let response = try await provider.complete(request: request)

        guard let data = response.text.data(using: .utf8) else {
            throw AIProviderError.invalidResponse
        }

        let bundle: KnowledgeExtractionBundle
        do {
            bundle = try JSONDecoder().decode(
                KnowledgeExtractionBundle.self,
                from: data
            )
        } catch {
            throw AIProviderError.decodingFailed
        }

        let normalized = Self.normalize(bundle)
        try Self.validate(normalized)

        return (
            normalized,
            response.providerID,
            response.modelID
        )
    }

    public static func normalize(
        _ bundle: KnowledgeExtractionBundle
    ) -> KnowledgeExtractionBundle {
        KnowledgeExtractionBundle(
            version: bundle.version
                .trimmingCharacters(
                    in: .whitespacesAndNewlines
                ),
            items: bundle.items.map { item in
                ExtractedKnowledgeItem(
                    key: item.key
                        .trimmingCharacters(
                            in: .whitespacesAndNewlines
                        ),
                    kind: item.kind,
                    title: item.title,
                    canonicalExpression: item.canonicalExpression,
                    meaning: item.meaning,
                    explanation: item.explanation,
                    naturalEnglish: item.naturalEnglish,
                    tags: item.tags,
                    cards: item.cards.map { card in
                        GeneratedFlashcard(
                            key: card.key
                                .trimmingCharacters(
                                    in: .whitespacesAndNewlines
                                ),
                            type: card.type,
                            prompt: card.prompt,
                            answer: card.answer,
                            explanation: card.explanation,
                            naturalEnglish: card.naturalEnglish
                        )
                    }
                )
            }
        )
    }

    public static func validate(
        _ bundle: KnowledgeExtractionBundle
    ) throws {
        guard bundle.version == extractionVersion else {
            throw KnowledgeExtractionError.invalidVersion(
                bundle.version
            )
        }

        guard bundle.items.count <= maximumItems else {
            throw KnowledgeExtractionError.tooManyItems(
                bundle.items.count
            )
        }

        var knowledgeKeys = Set<String>()

        for item in bundle.items {
            let itemKey = item.key.trimmingCharacters(
                in: .whitespacesAndNewlines
            )
            guard !itemKey.isEmpty else {
                throw KnowledgeExtractionError.emptyKnowledgeKey
            }
            guard knowledgeKeys.insert(itemKey).inserted else {
                throw KnowledgeExtractionError
                    .duplicateKnowledgeKey(itemKey)
            }

            guard item.cards.count <= maximumCardsPerItem else {
                throw KnowledgeExtractionError.tooManyCards(
                    itemKey: itemKey,
                    count: item.cards.count
                )
            }

            var cardKeys = Set<String>()
            for card in item.cards {
                let cardKey = card.key.trimmingCharacters(
                    in: .whitespacesAndNewlines
                )
                guard !cardKey.isEmpty else {
                    throw KnowledgeExtractionError.emptyCardKey(
                        itemKey: itemKey
                    )
                }
                guard cardKeys.insert(cardKey).inserted else {
                    throw KnowledgeExtractionError.duplicateCardKey(
                        itemKey: itemKey,
                        cardKey: cardKey
                    )
                }

                guard
                    !card.prompt
                        .trimmingCharacters(
                            in: .whitespacesAndNewlines
                        )
                        .isEmpty,
                    !card.answer
                        .trimmingCharacters(
                            in: .whitespacesAndNewlines
                        )
                        .isEmpty
                else {
                    throw KnowledgeExtractionError.emptyCardContent(
                        itemKey: itemKey,
                        cardKey: cardKey
                    )
                }
            }
        }
    }

    public static func request(
        for document: ImportedDocument
    ) -> AICompletionRequest {
        AICompletionRequest(
            systemPrompt: systemPrompt,
            userPrompt: userPrompt(for: document),
            responseSchemaName: "moyashi_knowledge_extraction_v1",
            responseSchemaJSON: responseSchemaJSON
        )
    }

    private static let responseSchemaJSON = """
    {
      "type": "object",
      "properties": {
        "version": {
          "type": "string",
          "enum": ["v1"]
        },
        "items": {
          "type": "array",
          "items": {
            "type": "object",
            "properties": {
              "key": {"type": "string"},
              "kind": {
                "type": "string",
                "enum": [
                  "vocabulary",
                  "expression",
                  "grammar",
                  "contrast",
                  "example",
                  "businessUsage",
                  "other"
                ]
              },
              "title": {"type": "string"},
              "canonicalExpression": {"type": "string"},
              "meaning": {"type": "string"},
              "explanation": {"type": "string"},
              "naturalEnglish": {"type": "string"},
              "tags": {
                "type": "array",
                "items": {"type": "string"}
              },
              "cards": {
                "type": "array",
                "items": {
                  "type": "object",
                  "properties": {
                    "key": {"type": "string"},
                    "type": {
                      "type": "string",
                      "enum": [
                        "zh-to-ja",
                        "ja-to-zh",
                        "cloze",
                        "contrast",
                        "application"
                      ]
                    },
                    "prompt": {"type": "string"},
                    "answer": {"type": "string"},
                    "explanation": {"type": "string"},
                    "naturalEnglish": {"type": "string"}
                  },
                  "required": [
                    "key",
                    "type",
                    "prompt",
                    "answer",
                    "explanation",
                    "naturalEnglish"
                  ],
                  "additionalProperties": false
                }
              }
            },
            "required": [
              "key",
              "kind",
              "title",
              "canonicalExpression",
              "meaning",
              "explanation",
              "naturalEnglish",
              "tags",
              "cards"
            ],
            "additionalProperties": false
          }
        }
      },
      "required": ["version", "items"],
      "additionalProperties": false
    }
    """

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
        \(document.title)

        SOURCE PATH:
        \(document.sourcePath.joined(separator: " / "))

        SOURCE CONTENT:
        \(document.content)

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
