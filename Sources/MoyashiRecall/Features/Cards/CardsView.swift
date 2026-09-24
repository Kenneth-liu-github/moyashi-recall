import SwiftUI

public struct CardsView: View {
    @EnvironmentObject private var language: LanguageStore
    public init() {}

    public var body: some View {
        NavigationStack {
            List {
                VStack(alignment: .leading, spacing: 5) {
                    Text(MockData.reviewCard.answer).font(.headline)
                    Text(MockData.reviewCard.meaning).foregroundStyle(AppTheme.muted)
                    Text(MockData.reviewCard.source).font(.caption).foregroundStyle(AppTheme.muted)
                }
            }
            .navigationTitle(language.text("卡片", "カード"))
            .searchable(text: .constant(""), prompt: language.text("搜索卡片", "カードを検索"))
        }
    }
}
