import SwiftUI
import SwiftData

public struct HomeView: View {
    @EnvironmentObject private var language: LanguageStore
    @Environment(\.modelContext) private var modelContext

    @State private var snapshot = HomeSnapshot(dueCount: 0, streakDays: 0)
    @State private var loadError: String?

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
                        metric("\(snapshot.dueCount)", language.text("今日到期", "今日の期限"))
                        metric("\(snapshot.streakDays)", language.text("连续学习", "連続学習"))
                    }

                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            Text(language.text("今日复习", "今日の復習")).font(.headline)
                            Spacer()
                            Text(language.text("实时数据", "リアルタイム"))
                                .font(.caption)
                                .foregroundStyle(AppTheme.muted)
                        }

                        if let loadError {
                            Text(loadError)
                                .font(.caption)
                                .foregroundStyle(.red)
                        } else {
                            Text(
                                language.text(
                                    snapshot.dueCount == 0
                                        ? "今天没有到期卡片。"
                                        : "\(snapshot.dueCount) 张卡片等待复习。",
                                    snapshot.dueCount == 0
                                        ? "今日は期限のカードがありません。"
                                        : "\(snapshot.dueCount)枚のカードが復習待ちです。"
                                )
                            )
                            .foregroundStyle(AppTheme.muted)
                        }

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
            .task { loadSnapshot() }
            .onAppear { loadSnapshot() }
        }
    }

    private func loadSnapshot() {
        do {
            let repository = LearningRepository(context: modelContext)
            try repository.seedDemoIfNeeded()
            snapshot = try repository.homeSnapshot()
            loadError = nil
        } catch {
            loadError = language.text("无法读取学习数据。", "学習データを読み込めませんでした。")
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
