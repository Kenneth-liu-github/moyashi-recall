import SwiftUI

public struct HomeView: View {
    @EnvironmentObject private var language: LanguageStore

    public init() {}

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(language.text("今天继续一点点。", "今日も少しずつ。"))
                            .font(.title2.bold())
                        Text(language.text("把到期内容先复习完，再处理薄弱项。", "期限のカードを先に復習して、弱点を強化しましょう。"))
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.muted)
                    }

                    HStack(spacing: 12) {
                        metric("28", language.text("今日到期", "今日の期限"))
                        metric("12", language.text("连续学习", "連続学習"))
                    }

                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            Text(language.text("今日复习", "今日の復習")).font(.headline)
                            Spacer()
                            Text("≈ 8 min").font(.caption).foregroundStyle(AppTheme.muted)
                        }
                        Text(language.text("28 张卡片等待复习。你可以先选择资料来源，再开始本次学习。", "28枚のカードが復習待ちです。学習ソースを選んで開始できます。"))
                            .foregroundStyle(AppTheme.muted)

                        NavigationLink {
                            StudyScopeView()
                        } label: {
                            Label(language.text("选择范围并开始", "範囲を選んで開始"), systemImage: "play.fill")
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(AppTheme.accent)
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                    }
                    .padding(18)
                    .background(Color.gray.opacity(0.10))
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius))

                    VStack(alignment: .leading, spacing: 10) {
                        Text(language.text("需要加强", "要強化")).font(.headline)
                        weakness("arrow.triangle.branch", language.text("使役 / 受身 / 使役受身", "使役・受身・使役受身"))
                        weakness("arrow.left.arrow.right", language.text("普通ば vs 可能形＋ば", "普通ば vs 可能形＋ば"))
                    }
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
        .background(Color.gray.opacity(0.10))
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
    }

    private func weakness(_ icon: String, _ text: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon).foregroundStyle(AppTheme.accent).frame(width: 22)
            Text(text)
            Spacer()
            Image(systemName: "chevron.right").font(.caption).foregroundStyle(AppTheme.muted)
        }
        .padding(.vertical, 6)
    }
}
