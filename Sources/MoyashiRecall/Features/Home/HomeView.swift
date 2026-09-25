import SwiftUI
import SwiftData

public struct HomeView: View {
    @EnvironmentObject private var language: LanguageStore
    @Environment(\.modelContext) private var modelContext

    @State private var snapshot = HomeSnapshot(
        dueCount: 0,
        streakDays: 0
    )
    @State private var loadError: String?

    public init() {}

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(
                    alignment: .leading,
                    spacing: 20
                ) {
                    VStack(
                        alignment: .leading,
                        spacing: 6
                    ) {
                        Text(
                            language.text(
                                "今天继续一点点。",
                                "今日も少しずつ。"
                            )
                        )
                        .font(.title2.bold())

                        Text(
                            language.text(
                                "先完成到期内容，再针对最近的薄弱项加强。",
                                "期限のカードを先に復習し、その後最近の弱点を強化しましょう。"
                            )
                        )
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.muted)
                    }

                    HStack(spacing: 12) {
                        metric(
                            "\(snapshot.dueCount)",
                            language.text(
                                "今日到期",
                                "今日の期限"
                            )
                        )
                        metric(
                            "\(snapshot.streakDays)",
                            language.text(
                                "连续学习",
                                "連続学習"
                            )
                        )
                    }

                    HStack(spacing: 12) {
                        metric(
                            "\(snapshot.reviewedToday)",
                            language.text(
                                "今日已复习",
                                "今日の復習"
                            )
                        )
                        metric(
                            successRateText,
                            language.text(
                                "近7日成功率",
                                "7日間成功率"
                            )
                        )
                    }

                    VStack(
                        alignment: .leading,
                        spacing: 14
                    ) {
                        HStack {
                            Text(
                                language.text(
                                    "今日复习",
                                    "今日の復習"
                                )
                            )
                            .font(.headline)

                            Spacer()

                            Text(
                                language.text(
                                    "近7日 \(snapshot.reviewedLast7Days) 次",
                                    "7日間 \(snapshot.reviewedLast7Days)回"
                                )
                            )
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
                            Label(
                                language.text(
                                    "选择范围并开始",
                                    "範囲を選んで開始"
                                ),
                                systemImage: "play.fill"
                            )
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(AppTheme.accent)
                            .foregroundStyle(.white)
                            .clipShape(
                                RoundedRectangle(
                                    cornerRadius: 14
                                )
                            )
                        }
                    }
                    .padding(18)
                    .background(
                        Color.gray.opacity(0.10)
                    )
                    .clipShape(
                        RoundedRectangle(
                            cornerRadius: AppTheme.cornerRadius
                        )
                    )

                    VStack(
                        alignment: .leading,
                        spacing: 10
                    ) {
                        Text(
                            language.text(
                                "最近薄弱项",
                                "最近の弱点"
                            )
                        )
                        .font(.headline)

                        if snapshot.weakKnowledge.isEmpty {
                            Text(
                                language.text(
                                    "近14天还没有足够的困难/重来记录。",
                                    "直近14日間には、まだ十分なHard/Again記録がありません。"
                                )
                            )
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.muted)
                        } else {
                            ForEach(
                                snapshot.weakKnowledge
                            ) { item in
                                weakness(item)
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Moyashi Recall")
            .onAppear {
                loadSnapshot()
            }
        }
    }

    private var successRateText: String {
        guard let rate = snapshot.successRateLast7Days else {
            return "—"
        }
        return "\(Int((rate * 100).rounded()))%"
    }

    private func loadSnapshot() {
        do {
            let repository = LearningRepository(
                context: modelContext
            )
            snapshot = try repository.homeSnapshot()
            loadError = nil
        } catch {
            loadError = language.text(
                "无法读取学习数据。",
                "学習データを読み込めませんでした。"
            )
        }
    }

    private func metric(
        _ value: String,
        _ label: String
    ) -> some View {
        VStack(
            alignment: .leading,
            spacing: 4
        ) {
            Text(value)
                .font(.title.bold())

            Text(label)
                .font(.caption)
                .foregroundStyle(AppTheme.muted)
        }
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
        .padding()
        .background(
            Color.gray.opacity(0.10)
        )
        .clipShape(
            RoundedRectangle(
                cornerRadius: AppTheme.cornerRadius
            )
        )
    }

    private func weakness(
        _ item: WeakKnowledgeSummary
    ) -> some View {
        HStack(
            alignment: .top,
            spacing: 10
        ) {
            Image(
                systemName: "exclamationmark.circle"
            )
            .foregroundStyle(AppTheme.accent)
            .frame(width: 22)

            VStack(
                alignment: .leading,
                spacing: 3
            ) {
                Text(item.title)
                    .foregroundStyle(AppTheme.ink)

                Text(
                    language.text(
                        "困难/重来 \(item.difficultReviews) / \(item.totalReviews) · \(item.sourceDisplay)",
                        "Hard/Again \(item.difficultReviews) / \(item.totalReviews) · \(item.sourceDisplay)"
                    )
                )
                .font(.caption)
                .foregroundStyle(AppTheme.muted)
                .lineLimit(2)
            }

            Spacer()
        }
        .padding(.vertical, 6)
    }
}
