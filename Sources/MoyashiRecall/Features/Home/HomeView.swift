import SwiftUI
import SwiftData

public struct HomeView: View {
    private let openReviewTab: () -> Void
    @EnvironmentObject private var language: LanguageStore
    @Environment(\.modelContext) private var modelContext

    @State private var snapshot = HomeSnapshot(
        dueCount: 0,
        streakDays: 0
    )
    @State private var loadError: String?
    @State private var lastSessionSummary: ReviewSessionSummary?
    @State private var readiness: AppReadinessSnapshot?

    @State private var reviewScope: StudyScopePreferences?
    @State private var scopedDueCount = 0

    public init(
        openReviewTab: @escaping () -> Void = {}
    ) {
        self.openReviewTab = openReviewTab
    }

    private var hasValidReviewScope: Bool {
        guard let reviewScope else {
            return false
        }

        guard
            !reviewScope.cardTypes.isEmpty,
            let documentIDs = reviewScope.documentIDs,
            !documentIDs.isEmpty
        else {
            return false
        }

        return true
    }

    private var effectiveTodayReviewCount: Int {
        guard let reviewScope else {
            return 0
        }

        if reviewScope.reviewCount == 0 {
            return scopedDueCount
        }

        return min(
            reviewScope.reviewCount,
            scopedDueCount
        )
    }

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
                            "\(scopedDueCount)",
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
                                    !hasValidReviewScope
                                        ? "请先选择今天要复习的卡片范围。"
                                        : scopedDueCount == 0
                                            ? "当前选择范围没有到期卡片。"
                                            : "\(scopedDueCount) 张卡片等待复习。",
                                    !hasValidReviewScope
                                        ? "まず今日復習するカード範囲を選択してください。"
                                        : scopedDueCount == 0
                                            ? "現在選択した範囲に期限カードはありません。"
                                            : "\(scopedDueCount)枚のカードが復習待ちです。"
                                )
                            )
                            .foregroundStyle(AppTheme.muted)
                        }

                        Button {
                            openReviewTab()
                        } label: {
                            Label(
                                language.text(
                                    !hasValidReviewScope
                                        ? "请选择复习卡片"
                                        : effectiveTodayReviewCount == 0
                                            ? "当前范围没有到期卡片"
                                            : "开始今日复习 · \(effectiveTodayReviewCount) 张",
                                    !hasValidReviewScope
                                        ? "復習カードを選択してください"
                                        : effectiveTodayReviewCount == 0
                                            ? "現在の範囲に期限カードはありません"
                                            : "今日の復習を開始 · \(effectiveTodayReviewCount)枚"
                                ),
                                systemImage: "play.fill"
                            )
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(AppTheme.accent)
                        .disabled(
                            !hasValidReviewScope
                            || effectiveTodayReviewCount == 0
                        )

                        HStack(spacing: 12) {
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
                                .font(.body.weight(.semibold))
                                .frame(
                                    maxWidth: .infinity
                                )
                                .padding(
                                    .vertical,
                                    10
                                )
                            }
                            .buttonStyle(.bordered)

                            NavigationLink {
                                ReviewHistoryView()
                            } label: {
                                Label(
                                    language.text(
                                        "复习记录",
                                        "復習履歴"
                                    ),
                                    systemImage:
                                        "clock.arrow.circlepath"
                                )
                                .font(.body.weight(.semibold))
                                .frame(
                                    maxWidth: .infinity
                                )
                                .padding(
                                    .vertical,
                                    10
                                )
                            }
                            .buttonStyle(.bordered)
                        }
                        .tint(AppTheme.accent)
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
                                weakKnowledgeGroups
                            ) { group in
                                VStack(
                                    alignment: .leading,
                                    spacing: 6
                                ) {
                                    HStack(spacing: 7) {
                                        Image(
                                            systemName:
                                                group.systemImage
                                        )
                                        .foregroundStyle(
                                            AppTheme.accent
                                        )

                                        Text(group.title)
                                            .font(
                                                .subheadline
                                                    .weight(
                                                        .semibold
                                                    )
                                            )

                                        Spacer()

                                        Text(
                                            "\(group.items.count)"
                                        )
                                        .font(.caption)
                                        .foregroundStyle(
                                            AppTheme.muted
                                        )
                                    }
                                    .padding(
                                        .top,
                                        6
                                    )

                                    ForEach(
                                        group.items
                                    ) { item in
                                        weakness(item)
                                    }
                                }

                                if group.id
                                    != weakKnowledgeGroups
                                        .last?.id {
                                    Divider()
                                }
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
                loadReviewScope()

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

            if !readiness.learningSourceReady {
                Text(
                    language.text(
                        "先导入学习资料。你可以从本地文件开始，也可以连接 Notion。",
                        "まず学習資料を読み込んでください。ローカルファイルまたはNotionを利用できます。"
                    )
                )
                .font(.subheadline)
                .foregroundStyle(AppTheme.muted)

                NavigationLink {
                    LibraryView()
                } label: {
                    Label(
                        language.text(
                            "打开资料库",
                            "ライブラリを開く"
                        ),
                        systemImage: "folder"
                    )
                }

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

            if readiness.learningSourceReady
                && !readiness.aiReady {
                Text(
                    language.text(
                        "资料已就绪。下一步配置 AI Provider 和模型。",
                        "資料は準備済みです。次にAI Providerとモデルを設定してください。"
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

            if readiness.learningSourceReady
                && readiness.aiReady
                && readiness.activeCardCount == 0 {
                Text(
                    language.text(
                        "学习资料和 AI 已就绪。进入资料库并生成第一批复习卡片。",
                        "学習資料とAIの準備が完了しました。ライブラリで最初の復習カードを生成してください。"
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
        if scopedDueCount > 0 {
            body = language.text(
                "当前复习范围有 \(scopedDueCount) 张卡片到期。",
                "現在の復習範囲には\(scopedDueCount)枚のカードが期限です。"
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

    private func loadReviewScope() {
        let preferences =
            StudyScopePreferencesStore()
                .load()

        reviewScope = preferences

        guard
            let preferences,
            !preferences.cardTypes.isEmpty,
            let documentIDs =
                preferences.documentIDs,
            !documentIDs.isEmpty
        else {
            scopedDueCount = 0
            return
        }

        do {
            let repository =
                LearningRepository(
                    context: modelContext
                )

            scopedDueCount =
                try repository.dueCardCount(
                    sourceKeys:
                        preferences.sourceKeys,
                    cardTypes:
                        preferences.cardTypes,
                    sourceDocumentIDs:
                        documentIDs
                )
        } catch {
            scopedDueCount = 0
        }
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

    private var weakKnowledgeGroups:
        [WeakKnowledgeGroup]
    {
        let grouped = Dictionary(
            grouping: snapshot.weakKnowledge
        ) { item in
            weakSourceGroup(
                from: item.sourceDisplay
            )
        }

        return grouped
            .map { key, items in
                WeakKnowledgeGroup(
                    id: key.id,
                    title: key.title,
                    systemImage:
                        key.systemImage,
                    items: items
                )
            }
            .sorted {
                $0.title.localizedStandardCompare(
                    $1.title
                ) == .orderedAscending
            }
    }

    private func weakSourceGroup(
        from sourceDisplay: String
    ) -> WeakSourceGroupKey {
        let components =
            sourceDisplay
                .components(
                    separatedBy: " / "
                )
                .filter {
                    !$0.isEmpty
                }

        guard let first =
            components.first
        else {
            return WeakSourceGroupKey(
                id: "unknown",
                title: language.text(
                    "其他资料",
                    "その他の資料"
                ),
                systemImage: "doc"
            )
        }

        if first == "Learning Home" {
            let source =
                components.count >= 2
                ? components[1]
                : "Learning Home"

            return WeakSourceGroupKey(
                id: "notion-\(source)",
                title: language.text(
                    "Notion · \(source)",
                    "Notion · \(source)"
                ),
                systemImage: "n.square"
            )
        }

        if first == "Imported Files" {
            let source =
                components.count >= 2
                ? components[1]
                : language.text(
                    "本地资料",
                    "ローカル資料"
                )

            return WeakSourceGroupKey(
                id: "file-\(source)",
                title: language.text(
                    "本地资料 · \(source)",
                    "ローカル資料 · \(source)"
                ),
                systemImage: "doc.text"
            )
        }

        return WeakSourceGroupKey(
            id: first,
            title: first,
            systemImage: "doc"
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


private struct WeakSourceGroupKey: Hashable {
    let id: String
    let title: String
    let systemImage: String
}

private struct WeakKnowledgeGroup: Identifiable {
    let id: String
    let title: String
    let systemImage: String
    let items: [WeakKnowledgeSummary]
}
