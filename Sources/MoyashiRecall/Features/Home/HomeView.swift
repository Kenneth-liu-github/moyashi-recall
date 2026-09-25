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
    @State private var lastSessionSummary: ReviewSessionSummary?
    @State private var readiness: AppReadinessSnapshot?

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

                    if let readiness,
                       !readiness.readyForReview {
                        setupCard(readiness)
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
                                .foregroundStyle(AppTheme.accent)
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
                            ReviewView(
                                sessionLimit: min(
                                    max(snapshot.dueCount, 1),
                                    20
                                )
                            )
                        } label: {
                            Label(
                                language.text(
                                    snapshot.dueCount == 0
                                        ? "今天没有到期卡片"
                                        : "开始今日复习 · \(min(snapshot.dueCount, 20)) 张",
                                    snapshot.dueCount == 0
                                        ? "今日は期限カードがありません"
                                        : "今日の復習を開始 · \(min(snapshot.dueCount, 20))枚"
                                ),
                                systemImage: "play.fill"
                            )
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                snapshot.dueCount == 0
                                    ? Color.gray.opacity(0.18)
                                    : AppTheme.accent
                            )
                            .foregroundStyle(
                                snapshot.dueCount == 0
                                    ? AppTheme.muted
                                    : .white
                            )
                            .clipShape(
                                RoundedRectangle(
                                    cornerRadius: 14
                                )
                            )
                        }
                        .disabled(snapshot.dueCount == 0)

                        HStack {
                            NavigationLink {
                                StudyScopeView()
                            } label: {
                                Label(
                                    language.text(
                                        "选择学习范围",
                                        "学習範囲を選択"
                                    ),
                                    systemImage: "slider.horizontal.3"
                                )
                            }

                            Spacer()

                            NavigationLink {
                                ReviewHistoryView()
                            } label: {
                                Label(
                                    language.text(
                                        "复习记录",
                                        "復習履歴"
                                    ),
                                    systemImage: "clock.arrow.circlepath"
                                )
                            }
                        }
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppTheme.accent)
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

                    if let summary = lastSessionSummary {
                        VStack(
                            alignment: .leading,
                            spacing: 10
                        ) {
                            HStack {
                                Text(
                                    language.text(
                                        "最近一次复习",
                                        "直近の復習"
                                    )
                                )
                                .font(.headline)

                                Spacer()

                                Text(
                                    summary.completedAt.formatted(
                                        date: .abbreviated,
                                        time: .shortened
                                    )
                                )
                                .font(.caption)
                                .foregroundStyle(AppTheme.muted)
                            }

                            Text(
                                language.text(
                                    "完成 \(summary.reviewedCount) 张 · 重来 \(summary.againCount) · 困难 \(summary.hardCount) · 良好 \(summary.goodCount) · 简单 \(summary.easyCount)",
                                    "\(summary.reviewedCount)枚完了 · もう一度 \(summary.againCount) · 難しい \(summary.hardCount) · 良い \(summary.goodCount) · 簡単 \(summary.easyCount)"
                                )
                            )
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.muted)
                        }
                        .padding(16)
                        .background(
                            Color.gray.opacity(0.10)
                        )
                        .clipShape(
                            RoundedRectangle(
                                cornerRadius: AppTheme.cornerRadius
                            )
                        )
                    }

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
                loadReadiness()
                loadLastSessionSummary()

                Task {
                    await refreshReviewReminder()
                }
            }
        }
    }

    @ViewBuilder
    private func setupCard(
        _ readiness: AppReadinessSnapshot
    ) -> some View {
        VStack(
            alignment: .leading,
            spacing: 12
        ) {
            Text(
                language.text(
                    "开始使用",
                    "はじめに"
                )
            )
            .font(.headline)

            if !readiness.notionReady {
                Text(
                    language.text(
                        "先连接 Notion 并同步学习资料。",
                        "まずNotionを接続して学習資料を同期してください。"
                    )
                )
                .font(.subheadline)
                .foregroundStyle(AppTheme.muted)

                NavigationLink {
                    NotionConnectionView()
                } label: {
                    Label(
                        language.text(
                            "配置 Notion",
                            "Notionを設定"
                        ),
                        systemImage: "arrow.right.circle"
                    )
                }
            }

            if readiness.notionReady
                && !readiness.aiReady {
                Text(
                    language.text(
                        "资料已同步。下一步配置 AI Provider 和模型。",
                        "資料は同期済みです。次にAI Providerとモデルを設定してください。"
                    )
                )
                .font(.subheadline)
                .foregroundStyle(AppTheme.muted)

                NavigationLink {
                    AIProviderSettingsView()
                } label: {
                    Label(
                        language.text(
                            "配置 AI",
                            "AIを設定"
                        ),
                        systemImage: "arrow.right.circle"
                    )
                }
            }

            if readiness.notionReady
                && readiness.aiReady
                && readiness.activeCardCount == 0 {
                Text(
                    language.text(
                        "Notion 和 AI 已就绪。进入资料库，打开同步页面并生成第一批复习卡片。",
                        "NotionとAIの準備が完了しました。ライブラリで同期ページを開き、最初の復習カードを生成してください。"
                    )
                )
                .font(.subheadline)
                .foregroundStyle(AppTheme.muted)
            }
        }
        .padding(16)
        .background(
            Color.gray.opacity(0.10)
        )
        .clipShape(
            RoundedRectangle(
                cornerRadius: AppTheme.cornerRadius
            )
        )
    }

    private var successRateText: String {
        guard let rate = snapshot.successRateLast7Days else {
            return "—"
        }
        return "\(Int((rate * 100).rounded()))%"
    }

    @MainActor
    private func refreshReviewReminder() async {
        let preferences = ReviewReminderPreferencesStore()
            .load()

        guard preferences.enabled else {
            return
        }

        let service = ReviewReminderService()
        guard await service.isAuthorized() else {
            return
        }

        let body: String
        if snapshot.dueCount > 0 {
            body = language.text(
                "今天有 \(snapshot.dueCount) 张日语卡片到期。",
                "今日は\(snapshot.dueCount)枚の日本語カードが期限です。"
            )
        } else {
            body = language.text(
                "打开 Moyashi Recall 看看今天的复习计划。",
                "Moyashi Recallで今日の復習予定を確認しましょう。"
            )
        }

        try? await service.scheduleDaily(
            hour: preferences.hour,
            minute: preferences.minute,
            title: "Moyashi Recall",
            body: body
        )
    }

    private func loadReadiness() {
        do {
            readiness = try AppReadinessService(
                context: modelContext
            ).snapshot()
        } catch {
            readiness = nil
        }
    }

    private func loadLastSessionSummary() {
        guard
            let summary = ReviewSessionSummaryStore().load(),
            let latestReviewAt = snapshot.latestReviewAt,
            summary.completedAt >= latestReviewAt
        else {
            lastSessionSummary = nil
            return
        }

        lastSessionSummary = summary
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
        NavigationLink {
            ReviewView(
                knowledgeItemIDs: [item.id],
                sessionLimit: 20
            )
        } label: {
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

                Image(
                    systemName: "chevron.right"
                )
                .font(.caption)
                .foregroundStyle(AppTheme.muted)
            }
            .padding(.vertical, 6)
        }
        .buttonStyle(.plain)
    }
}
