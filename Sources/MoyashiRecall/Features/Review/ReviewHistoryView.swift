import SwiftUI
import SwiftData

private enum ReviewHistoryRatingFilter:
    String,
    CaseIterable,
    Identifiable
{
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

private enum ReviewHistorySourceFilter:
    String,
    CaseIterable,
    Identifiable
{
    case all
    case local
    case notion

    var id: String { rawValue }
}

private enum ReviewHistoryTimeFilter:
    String,
    CaseIterable,
    Identifiable
{
    case all
    case today
    case week
    case month

    var id: String { rawValue }
}

private enum ReviewHistorySortOrder:
    String,
    CaseIterable,
    Identifiable
{
    case newest
    case oldest

    var id: String { rawValue }
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
    @State private var searchText = ""

    @State private var ratingFilter:
        ReviewHistoryRatingFilter = .all

    @State private var sourceFilter:
        ReviewHistorySourceFilter = .all

    @State private var timeFilter:
        ReviewHistoryTimeFilter = .all

    @State private var sortOrder:
        ReviewHistorySortOrder = .newest

    @State private var loadError: String?

    public init() {}

    public var body: some View {
        VStack(spacing: 0) {
            filterBar

            Divider()

            Group {
                if let loadError {
                    ContentUnavailableView(
                        language.text(
                            "无法读取复习记录",
                            "復習履歴を読み込めません"
                        ),
                        systemImage:
                            "exclamationmark.triangle",
                        description:
                            Text(loadError)
                    )
                } else if items.isEmpty {
                    ContentUnavailableView(
                        language.text(
                            "还没有复习记录",
                            "復習履歴はまだありません"
                        ),
                        systemImage:
                            "clock.arrow.circlepath"
                    )
                } else if filteredItems.isEmpty {
                    ContentUnavailableView(
                        language.text(
                            "没有符合条件的记录",
                            "条件に一致する履歴はありません"
                        ),
                        systemImage:
                            "line.3.horizontal.decrease.circle",
                        description: Text(
                            language.text(
                                "可以调整搜索、来源、时间或评分条件。",
                                "検索・ソース・期間・評価条件を変更してください。"
                            )
                        )
                    )
                } else {
                    List {
                        ForEach(daySections) { section in
                            Section(
                                dayLabel(section.day)
                            ) {
                                ForEach(
                                    section.items
                                ) { item in
                                    historyRow(item)
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
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
        .onAppear {
            loadHistory()
        }
    }

    // MARK: - Filter bar

    private var filterBar: some View {
        ScrollView(
            .horizontal,
            showsIndicators: false
        ) {
            HStack(spacing: 10) {
                Menu {
                    Picker(
                        "",
                        selection: $sourceFilter
                    ) {
                        ForEach(
                            ReviewHistorySourceFilter
                                .allCases
                        ) { filter in
                            Text(
                                sourceFilterLabel(
                                    filter
                                )
                            )
                            .tag(filter)
                        }
                    }
                } label: {
                    filterChip(
                        icon: "folder",
                        text:
                            sourceFilterLabel(
                                sourceFilter
                            )
                    )
                }

                Menu {
                    Picker(
                        "",
                        selection: $timeFilter
                    ) {
                        ForEach(
                            ReviewHistoryTimeFilter
                                .allCases
                        ) { filter in
                            Text(
                                timeFilterLabel(
                                    filter
                                )
                            )
                            .tag(filter)
                        }
                    }
                } label: {
                    filterChip(
                        icon: "calendar",
                        text:
                            timeFilterLabel(
                                timeFilter
                            )
                    )
                }

                Menu {
                    Picker(
                        "",
                        selection: $ratingFilter
                    ) {
                        ForEach(
                            ReviewHistoryRatingFilter
                                .allCases
                        ) { filter in
                            Text(
                                ratingFilterLabel(
                                    filter
                                )
                            )
                            .tag(filter)
                        }
                    }
                } label: {
                    filterChip(
                        icon:
                            "line.3.horizontal.decrease.circle",
                        text:
                            ratingFilterLabel(
                                ratingFilter
                            )
                    )
                }

                Menu {
                    Picker(
                        "",
                        selection: $sortOrder
                    ) {
                        ForEach(
                            ReviewHistorySortOrder
                                .allCases
                        ) { order in
                            Text(
                                sortOrderLabel(
                                    order
                                )
                            )
                            .tag(order)
                        }
                    }
                } label: {
                    filterChip(
                        icon:
                            "arrow.up.arrow.down",
                        text:
                            sortOrderLabel(
                                sortOrder
                            )
                    )
                }

                if sourceFilter != .all
                    || timeFilter != .all
                    || ratingFilter != .all
                    || sortOrder != .newest
                {
                    Button {
                        sourceFilter = .all
                        timeFilter = .all
                        ratingFilter = .all
                        sortOrder = .newest
                    } label: {
                        Label(
                            language.text(
                                "重置",
                                "リセット"
                            ),
                            systemImage:
                                "arrow.counterclockwise"
                        )
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
        }
    }

    private func filterChip(
        icon: String,
        text: String
    ) -> some View {
        Label(
            text,
            systemImage: icon
        )
        .font(
            .subheadline
                .weight(.medium)
        )
        .padding(
            .horizontal,
            12
        )
        .padding(
            .vertical,
            7
        )
        .background(
            Color.gray.opacity(0.10)
        )
        .clipShape(
            Capsule()
        )
    }

    // MARK: - Filtering

    private var filteredItems: [ReviewHistorySummary] {
        let normalized =
            searchText.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        var result = items.filter { item in
            if let rating =
                ratingFilter.rating,
               item.rating != rating {
                return false
            }

            switch sourceFilter {
            case .all:
                break

            case .local:
                guard item.sourceKind == "file"
                else {
                    return false
                }

            case .notion:
                guard item.sourceKind == "notion"
                else {
                    return false
                }
            }

            if !matchesTimeFilter(
                item.reviewedAt
            ) {
                return false
            }

            guard !normalized.isEmpty else {
                return true
            }

            return item.prompt
                .localizedCaseInsensitiveContains(
                    normalized
                )
                || item.answer
                    .localizedCaseInsensitiveContains(
                        normalized
                    )
                || item.sourceDisplay
                    .localizedCaseInsensitiveContains(
                        normalized
                    )
        }

        switch sortOrder {
        case .newest:
            result.sort {
                $0.reviewedAt
                    > $1.reviewedAt
            }

        case .oldest:
            result.sort {
                $0.reviewedAt
                    < $1.reviewedAt
            }
        }

        return result
    }

    private func matchesTimeFilter(
        _ date: Date
    ) -> Bool {
        let calendar = Calendar.current
        let now = Date()

        switch timeFilter {
        case .all:
            return true

        case .today:
            return calendar.isDateInToday(
                date
            )

        case .week:
            guard let cutoff =
                calendar.date(
                    byAdding: .day,
                    value: -7,
                    to: now
                )
            else {
                return true
            }

            return date >= cutoff

        case .month:
            guard let cutoff =
                calendar.date(
                    byAdding: .day,
                    value: -30,
                    to: now
                )
            else {
                return true
            }

            return date >= cutoff
        }
    }

    // MARK: - Sections

    private var daySections:
        [ReviewHistoryDaySection]
    {
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
                    items: entries
                )
            }
            .sorted {
                switch sortOrder {
                case .newest:
                    return $0.day > $1.day
                case .oldest:
                    return $0.day < $1.day
                }
            }
    }

    // MARK: - Row

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
                .font(
                    .caption
                        .weight(.semibold)
                )
                .foregroundStyle(
                    AppTheme.accent
                )

                Spacer()

                Text(
                    item.reviewedAt
                        .formatted(
                            date: .omitted,
                            time: .shortened
                        )
                )
                .font(.caption)
                .foregroundStyle(
                    AppTheme.muted
                )
            }

            Text(item.prompt)
                .font(.headline)

            Text(item.answer)
                .foregroundStyle(
                    AppTheme.muted
                )

            if !item.sourceDisplay.isEmpty {
                HStack(spacing: 6) {
                    Image(
                        systemName:
                            item.sourceKind == "notion"
                            ? "n.square"
                            : "doc"
                    )

                    Text(
                        item.sourceDisplay
                    )
                    .lineLimit(2)
                }
                .font(.caption2)
                .foregroundStyle(
                    AppTheme.muted
                )
            }
        }
        .padding(
            .vertical,
            4
        )
    }

    // MARK: - Load

    private func loadHistory() {
        do {
            items =
                try LearningRepository(
                    context:
                        modelContext
                )
                .recentReviewHistory(
                    limit: 500
                )

            loadError = nil
        } catch {
            loadError =
                language.text(
                    "无法读取本地复习历史。",
                    "ローカルの復習履歴を読み込めませんでした。"
                )
        }
    }

    // MARK: - Labels

    private func sourceFilterLabel(
        _ filter:
            ReviewHistorySourceFilter
    ) -> String {
        switch filter {
        case .all:
            return language.text(
                "全部来源",
                "全ソース"
            )
        case .local:
            return language.text(
                "本地",
                "ローカル"
            )
        case .notion:
            return "Notion"
        }
    }

    private func timeFilterLabel(
        _ filter:
            ReviewHistoryTimeFilter
    ) -> String {
        switch filter {
        case .all:
            return language.text(
                "全部时间",
                "全期間"
            )
        case .today:
            return language.text(
                "今天",
                "今日"
            )
        case .week:
            return language.text(
                "7天",
                "7日"
            )
        case .month:
            return language.text(
                "30天",
                "30日"
            )
        }
    }

    private func ratingFilterLabel(
        _ filter:
            ReviewHistoryRatingFilter
    ) -> String {
        switch filter {
        case .all:
            return language.text(
                "全部评分",
                "全評価"
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

    private func sortOrderLabel(
        _ order:
            ReviewHistorySortOrder
    ) -> String {
        switch order {
        case .newest:
            return language.text(
                "最新",
                "新しい順"
            )
        case .oldest:
            return language.text(
                "最早",
                "古い順"
            )
        }
    }

    private func ratingLabel(
        _ rating:
            ReviewRating
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
        let calendar =
            Calendar.current

        if calendar.isDateInToday(
            day
        ) {
            return language.text(
                "今天",
                "今日"
            )
        }

        if calendar.isDateInYesterday(
            day
        ) {
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
