import SwiftUI

public struct ReviewView: View {
    @EnvironmentObject private var language: LanguageStore
    @State private var revealed = false

    public init() {}

    public var body: some View {
        NavigationStack {
            VStack(spacing: 22) {
                Spacer()
                Text(MockData.reviewCard.prompt)
                    .font(.title2.bold())
                    .multilineTextAlignment(.center)

                Text(MockData.reviewCard.source)
                    .font(.caption)
                    .foregroundStyle(AppTheme.muted)

                if revealed {
                    Divider()
                    Text(MockData.reviewCard.answer).font(.title3.bold())
                    Text(MockData.reviewCard.meaning)
                    Text("Natural English: \(MockData.reviewCard.naturalEnglish)")
                        .foregroundStyle(AppTheme.muted)

                    HStack {
                        rating(language.text("重来", "もう一度"))
                        rating(language.text("困难", "難しい"))
                        rating(language.text("良好", "良い"))
                        rating(language.text("简单", "簡単"))
                    }
                } else {
                    Button(language.text("显示答案", "答えを見る")) { revealed = true }
                        .buttonStyle(.borderedProminent)
                        .tint(AppTheme.accent)
                }
                Spacer()
            }
            .padding()
            .navigationTitle(language.text("复习", "復習"))
        }
    }

    private func rating(_ text: String) -> some View {
        Button(text) { revealed = false }
            .buttonStyle(.bordered)
            .tint(AppTheme.accent)
    }
}
