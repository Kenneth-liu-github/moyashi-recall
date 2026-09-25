import SwiftUI
import SwiftData

public struct StudyScopeView: View {
    @EnvironmentObject private var language: LanguageStore
    @Environment(\.modelContext) private var modelContext

    @State private var sources: [StudySource] = []
    @State private var selectedSources = Set<String>()
    @State private var selectedCardTypes = Set(
        ReviewCardType.allCases
    )
    @State private var reviewCount = 20
    @State private var filteredDueCount = 0
    @State private var presets: [SavedStudyPreset] = []
    @State private var showingSavePreset = false
    @State private var presetNameDraft = ""
    @State private var presetStatusMessage: String?

    private let preferencesStore = StudyScopePreferencesStore()
    private let presetStore = StudyPresetStore()

    public init() {}

    private var selectedSourceKeys: Set<String> {
        selectedSources
    }

    private var selectedCardTypeIDs: Set<String> {
        Set(selectedCardTypes.map(\.rawValue))
    }

    private var effectiveSessionCount: Int {
        min(reviewCount, filteredDueCount)
    }

    public var body: some View {
        List {
            if !presets.isEmpty {
                Section(
                    language.text(
                        "快速方案",
                        "クイックプリセット"
                    )
                ) {
                    ForEach(presets) { preset in
                        HStack {
                            Button {
                                applyPreset(preset)
                            } label: {
                                VStack(
                                    alignment: .leading,
                                    spacing: 3
                                ) {
                                    Text(preset.name)
                                        .foregroundStyle(AppTheme.ink)

                                    Text(
                                        language.text(
                                            "\(preset.sourceKeys.count) 个来源 · \(preset.cardTypes.count) 种卡片 · \(preset.reviewCount) 张",
                                            "\(preset.sourceKeys.count)ソース · \(preset.cardTypes.count)種類 · \(preset.reviewCount)枚"
                                        )
                                    )
                                    .font(.caption)
                                    .foregroundStyle(AppTheme.muted)
                                }
                            }
                            .buttonStyle(.plain)

                            Spacer()

                            Button(role: .destructive) {
                                deletePreset(preset)
                            } label: {
                                Image(systemName: "trash")
                            }
                            .buttonStyle(.borderless)
                        }
                    }
                }
            }

            Section {
                ForEach(sources) { source in
                    Button {
                        toggleSource(source.key)
                    } label: {
                        HStack(spacing: 12) {
                            Image(
                                systemName: selectedSources
                                    .contains(source.key)
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

                            VStack(
                                alignment: .trailing,
                                spacing: 2
                            ) {
                                Text(
                                    "\(source.dueCardCount)"
                                )
                                .font(.subheadline.bold())
                                .foregroundStyle(
                                    source.dueCardCount > 0
                                        ? AppTheme.ink
                                        : AppTheme.muted
                                )

                                Text(
                                    language.text(
                                        "到期 / 总 \(source.cardCount)",
                                        "期限 / 合計 \(source.cardCount)"
                                    )
                                )
                                .font(.caption2)
                                .foregroundStyle(AppTheme.muted)
                            }
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
                .onChange(of: reviewCount) { _, _ in
                    persistPreferences()
                }
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

            if let presetStatusMessage {
                Section {
                    Text(presetStatusMessage)
                        .font(.caption)
                        .foregroundStyle(AppTheme.muted)
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
                                effectiveSessionCount == 0
                                    ? "当前范围没有到期卡片"
                                    : "开始复习 · \(effectiveSessionCount) 张",
                                effectiveSessionCount == 0
                                    ? "現在の範囲に期限カードはありません"
                                    : "復習を開始 · \(effectiveSessionCount)枚"
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
                        || filteredDueCount == 0
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
                } else if filteredDueCount == 0 {
                    Text(
                        language.text(
                            "当前选择范围没有到期卡片。",
                            "現在選択した範囲に期限カードはありません。"
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
        .toolbar {
            ToolbarItem(
                placement: .primaryAction
            ) {
                Button {
                    presetNameDraft = ""
                    showingSavePreset = true
                } label: {
                    Image(
                        systemName: "bookmark.badge.plus"
                    )
                }
                .disabled(
                    selectedSources.isEmpty
                        || selectedCardTypes.isEmpty
                )
                .accessibilityLabel(
                    language.text(
                        "保存当前方案",
                        "現在の設定を保存"
                    )
                )
            }
        }
        .alert(
            language.text(
                "保存学习方案",
                "学習プリセットを保存"
            ),
            isPresented: $showingSavePreset
        ) {
            TextField(
                language.text(
                    "方案名称",
                    "プリセット名"
                ),
                text: $presetNameDraft
            )
            Button(
                language.text(
                    "保存",
                    "保存"
                )
            ) {
                saveCurrentPreset()
            }
            Button(
                language.text(
                    "取消",
                    "キャンセル"
                ),
                role: .cancel
            ) {}
        } message: {
            Text(
                language.text(
                    "使用同名方案时会更新原方案。",
                    "同じ名前のプリセットは更新されます。"
                )
            )
        }
        .onAppear {
            loadSources()
            loadPresets()
        }
    }

    private func toggleSource(
        _ key: String
    ) {
        if selectedSources.contains(key) {
            selectedSources.remove(key)
        } else {
            selectedSources.insert(key)
        }
        persistPreferences()
        refreshFilteredDueCount()
    }

    private func toggleCardType(
        _ type: ReviewCardType
    ) {
        if selectedCardTypes.contains(type) {
            selectedCardTypes.remove(type)
        } else {
            selectedCardTypes.insert(type)
        }
        persistPreferences()
        refreshSourceDueCounts()
        refreshFilteredDueCount()
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

    private func loadSources() {
        do {
            let repository = LearningRepository(
                context: modelContext
            )
            sources = try repository.reviewSources(
                cardTypes: selectedCardTypeIDs
            )

            let availableKeys = Set(
                sources.map(\.key)
            )

            if let saved = preferencesStore.load() {
                selectedSources = saved.sourceKeys
                    .intersection(availableKeys)

                selectedCardTypes = Set(
                    saved.cardTypes.compactMap {
                        ReviewCardType(rawValue: $0)
                    }
                )

                reviewCount = [10, 20, 30].contains(
                    saved.reviewCount
                )
                    ? saved.reviewCount
                    : 20
            } else {
                selectedSources = availableKeys
                selectedCardTypes = Set(
                    ReviewCardType.allCases
                )
                reviewCount = 20
            }

            persistPreferences()
            refreshSourceDueCounts()
            refreshFilteredDueCount()
        } catch {
            sources = []
            selectedSources = []
            filteredDueCount = 0
        }
    }

    private func loadPresets() {
        presets = presetStore.load()
    }

    private func saveCurrentPreset() {
        do {
            _ = try presetStore.save(
                name: presetNameDraft,
                sourceKeys: selectedSources,
                cardTypes: selectedCardTypeIDs,
                reviewCount: reviewCount
            )
            loadPresets()
            presetStatusMessage = language.text(
                "学习方案已保存。",
                "学習プリセットを保存しました。"
            )
        } catch StudyPresetStoreError.emptyName {
            presetStatusMessage = language.text(
                "方案名称不能为空。",
                "プリセット名を入力してください。"
            )
        } catch {
            presetStatusMessage = language.text(
                "无法保存学习方案。",
                "学習プリセットを保存できませんでした。"
            )
        }
    }

    private func applyPreset(
        _ preset: SavedStudyPreset
    ) {
        let availableKeys = Set(
            sources.map(\.key)
        )
        selectedSources = preset.sourceKeys
            .intersection(availableKeys)

        selectedCardTypes = Set(
            preset.cardTypes.compactMap {
                ReviewCardType(rawValue: $0)
            }
        )

        reviewCount = [10, 20, 30].contains(
            preset.reviewCount
        )
            ? preset.reviewCount
            : 20

        persistPreferences()
        refreshSourceDueCounts()
        refreshFilteredDueCount()

        if selectedSources.isEmpty
            || selectedCardTypes.isEmpty {
            presetStatusMessage = language.text(
                "方案“\(preset.name)”包含当前不可用的来源或卡片类型，请重新选择后保存。",
                "プリセット「\(preset.name)」には現在利用できないソースまたはカード種類が含まれています。選び直して保存してください。"
            )
        } else {
            presetStatusMessage = language.text(
                "已应用：\(preset.name)",
                "適用済み：\(preset.name)"
            )
        }
    }

    private func deletePreset(
        _ preset: SavedStudyPreset
    ) {
        do {
            try presetStore.delete(id: preset.id)
            loadPresets()
            presetStatusMessage = language.text(
                "已删除：\(preset.name)",
                "削除済み：\(preset.name)"
            )
        } catch {
            presetStatusMessage = language.text(
                "无法删除学习方案。",
                "学習プリセットを削除できませんでした。"
            )
        }
    }

    private func persistPreferences() {
        do {
            try preferencesStore.save(
                StudyScopePreferences(
                    sourceKeys: selectedSources,
                    cardTypes: selectedCardTypeIDs,
                    reviewCount: reviewCount
                )
            )
        } catch {
            // Preferences are non-critical; the review flow can continue.
        }
    }

    private func refreshSourceDueCounts() {
        do {
            let repository = LearningRepository(
                context: modelContext
            )
            sources = try repository.reviewSources(
                cardTypes: selectedCardTypeIDs
            )
        } catch {
            // Keep the last known source list if only the count refresh fails.
        }
    }

    private func refreshFilteredDueCount() {
        guard !selectedSources.isEmpty,
              !selectedCardTypes.isEmpty
        else {
            filteredDueCount = 0
            return
        }

        do {
            let repository = LearningRepository(
                context: modelContext
            )
            filteredDueCount = try repository.dueCardCount(
                sourceKeys: selectedSourceKeys,
                cardTypes: selectedCardTypeIDs
            )
        } catch {
            filteredDueCount = 0
        }
    }
}
