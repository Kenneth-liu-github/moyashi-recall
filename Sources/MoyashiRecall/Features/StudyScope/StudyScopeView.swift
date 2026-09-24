import SwiftUI
import SwiftData

public struct StudyScopeView: View {
    @EnvironmentObject private var language: LanguageStore
    @Environment(\.modelContext) private var modelContext

    @State private var selectedSources = Set<UUID>()
    @State private var selectedCardTypes = Set(
        ReviewCardType.allCases
    )
    @State private var reviewCount = 20
    @State private var sourceCounts: [String: Int] = [:]

    public init() {}

    private var selectedSourceKeys: Set<String> {
        Set(
            MockData.sources
                .filter {
                    selectedSources.contains($0.id)
                }
                .map(\.key)
        )
    }

    private var selectedCardTypeIDs: Set<String> {
        Set(selectedCardTypes.map(\.rawValue))
    }

    public var body: some View {
        List {
            Section {
                ForEach(MockData.sources) { source in
                    Button {
                        toggleSource(source.id)
                    } label: {
                        HStack(spacing: 12) {
                            Image(
                                systemName: selectedSources
                                    .contains(source.id)
                                    ? "checkmark.circle.fill"
                                    : "circle"
                            )
                            .foregroundStyle(AppTheme.accent)

                            VStack(
                                alignment: .leading,
                                spacing: 3
                            ) {
                                Text(source.title)
                                    .foregroundStyle(
                                        AppTheme.ink
                                    )
                                Text(source.detail)
                                    .font(.caption)
                                    .foregroundStyle(
                                        AppTheme.muted
                                    )
                            }

                            Spacer()

                            Text(
                                "\(sourceCounts[source.key, default: 0])"
                            )
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.muted)
                        }
                    }
                }
            } header: {
                Text(
                    language.text(
                        "学习来源（可多选）",
                        "学習ソース（複数選択可）"
                    )
                )
            }

            Section(
                language.text(
                    "本次复习数量",
                    "今回の復習枚数"
                )
            ) {
                Picker(
                    language.text(
                        "卡片数量",
                        "カード枚数"
                    ),
                    selection: $reviewCount
                ) {
                    Text("10").tag(10)
                    Text("20").tag(20)
                    Text("30").tag(30)
                }
                .pickerStyle(.segmented)
            }

            Section(
                language.text(
                    "卡片类型（可多选）",
                    "カードタイプ（複数選択可）"
                )
            ) {
                ForEach(ReviewCardType.allCases) { type in
                    Button {
                        toggleCardType(type)
                    } label: {
                        HStack {
                            Image(
                                systemName: selectedCardTypes
                                    .contains(type)
                                    ? "checkmark.circle.fill"
                                    : "circle"
                            )
                            .foregroundStyle(AppTheme.accent)

                            Text(cardTypeLabel(type))
                                .foregroundStyle(AppTheme.ink)
                        }
                    }
                }
            }

            Section {
                NavigationLink {
                    ReviewView(
                        sourceKeys: selectedSourceKeys,
                        cardTypes: selectedCardTypeIDs,
                        sessionLimit: reviewCount
                    )
                } label: {
                    HStack {
                        Spacer()
                        Text(
                            language.text(
                                "开始复习 · \(reviewCount) 张",
                                "復習を開始 · \(reviewCount)枚"
                            )
                        )
                        .fontWeight(.semibold)
                        .foregroundStyle(AppTheme.accent)
                        Spacer()
                    }
                }
                .disabled(
                    selectedSources.isEmpty
                        || selectedCardTypes.isEmpty
                )
            } footer: {
                if selectedSources.isEmpty {
                    Text(
                        language.text(
                            "请至少选择一个学习来源。",
                            "学習ソースを1つ以上選択してください。"
                        )
                    )
                } else if selectedCardTypes.isEmpty {
                    Text(
                        language.text(
                            "请至少选择一种卡片类型。",
                            "カードタイプを1つ以上選択してください。"
                        )
                    )
                }
            }
        }
        .navigationTitle(
            language.text(
                "选择学习范围",
                "学習範囲を選択"
            )
        )
        .onAppear {
            if selectedSources.isEmpty {
                selectedSources = Set(
                    MockData.sources.map(\.id)
                )
            }
            loadSourceCounts()
        }
    }

    private func toggleSource(_ id: UUID) {
        if selectedSources.contains(id) {
            selectedSources.remove(id)
        } else {
            selectedSources.insert(id)
        }
    }

    private func toggleCardType(
        _ type: ReviewCardType
    ) {
        if selectedCardTypes.contains(type) {
            selectedCardTypes.remove(type)
        } else {
            selectedCardTypes.insert(type)
        }
    }

    private func cardTypeLabel(
        _ type: ReviewCardType
    ) -> String {
        switch type {
        case .zhToJa:
            return language.text(
                "中 → 日",
                "中 → 日"
            )
        case .jaToZh:
            return language.text(
                "日 → 中",
                "日 → 中"
            )
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

    private func loadSourceCounts() {
        do {
            let repository = LearningRepository(
                context: modelContext
            )
            try repository.seedDemoIfNeeded()
            sourceCounts = try repository
                .cardCountsBySourceKey()
        } catch {
            sourceCounts = [:]
        }
    }
}
