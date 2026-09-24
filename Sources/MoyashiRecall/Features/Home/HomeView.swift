import SwiftUI
import SwiftData

public struct HomeView: View {
    @EnvironmentObject private var language: LanguageStore
    @Query private var cards: [FlashcardEntity]
    @Query(sort: \ReviewStateEntity.due) private var reviewStates: [ReviewStateEntity]
    @Query(sort: \ReviewHistoryEntity.reviewedAt, order: .reverse) private var reviewHistory: [ReviewHistoryEntity]

    public init() {}

    private var dueCount: Int {
        let now = Date()
        let stateByCard = reviewStates.reduce(into: [UUID: ReviewStateEntity]()) { result, state in
            if let existing = result[state.cardID] {
                if state.due < existing.due { result[state.cardID] = state }
            } else {
                result[state.cardID] = state
            }
        }
        return cards.reduce(0) { count, card in
            guard let state = stateByCard[card.id] else { return count + 1 }
            return count + (state.due <= now ? 1 : 0)
        }
    }

    private var streakDays: Int {
        let calendar = Calendar.current
        let days = Set(reviewHistory.map { calendar.startOfDay(for: $0.reviewedAt) })
        guard !days.isEmpty else { return 0 }

        var streak = 0
        var cursor = calendar.startOfDay(for: .now)
        if !days.contains(cursor) {
            cursor = calendar.date(byAdding: .day, value: -1, to: cursor) ?? cursor
        }

        while days.contains(cursor) {
            streak += 1
            cursor = calendar.date(byAdding: .day, value: -1, to: cursor) ?? cursor
        }
        return streak
    }

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
                        metric("\(dueCount)", language.text("今日到期", "今日の期限"))
                        metric("\(streakDays)", language.text("连续学习", "連続学習"))
                    }

                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            Text(language.text("今日复习", "今日の復習")).font(.headline)
                            Spacer()
                            Text(language.text("实时数据", "リアルタイム")).font(.caption).foregroundStyle(AppTheme.muted)
                        }
                        Text(
                            language.text(
                                dueCount == 0 ? "今天没有到期卡片。" : "\(dueCount) 张卡片等待复习。",
                                dueCount == 0 ? "今日は期限のカードがありません。" : "\(dueCount)枚のカードが復習待ちです。"
                            )
                        )
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
