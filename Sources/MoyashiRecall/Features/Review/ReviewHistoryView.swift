import SwiftUI
import SwiftData

private enum ReviewHistoryFilter: String, CaseIterable, Identifiable {
    case all
    case again
    case hard
    case good
    case easy

    var id: String { rawValue }

    var rating: ReviewRating? {
        switch self {
        case .all:
            return nil
        case .again:
            return .again
        case .hard:
            return .hard
        case .good:
            return .good
        case .easy:
            return .easy
        }
    }
}

private struct ReviewHistoryDaySection: Identifiable {
    let day: Date
    let items: [ReviewHistorySummary]

    var id: Date { day }
}

public struct ReviewHistoryView: View {
    @EnvironmentObject private var language: LanguageStore
    @Environment(\.modelContext) private var modelContext

    @State private var items: [ReviewHistorySummary] = []
    @State private var filter: ReviewHistoryFilter = .all
    @State private var searchText = ""
    @State private var loadError: String?

    public init() {}

    public var body: some View {
        Group {
            if let loadError {
                ContentUnavailableView(
                    language.text(
                        "无法读取复习记录",
                        "復習履歴を読み込めません"
                    ),
                    systemImage: "exclamationmark.triangle",
                    description: Text(loadError)
                )
            } else if items.isEmpty {
                ContentUnavailableView(
                    language.text(
                        "还没有复习记录",
                        "復習履歴はまだありません"
                    ),
                    systemImage: "clock.arrow.circlepath"
                )
            } else if filteredItems.isEmpty {
                ContentUnavailableView(
                    language.text(
                        "没有符合条件的记录",
                        "条件に一致する履歴はありません"
                    ),
                    systemImage: "line.3.horizontal.decrease.circle",
                    description: Text(
                        language.text(
                            "可以更改评分筛选或搜索内容。",
                            "評価フィルターまたは検索条件を変更してください。"
                        )
                    )
                )
            } else {
                List {
                    ForEach(daySections) { section in
                        Section(
                            dayLabel(section.day)
                        ) {
                            ForEach(section.items) { item in
                                historyRow(item)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle(
            language.text(
                "复习记录",
                "復習履歴"
            )
        )
        .searchable(
            text: $searchText,
            prompt: language.text(
                "搜索问题、答案或来源",
                "問題・答え・ソースを検索"
            )
        )
        .toolbar {
            ToolbarItem(
                placement: .primaryAction
            ) {
                Menu {
                    Picker(
                        language.text(
                            "评分筛选",
                            "評価フィルター"
                        ),
                        selection: $filter
                    ) {
                        ForEach(
                            ReviewHistoryFilter.allCases
                        ) { item in
                            Text(
                                filterLabel(item)
                            )
                            .tag(item)
                        }
                    }
                } label: {
                    Label(
                        filterLabel(filter),
                        systemImage: "line.3.horizontal.decrease.circle"
                    )
                }
            }
        }
        .onAppear {
            loadHistory()
        }
    }

    private var filteredItems: [ReviewHistorySummary] {
        let normalized = searchText.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        return items.filter { item in
            if let rating = filter.rating,
               item.rating != rating {
                return false
            }

            guard !normalized.isEmpty else {
                return true
            }

            return item.prompt.localizedCaseInsensitiveContains(
                normalized
            )
                || item.answer.localizedCaseInsensitiveContains(
                    normalized
                )
                || item.sourceDisplay.localizedCaseInsensitiveContains(
                    normalized
                )
        }
    }

    private var daySections: [ReviewHistoryDaySection] {
        let calendar = Calendar.current
        let groups = Dictionary(
            grouping: filteredItems
        ) {
            calendar.startOfDay(
                for: $0.reviewedAt
            )
        }

        return groups
            .map { day, entries in
                ReviewHistoryDaySection(
                    day: day,
                    items: entries.sorted {
                        $0.reviewedAt > $1.reviewedAt
                    }
                )
            }
            .sorted {
                $0.day > $1.day
            }
    }

    @ViewBuilder
    private func historyRow(
        _ item: ReviewHistorySummary
    ) -> some View {
        VStack(
            alignment: .leading,
            spacing: 6
        ) {
            HStack {
                Text(
                    ratingLabel(
                        item.rating
                    )
                )
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppTheme.accent)

                Spacer()

                Text(
                    item.reviewedAt.formatted(
                        date: .omitted,
                        time: .shortened
                    )
                )
                .font(.caption)
                .foregroundStyle(AppTheme.muted)
            }

            Text(item.prompt)
                .font(.headline)

            Text(item.answer)
                .foregroundStyle(AppTheme.muted)

            if !item.sourceDisplay.isEmpty {
                Text(item.sourceDisplay)
                    .font(.caption2)
                    .foregroundStyle(AppTheme.muted)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 4)
    }

    private func loadHistory() {
        do {
            items = try LearningRepository(
                context: modelContext
            )
            .recentReviewHistory()
            loadError = nil
        } catch {
            loadError = language.text(
                "无法读取本地复习历史。",
                "ローカルの復習履歴を読み込めませんでした。"
            )
        }
    }

    private func filterLabel(
        _ filter: ReviewHistoryFilter
    ) -> String {
        switch filter {
        case .all:
            return language.text(
                "全部评分",
                "すべての評価"
            )
        case .again:
            return ratingLabel(.again)
        case .hard:
            return ratingLabel(.hard)
        case .good:
            return ratingLabel(.good)
        case .easy:
            return ratingLabel(.easy)
        }
    }

    private func ratingLabel(
        _ rating: ReviewRating
    ) -> String {
        switch rating {
        case .again:
            return language.text(
                "重来",
                "もう一度"
            )
        case .hard:
            return language.text(
                "困难",
                "難しい"
            )
        case .good:
            return language.text(
                "良好",
                "良い"
            )
        case .easy:
            return language.text(
                "简单",
                "簡単"
            )
        }
    }

    private func dayLabel(
        _ day: Date
    ) -> String {
        let calendar = Calendar.current

        if calendar.isDateInToday(day) {
            return language.text(
                "今天",
                "今日"
            )
        }

        if calendar.isDateInYesterday(day) {
            return language.text(
                "昨天",
                "昨日"
            )
        }

        return day.formatted(
            date: .abbreviated,
            time: .omitted
        )
    }
}
