import SwiftUI
import SwiftData

public struct CardsView: View {
    @EnvironmentObject private var language: LanguageStore
    @Environment(\.modelContext) private var modelContext

    @State private var searchText = ""
    @State private var allCards: [CardLibraryItem] = []
    @State private var loadError: String?

    @State private var sourceFilter:
        CardSourceFilter = .all

    @State private var timeFilter:
        CardTimeFilter = .all

    @State private var studyFilter:
        CardStudyFilter = .all

    @State private var sortOrder:
        CardSortOrder = .newest

    public init() {}

    private var filteredCards: [CardLibraryItem] {
        var result = allCards

        switch sourceFilter {
        case .all:
            break
        case .local:
            result = result.filter {
                $0.sourceKind == "file"
            }
        case .notion:
            result = result.filter {
                $0.sourceKind == "notion"
            }
        }

        let now = Date()

        if let interval =
            timeFilter.interval {
            let cutoff =
                now.addingTimeInterval(
                    -interval
                )

            result = result.filter {
                $0.createdAt >= cutoff
            }
        }

        switch studyFilter {
        case .all:
            break
        case .never:
            result = result.filter {
                $0.studyCount == 0
            }
        case .oneToTwo:
            result = result.filter {
                (1...2).contains(
                    $0.studyCount
                )
            }
        case .threePlus:
            result = result.filter {
                $0.studyCount >= 3
            }
        }

        switch sortOrder {
        case .newest:
            result.sort {
                $0.createdAt > $1.createdAt
            }
        case .oldest:
            result.sort {
                $0.createdAt < $1.createdAt
            }
        case .mostStudied:
            result.sort {
                if $0.studyCount
                    == $1.studyCount {
                    return $0.createdAt
                        > $1.createdAt
                }

                return $0.studyCount
                    > $1.studyCount
            }
        case .leastStudied:
            result.sort {
                if $0.studyCount
                    == $1.studyCount {
                    return $0.createdAt
                        > $1.createdAt
                }

                return $0.studyCount
                    < $1.studyCount
            }
        }

        return result
    }

    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                filterBar

                Divider()

