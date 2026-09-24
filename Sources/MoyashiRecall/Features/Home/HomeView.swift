import SwiftUI

public struct HomeView: View {
    @EnvironmentObject private var language: LanguageStore

    public init() {}

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text(language.text("今天继续一点点。", "今日も少しずつ。"))
                        .font(.title2.bold())

                    HStack(spacing: 12) {
                        metric("28", language.text("待复习", "復習待ち"))
                        metric("12", language.text("连续天数", "連続日数"))
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Text(language.text("今日复习", "今日の復習")).font(.headline)
                        Text(language.text("根据你的学习记录，今天有 28 张卡片到期。", "学習履歴に基づき、今日は28枚のカードが期限です。"))
                            .foregroundStyle(AppTheme.muted)
                        NavigationLink {
                            StudyScopeView()
                        } label: {
                            Text(language.text("选择范围并开始", "範囲を選んで開始"))
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(AppTheme.accent)
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
                        }
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius))

                    Text(language.text("需要加强", "要強化")).font(.headline)
                    Text(language.text("使役 / 受身 / 使役受身 · ば形判断", "使役・受身・使役受身 · ば形の判断"))
                        .foregroundStyle(AppTheme.muted)
                }
                .padding()
            }
            .navigationTitle("Moyashi Recall")
        }
    }

    private func metric(_ value: String, _ label: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value).font(.title.bold())
            Text(label).font(.caption).foregroundStyle(AppTheme.muted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
    }
}
