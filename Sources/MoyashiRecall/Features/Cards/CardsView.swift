import SwiftUI
import SwiftData

public struct CardsView: View {
    @EnvironmentObject private var language: LanguageStore
    @Environment(\.modelContext) private var modelContext

    @State private var searchText = ""
    @State private var cards: [ReviewSessionCard] = []
    @State private var loadError: String?

    public init() {}

    public var body: some View {
        NavigationStack {
            Group {
                if let loadError {
                    ContentUnavailableView(
                        language.text("无法读取卡片", "カードを読み込めません"),
                        systemImage: "exclamationmark.triangle",
                        description: Text(loadError)
                    )
                } else if cards.isEmpty {
                    ContentUnavailableView(
                        searchText.isEmpty
                            ? language.text("暂无卡片", "カードがありません")
                            : language.text("没有匹配的卡片", "一致するカードがありません"),
                        systemImage: "rectangle.stack"
                    )
                } else {
                    List(cards) { card in
                        VStack(alignment: .leading, spacing: 5) {
                            Text(card.answer).font(.headline)
                            if !card.explanation.isEmpty {
                                Text(card.explanation)
                                    .foregroundStyle(AppTheme.muted)
                            }
                            Text(card.sourceReference)
                                .font(.caption)
                                .foregroundStyle(AppTheme.muted)
                        }
                    }
                }
            }
            .navigationTitle(language.text("卡片", "カード"))
            .searchable(
                text: $searchText,
                prompt: language.text("搜索卡片", "カードを検索")
            )
            .task(id: searchText) {
                loadCards()
            }
            .onAppear {
                loadCards()
            }
        }
    }

    private func loadCards() {
        do {
            let repository = LearningRepository(context: modelContext)
            try repository.seedDemoIfNeeded()
            cards = try repository.allSessionCards(searchText: searchText)
            loadError = nil
        } catch {
            loadError = language.text(
                "无法读取卡片数据。",
                "カードデータを読み込めませんでした。"
            )
        }
    }
}