                Group {
                    if let loadError {
                        ContentUnavailableView(
                            language.text(
                                "无法读取卡片",
                                "カードを読み込めません"
                            ),
                            systemImage:
                                "exclamationmark.triangle",
                            description:
                                Text(loadError)
                        )
                    } else if filteredCards.isEmpty {
                        ContentUnavailableView(
                            searchText.isEmpty
                                ? language.text(
                                    "当前筛选条件下暂无卡片",
                                    "現在の条件ではカードがありません"
                                )
                                : language.text(
                                    "没有匹配的卡片",
                                    "一致するカードがありません"
                                ),
                            systemImage:
                                "rectangle.stack"
                        )
                    } else {
                        List(
                            filteredCards
                        ) { card in
                            cardRow(card)
                        }
                        .listStyle(.plain)
                    }
                }
            }
            .navigationTitle(
                language.text(
                    "卡片",
                    "カード"
                )
            )
            .searchable(
                text: $searchText,
                prompt: language.text(
                    "搜索关键词、答案、说明或来源",
                    "キーワード、回答、説明、ソースを検索"
                )
            )
            .onAppear {
                loadCards()
            }
            .onChange(
                of: searchText
            ) { _, _ in
                loadCards()
            }
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
                        selection:
                            $sourceFilter
                    ) {
                        ForEach(
                            CardSourceFilter
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
                        icon:
                            "folder",
                        text:
                            sourceFilterLabel(
                                sourceFilter
                            )
                    )
                }

                Menu {
                    Picker(
                        "",
                        selection:
                            $timeFilter
                    ) {
                        ForEach(
                            CardTimeFilter
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
                        icon:
                            "calendar",
                        text:
                            timeFilterLabel(
                                timeFilter
                            )
                    )
                }

                Menu {
                    Picker(
                        "",
                        selection:
                            $studyFilter
                    ) {
                        ForEach(
                            CardStudyFilter
                                .allCases
                        ) { filter in
                            Text(
                                studyFilterLabel(
                                    filter
                                )
                            )
                            .tag(filter)
                        }
                    }
                } label: {
                    filterChip(
                        icon:
                            "repeat",
                        text:
                            studyFilterLabel(
                                studyFilter
                            )
                    )
                }

                Menu {
                    Picker(
                        "",
                        selection:
                            $sortOrder
                    ) {
                        ForEach(
                            CardSortOrder
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
                    || studyFilter != .all
                    || sortOrder != .newest {
                    Button {
                        sourceFilter = .all
                        timeFilter = .all
                        studyFilter = .all
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
            .padding(
                .horizontal
            )
            .padding(
                .vertical,
                10
            )
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
            Color.gray
                .opacity(0.10)
        )
        .clipShape(
            Capsule()
        )
    }

    // MARK: - Card row

    private func cardRow(
        _ card: CardLibraryItem
    ) -> some View {
        VStack(
            alignment: .leading,
            spacing: 7
        ) {
            HStack {
                Text(card.answer)
                    .font(
                        .headline
                    )

                Spacer()

                sourceBadge(card)
            }

            if !card.prompt.isEmpty {
                Text(card.prompt)
                    .font(.subheadline)
            }

            if !card.explanation.isEmpty {
                Text(
                    card.explanation
                )
                .foregroundStyle(
                    AppTheme.muted
                )
            }

            HStack(
                spacing: 12
            ) {
                Label(
                    card.createdAt
                        .formatted(
                            date:
                                .abbreviated,
                            time:
                                .omitted
                        ),
                    systemImage:
                        "calendar"
                )

                Label(
                    language.text(
                        "学习 \(card.studyCount) 次",
                        "学習 \(card.studyCount)回"
                    ),
                    systemImage:
                        "repeat"
                )

                Text(
                    cardTypeLabel(
                        card.cardType
                    )
                )
            }
            .font(.caption2)
            .foregroundStyle(
                AppTheme.muted
            )

            Text(
                card.sourceDisplay
            )
            .font(.caption)
            .foregroundStyle(
                AppTheme.muted
            )
            .lineLimit(2)
        }
        .padding(
            .vertical,
            5
        )
    }

    @ViewBuilder
    private func sourceBadge(
        _ card: CardLibraryItem
    ) -> some View {
        if card.sourceKind
            == "notion" {
            Label(
                "Notion",
                systemImage:
                    "n.square"
            )
            .font(.caption2)
            .foregroundStyle(
                AppTheme.accent
            )
        } else if card.sourceKind
            == "file" {
            Label(
                language.text(
                    "本地",
                    "ローカル"
                ),
                systemImage:
                    "doc"
            )
            .font(.caption2)
            .foregroundStyle(
                AppTheme.accent
            )
        }
    }

    // MARK: - Data

    private func loadCards() {
        do {
            let repository =
                LearningRepository(
                    context:
                        modelContext
                )

            allCards =
                try repository
                    .cardLibraryItems(
                        searchText:
                            searchText
                    )

            loadError = nil
        } catch {
            loadError =
                language.text(
                    "无法读取卡片数据。",
                    "カードデータを読み込めませんでした。"
                )
        }
    }

    // MARK: - Labels

    private func sourceFilterLabel(
        _ filter: CardSourceFilter
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
        _ filter: CardTimeFilter
    ) -> String {
        switch filter {
        case .all:
            return language.text(
                "全部时间",
                "全期間"
            )
        case .day:
            return language.text(
                "24小时",
                "24時間"
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

    private func studyFilterLabel(
        _ filter: CardStudyFilter
    ) -> String {
        switch filter {
        case .all:
            return language.text(
                "全部次数",
                "全回数"
            )
        case .never:
            return language.text(
                "未学习",
                "未学習"
            )
        case .oneToTwo:
            return language.text(
                "1–2次",
                "1–2回"
            )
        case .threePlus:
            return language.text(
                "3次以上",
                "3回以上"
            )
        }
    }

    private func sortOrderLabel(
        _ order: CardSortOrder
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
        case .mostStudied:
            return language.text(
                "学习最多",
                "学習回数が多い"
            )
        case .leastStudied:
            return language.text(
                "学习最少",
                "学習回数が少ない"
            )
        }
    }

    private func cardTypeLabel(
        _ rawValue: String
    ) -> String {
        guard let type =
            ReviewCardType(
                rawValue: rawValue
            )
        else {
            return rawValue
        }

        switch type {
        case .zhToJa:
            return "中 → 日"
        case .jaToZh:
            return "日 → 中"
        case .cloze:
            return "Cloze"
        case .contrast:
            return language.text(
                "对比",
                "比較"
            )
        case .application:
            return language.text(
                "应用",
                "応用"
            )
        }
    }
}

private enum CardSourceFilter:
    String,
    CaseIterable,
    Identifiable
{
    case all
    case local
    case notion

    var id: String {
        rawValue
    }
}

private enum CardTimeFilter:
    String,
    CaseIterable,
    Identifiable
{
    case all
    case day
    case week
    case month

    var id: String {
        rawValue
    }

    var interval: TimeInterval? {
        switch self {
        case .all:
            return nil
        case .day:
            return 86_400
        case .week:
            return 7 * 86_400
        case .month:
            return 30 * 86_400
        }
    }
}

private enum CardStudyFilter:
    String,
    CaseIterable,
    Identifiable
{
    case all
    case never
    case oneToTwo
    case threePlus

    var id: String {
        rawValue
    }
}

private enum CardSortOrder:
    String,
    CaseIterable,
    Identifiable
{
    case newest
    case oldest
    case mostStudied
    case leastStudied

    var id: String {
        rawValue
    }
}
