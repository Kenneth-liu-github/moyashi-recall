import XCTest
@testable import MoyashiRecall

final class DocumentChunkerTests: XCTestCase {
    func testShortDocumentRemainsOneChunk() {
        let chunker = DocumentChunker(
            maximumCharacters: 1_000
        )

        XCTAssertEqual(
            chunker.chunks(
                text: "第一段。\n\n第二段。"
            ),
            ["第一段。\n\n第二段。"]
        )
    }

    func testLongDocumentSplitsWithoutDroppingContent() {
        let block = String(
            repeating: "あ",
            count: 2_500
        )
        let chunker = DocumentChunker(
            maximumCharacters: 1_000
        )

        let chunks = chunker.chunks(
            text: block
        )

        XCTAssertEqual(chunks.count, 3)
        XCTAssertEqual(
            chunks.joined().count,
            block.count
        )
        XCTAssertTrue(
            chunks.allSatisfy {
                $0.count <= 1_000
            }
        )
    }

    func testBundleMergerDeduplicatesKnowledgeAndCards() throws {
        let first = ExtractedKnowledgeItem(
            key: "grammar-ni-tsuite",
            kind: .grammar,
            title: "～について",
            canonicalExpression: "～について",
            meaning: "关于……",
            explanation: "主题表达",
            tags: ["语法"],
            cards: [
                GeneratedFlashcard(
                    key: "zh-ja",
                    type: .zhToJa,
                    prompt: "关于推进方式",
                    answer: "進（すす）め方（かた）について"
                )
            ]
        )
        let second = ExtractedKnowledgeItem(
            key: "grammar-ni-tsuite",
            kind: .grammar,
            title: "～について",
            canonicalExpression: "～について",
            meaning: "关于……",
            explanation: "主题表达",
            tags: ["商务"],
            cards: [
                GeneratedFlashcard(
                    key: "ja-zh",
                    type: .jaToZh,
                    prompt: "進（すす）め方（かた）について",
                    answer: "关于推进方式"
                )
            ]
        )

        let merged = try KnowledgeBundleMerger.merge(
            [
                KnowledgeExtractionBundle(
                    version: "v1",
                    items: [first]
                ),
                KnowledgeExtractionBundle(
                    version: "v1",
                    items: [second]
                )
            ]
        )

        XCTAssertEqual(merged.items.count, 1)
        XCTAssertEqual(
            Set(merged.items[0].tags),
            Set(["语法", "商务"])
        )
        XCTAssertEqual(
            Set(merged.items[0].cards.map(\.key)),
            Set(["zh-ja", "ja-zh"])
        )
    }
}
