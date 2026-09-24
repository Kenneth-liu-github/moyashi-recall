import Foundation

public struct DocumentChunker: Sendable {
    public let maximumCharacters: Int

    public init(
        maximumCharacters: Int = 12_000
    ) {
        self.maximumCharacters = max(
            1_000,
            maximumCharacters
        )
    }

    public func chunks(
        text: String
    ) -> [String] {
        let normalized = text
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        guard !normalized.isEmpty else {
            return []
        }

        let paragraphs = normalized.components(
            separatedBy: "\n\n"
        )

        var result: [String] = []
        var current = ""

        for paragraph in paragraphs {
            let block = paragraph.trimmingCharacters(
                in: .whitespacesAndNewlines
            )
            guard !block.isEmpty else {
                continue
            }

            if block.count > maximumCharacters {
                if !current.isEmpty {
                    result.append(current)
                    current = ""
                }
                result.append(
                    contentsOf: splitLongBlock(block)
                )
                continue
            }

            let candidate = current.isEmpty
                ? block
                : current + "\n\n" + block

            if candidate.count <= maximumCharacters {
                current = candidate
            } else {
                result.append(current)
                current = block
            }
        }

        if !current.isEmpty {
            result.append(current)
        }

        return result
    }

    private func splitLongBlock(
        _ block: String
    ) -> [String] {
        var parts: [String] = []
        var start = block.startIndex

        while start < block.endIndex {
            let end = block.index(
                start,
                offsetBy: maximumCharacters,
                limitedBy: block.endIndex
            ) ?? block.endIndex

            let part = String(
                block[start..<end]
            )
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )

            if !part.isEmpty {
                parts.append(part)
            }
            start = end
        }

        return parts
    }
}

public enum KnowledgeBundleMerger {
    public static func merge(
        _ bundles: [KnowledgeExtractionBundle]
    ) throws -> KnowledgeExtractionBundle {
        guard !bundles.isEmpty else {
            return KnowledgeExtractionBundle(
                version: KnowledgeExtractionService
                    .extractionVersion,
                items: []
            )
        }

        for bundle in bundles {
            try KnowledgeExtractionService.validate(
                bundle
            )
        }

        let version = bundles[0].version
        guard bundles.allSatisfy({
            $0.version == version
        }) else {
            throw KnowledgeExtractionError
                .invalidVersion("mixed")
        }

        var order: [String] = []
        var itemsByKey: [
            String: ExtractedKnowledgeItem
        ] = [:]

        for bundle in bundles {
            for item in bundle.items {
                if let existing = itemsByKey[item.key] {
                    itemsByKey[item.key] = merge(
                        existing,
                        item
                    )
                } else {
                    order.append(item.key)
                    itemsByKey[item.key] = item
                }
            }
        }

        let items = order.compactMap {
            itemsByKey[$0]
        }
        let merged = KnowledgeExtractionBundle(
            version: version,
            items: items
        )
        try KnowledgeExtractionService.validate(
            merged
        )
        return merged
    }

    private static func merge(
        _ lhs: ExtractedKnowledgeItem,
        _ rhs: ExtractedKnowledgeItem
    ) -> ExtractedKnowledgeItem {
        var cardOrder = lhs.cards.map(\.key)
        var cardsByKey = Dictionary(
            uniqueKeysWithValues: lhs.cards.map {
                ($0.key, $0)
            }
        )

        for card in rhs.cards
        where cardsByKey[card.key] == nil {
            cardOrder.append(card.key)
            cardsByKey[card.key] = card
        }

        let tags = Array(
            Set(lhs.tags + rhs.tags)
        )
        .sorted()

        return ExtractedKnowledgeItem(
            key: lhs.key,
            kind: lhs.kind,
            title: lhs.title,
            canonicalExpression: lhs.canonicalExpression,
            meaning: lhs.meaning,
            explanation: lhs.explanation,
            naturalEnglish: lhs.naturalEnglish,
            tags: tags,
            cards: cardOrder.compactMap {
                cardsByKey[$0]
            }
        )
    }
}
