import SwiftUI

public struct ReviewView: View {
    @EnvironmentObject private var language: LanguageStore
    @State private var revealed = false
    @State private var reviewed = 0

    public init() {}

    public var body: some View {
        VStack(spacing: 0) {
            ProgressView(value: Double(reviewed), total: 20)
                .tint(AppTheme.accent)
                .padding(.horizontal)
                .padding(.top, 10)

            ScrollView {
                VStack(spacing: 22) {
                    HStack {
                        Text(language.text("中 → 日", "中 → 日"))
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(AppTheme.accent)
                        Spacer()
                        Text("\(reviewed + 1) / 20")
                            .font(.caption)
                            .foregroundStyle(AppTheme.muted)
                    }

                    Spacer(minLength: 30)

                    Text(MockData.reviewCard.prompt)
                        .font(.title2.bold())
                        .multilineTextAlignment(.center)

                    Text(MockData.reviewCard.source)
                        .font(.caption)
                        .foregroundStyle(AppTheme.muted)

                    if revealed {
                        Divider().padding(.vertical, 4)
                        VStack(spacing: 12) {
                            Text(MockData.reviewCard.answer)
                                .font(.title3.bold())
                            Text(MockData.reviewCard.meaning)
                                .multilineTextAlignment(.center)
                            Text("Natural English: \(MockData.reviewCard.naturalEnglish)")
                                .font(.subheadline)
                                .foregroundStyle(AppTheme.muted)
                        }
                    }

                    Spacer(minLength: 24)
                }
                .padding(20)
            }

            VStack(spacing: 12) {
                if revealed {
                    HStack(spacing: 8) {
                        rating(language.text("重来", "もう一度"))
                        rating(language.text("困难", "難しい"))
                        rating(language.text("良好", "良い"))
                        rating(language.text("简单", "簡単"))
                    }
                } else {
                    Button {
                        revealed = true
                    } label: {
                        Text(language.text("显示答案", "答えを見る"))
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(AppTheme.accent)
                }
            }
            .padding()
            .background(AppTheme.surface)
        }
        .navigationTitle(language.text("复习", "復習"))
    }

    private func rating(_ text: String) -> some View {
        Button(text) {
            reviewed = min(reviewed + 1, 20)
            revealed = false
        }
        .buttonStyle(.bordered)
        .tint(AppTheme.accent)
        .frame(maxWidth: .infinity)
    }
}
