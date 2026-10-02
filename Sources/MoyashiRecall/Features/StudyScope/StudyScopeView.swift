import SwiftUI
import SwiftData

public struct StudyScopeView: View {
    @EnvironmentObject private var language: LanguageStore
    @Environment(\.modelContext) private var modelContext

    // All currently active learning materials.
    // Includes materials with zero generated cards.
    @State private var materials: [StudyDocument] = []

    // Actual card groups used by ReviewView.
    @State private var selectedDocumentIDs = Set<UUID>()

    // Temporary selection in "资料范围".
    // Only committed after pressing "添加到复习卡片中".
    @State private var stagedMaterialIDs = Set<UUID>()

    @State private var selectedCardTypes = Set(
        ReviewCardType.allCases
    )

    @State private var reviewCount = 20
    @State private var filteredDueCount = 0

    @State private var presets: [SavedStudyPreset] = []
    @State private var showingSavePreset = false
    @State private var presetNameDraft = ""
    @State private var presetStatusMessage: String?

    private let preferencesStore =
        StudyScopePreferencesStore()

    private let presetStore =
        StudyPresetStore()

    public init() {}

    // MARK: - Derived state

    private var selectedCardTypeIDs: Set<String> {
        Set(
            selectedCardTypes.map(\.rawValue)
        )
    }

    private var eligibleMaterialIDs: Set<UUID> {
        Set(
            materials
                .filter { $0.cardCount > 0 }
                .map(\.id)
        )
    }

    private var stagedEligibleIDs: Set<UUID> {
        stagedMaterialIDs
            .intersection(
                eligibleMaterialIDs
            )
    }

    private var selectedReviewDocuments: [StudyDocument] {
        materials.filter {
            selectedDocumentIDs.contains(
                $0.id
            )
        }
    }

    private var selectedSourceKeys: Set<String> {
        Set(
            selectedReviewDocuments
                .map(\.sourceKey)
                .filter { !$0.isEmpty }
        )
    }

    private var effectiveSessionCount: Int {
        reviewCount == 0
            ? filteredDueCount
            : min(
                reviewCount,
                filteredDueCount
            )
    }

    // MARK: - Body

    public var body: some View {
        List {
            quickPresetSection

            reviewCardsSection

            materialsSection

            reviewCountSection

            cardTypeSection

            if let presetStatusMessage {
                Section {
                    Text(presetStatusMessage)
                        .font(.caption)
                        .foregroundStyle(
                            AppTheme.muted
                        )
                }
            }

            startReviewSection
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
                        systemName:
                            "bookmark.badge.plus"
                    )
                }
                .disabled(
                    selectedDocumentIDs.isEmpty
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
            isPresented:
                $showingSavePreset
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
            // Important:
            // Re-read the repository every time this page appears.
            // This means materials that received AI-generated cards
            // since the previous visit become selectable immediately.
            loadStudyScope()
            loadPresets()
        }
    }

    // MARK: - Quick presets

    @ViewBuilder
    private var quickPresetSection: some View {
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
                                    .foregroundStyle(
                                        AppTheme.ink
                                    )

                                Text(
                                    language.text(
                                        "\(presetDocumentLabel(preset)) · \(preset.cardTypes.count) 种卡片 · \(presetCountLabel(preset.reviewCount))",
                                        "\(presetDocumentLabel(preset)) · \(preset.cardTypes.count)種類 · \(presetCountLabel(preset.reviewCount))"
                                    )
                                )
                                .font(.caption)
                                .foregroundStyle(
                                    AppTheme.muted
                                )
                            }
                        }
                        .buttonStyle(.plain)

                        Spacer()

                        Button(
                            role: .destructive
                        ) {
                            deletePreset(preset)
                        } label: {
                            Image(
                                systemName: "trash"
                            )
                        }
                        .buttonStyle(.borderless)
                    }
                }
            }
        }
    }

    // MARK: - Section 1: Review card groups

    private var reviewCardsSection: some View {
        Section {
            if selectedReviewDocuments.isEmpty {
                Text(
                    language.text(
                        "尚未添加复习卡片。请从下面的资料范围中选择已生成卡片的资料，然后添加。",
                        "復習カードがまだ追加されていません。下の資料範囲からカード生成済みの資料を選択して追加してください。"
                    )
                )
                .font(.subheadline)
                .foregroundStyle(
                    AppTheme.muted
                )
            } else {
                ForEach(
                    selectedReviewDocuments
                ) { document in
                    Button {
                        removeReviewDocument(
                            document.id
                        )
                    } label: {
                        HStack(spacing: 12) {
                            Image(
                                systemName:
                                    "checkmark.circle.fill"
                            )
                            .foregroundStyle(
                                AppTheme.accent
                            )

                            VStack(
                                alignment: .leading,
                                spacing: 3
                            ) {
                                Text(document.title)
                                    .foregroundStyle(
                                        AppTheme.ink
                                    )

                                Text(document.path)
                                    .font(.caption)
                                    .foregroundStyle(
                                        AppTheme.muted
                                    )
                                    .lineLimit(2)
                            }

                            Spacer()

                            VStack(
                                alignment: .trailing,
                                spacing: 2
                            ) {
                                Text(
                                    "\(document.dueCardCount)"
                                )
                                .font(
                                    .subheadline.bold()
                                )
                                .foregroundStyle(
                                    document
                                        .dueCardCount > 0
                                    ? AppTheme.ink
                                    : AppTheme.muted
                                )

                                Text(
                                    language.text(
                                        "到期 / 总 \(document.cardCount)",
                                        "期限 / 合計 \(document.cardCount)"
                                    )
                                )
                                .font(.caption2)
                                .foregroundStyle(
                                    AppTheme.muted
                                )
                            }
                        }
                    }
                }
            }
        } header: {
            Text(
                language.text(
                    "复习卡片（可多选）",
                    "復習カード（複数選択可）"
                )
            )
        } footer: {
            Text(
                language.text(
                    "开始复习时，只会从这里列出的卡片组中抽取卡片。点击已添加的项目可以将其移除。",
                    "復習開始時は、ここに表示されたカードグループからのみカードを抽出します。追加済み項目をタップすると削除できます。"
                )
            )
        }
    }

    private var notionMaterials: [StudyDocument] {
        materials.filter {
            $0.sourceKind == "notion"
        }
    }

    private var localMaterials: [StudyDocument] {
        materials.filter {
            $0.sourceKind == "file"
        }
    }

    private var otherMaterials: [StudyDocument] {
        materials.filter {
            $0.sourceKind != "notion"
                && $0.sourceKind != "file"
        }
    }

    // MARK: - Section 2: Material pool

    private var materialsSection: some View {
        Section {
            HStack {
                Button(
                    language.text(
                        "全选可添加",
                        "追加可能をすべて選択"
                    )
                ) {
                    stagedMaterialIDs =
                        eligibleMaterialIDs
                }

                Spacer()

                Button(
                    language.text(
                        "清空",
                        "選択解除"
                    )
                ) {
                    stagedMaterialIDs = []
                }
            }
            .font(.caption)

            if materials.isEmpty {
                Text(
                    language.text(
                        "资料库中还没有可显示的学习资料。",
                        "ライブラリに表示できる学習資料がありません。"
                    )
                )
                .foregroundStyle(
                    AppTheme.muted
                )
            } else {
                if !notionMaterials.isEmpty {
                    materialGroupHeader(
                        language.text(
                            "Notion",
                            "Notion"
                        ),
                        systemImage: "n.square"
                    )

                    ForEach(
                        notionMaterials
                    ) { document in
                        materialRow(document)
                    }
                }

                if !localMaterials.isEmpty {
                    materialGroupHeader(
                        language.text(
                            "本地资料",
                            "ローカル資料"
                        ),
                        systemImage: "doc"
                    )

                    ForEach(
                        localMaterials
                    ) { document in
                        materialRow(document)
                    }
                }

                if !otherMaterials.isEmpty {
                    materialGroupHeader(
                        language.text(
                            "其他资料",
                            "その他の資料"
                        ),
                        systemImage: "folder"
                    )

                    ForEach(
                        otherMaterials
                    ) { document in
                        materialRow(document)
                    }
                }
            }

            Button {
                addSelectedMaterialsToReviewCards()
            } label: {
                HStack {
                    Spacer()

                    Label(
                        language.text(
                            stagedEligibleIDs.isEmpty
                                ? "添加到复习卡片中"
                                : "添加到复习卡片中 · \(stagedEligibleIDs.count) 项",
                            stagedEligibleIDs.isEmpty
                                ? "復習カードに追加"
                                : "復習カードに追加 · \(stagedEligibleIDs.count)件"
                        ),
                        systemImage:
                            "plus.circle.fill"
                    )
                    .fontWeight(.semibold)

                    Spacer()
                }
            }
            .disabled(
                stagedEligibleIDs.isEmpty
            )
        } header: {
            Text(
                language.text(
                    "资料范围（可多选）",
                    "資料範囲（複数選択可）"
                )
            )
        } footer: {
            Text(
                language.text(
                    "只有已经由 AI 生成过有效复习卡片的资料可以选择。尚未生成卡片的资料会显示为灰色，需先到资料库生成卡片。",
                    "AIで有効な復習カードが生成済みの資料だけ選択できます。未生成の資料はグレー表示され、先にライブラリでカード生成が必要です。"
                )
            )
        }
    }

    private func materialGroupHeader(
        _ title: String,
        systemImage: String
    ) -> some View {
        HStack(spacing: 7) {
            Image(
                systemName: systemImage
            )
            .foregroundStyle(
                AppTheme.accent
            )

            Text(title)
                .font(
                    .subheadline
                        .weight(.semibold)
                )

            Spacer()
        }
        .padding(.top, 8)
        .padding(.bottom, 2)
    }

    @ViewBuilder
    private func materialRow(
        _ document: StudyDocument
    ) -> some View {
        let eligible =
            document.cardCount > 0

        Button {
            guard eligible else {
                return
            }

            toggleStagedMaterial(
                document.id
            )
        } label: {
            HStack(spacing: 12) {
                Image(
                    systemName:
                        eligible
                        ? (
                            stagedMaterialIDs
                                .contains(
                                    document.id
                                )
                            ? "checkmark.circle.fill"
                            : "circle"
                        )
                        : "minus.circle"
                )
                .foregroundStyle(
                    eligible
                    ? AppTheme.accent
                    : AppTheme.muted
                )

                VStack(
                    alignment: .leading,
                    spacing: 3
                ) {
                    Text(document.title)
                        .foregroundStyle(
                            eligible
                            ? AppTheme.ink
                            : AppTheme.muted
                        )

                    Text(document.path)
                        .font(.caption)
                        .foregroundStyle(
                            AppTheme.muted
                        )
                        .lineLimit(2)
                }

                Spacer()

                if eligible {
                    VStack(
                        alignment: .trailing,
                        spacing: 2
                    ) {
                        Text(
                            "\(document.dueCardCount)"
                        )
                        .font(
                            .subheadline.bold()
                        )
                        .foregroundStyle(
                            document
                                .dueCardCount > 0
                            ? AppTheme.ink
                            : AppTheme.muted
                        )

                        Text(
                            language.text(
                                "到期 / 总 \(document.cardCount)",
                                "期限 / 合計 \(document.cardCount)"
                            )
                        )
                        .font(.caption2)
                        .foregroundStyle(
                            AppTheme.muted
                        )
                    }
                } else {
                    Text(
                        language.text(
                            "尚未生成卡片",
                            "カード未生成"
                        )
                    )
                    .font(.caption)
                    .foregroundStyle(
                        AppTheme.muted
                    )
                }
            }
        }
        .disabled(!eligible)
        .opacity(
            eligible ? 1.0 : 0.48
        )
    }

    // MARK: - Review count

    private var reviewCountSection: some View {
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

                Text(
                    language.text(
                        "全部",
                        "すべて"
                    )
                )
                .tag(0)
            }
            .pickerStyle(.segmented)
            .onChange(
                of: reviewCount
            ) { _, _ in
                persistPreferences()
            }
        }
    }

    // MARK: - Card types

    private var cardTypeSection: some View {
        Section(
            language.text(
                "卡片类型（可多选）",
                "カードタイプ（複数選択可）"
            )
        ) {
            ForEach(
                ReviewCardType.allCases
            ) { type in
                Button {
                    toggleCardType(type)
                } label: {
                    HStack {
                        Image(
                            systemName:
                                selectedCardTypes
                                    .contains(type)
                                ? "checkmark.circle.fill"
                                : "circle"
                        )
                        .foregroundStyle(
                            AppTheme.accent
                        )

                        Text(
                            cardTypeLabel(type)
                        )
                        .foregroundStyle(
                            AppTheme.ink
                        )
                    }
                }
            }
        }
    }

    // MARK: - Start review

    private var startReviewSection: some View {
        Section {
            NavigationLink {
                ReviewView(
                    sourceKeys:
                        selectedSourceKeys,
                    cardTypes:
                        selectedCardTypeIDs,
                    sourceDocumentIDs:
                        selectedDocumentIDs,
                    sessionLimit:
                        reviewCount
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
                    .foregroundStyle(
                        AppTheme.accent
                    )

                    Spacer()
                }
            }
            .disabled(
                selectedDocumentIDs.isEmpty
                || selectedCardTypes.isEmpty
                || filteredDueCount == 0
            )
        } footer: {
            if selectedDocumentIDs.isEmpty {
                Text(
                    language.text(
                        "请先从资料范围中添加至少一个复习卡片组。",
                        "資料範囲から復習カードグループを1つ以上追加してください。"
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
                        "当前复习卡片范围没有到期卡片。",
                        "現在の復習カード範囲に期限カードはありません。"
                    )
                )
            }
        }
    }

    // MARK: - Material selection

    private func toggleStagedMaterial(
        _ id: UUID
    ) {
        guard
            eligibleMaterialIDs
                .contains(id)
        else {
            return
        }

        if stagedMaterialIDs.contains(id) {
            stagedMaterialIDs.remove(id)
        } else {
            stagedMaterialIDs.insert(id)
        }
    }

    private func addSelectedMaterialsToReviewCards() {
        selectedDocumentIDs.formUnion(
            stagedEligibleIDs
        )

        stagedMaterialIDs = []

        persistPreferences()
        refreshFilteredDueCount()

        presetStatusMessage =
            language.text(
                "已添加到复习卡片。",
                "復習カードに追加しました。"
            )
    }

    private func removeReviewDocument(
        _ id: UUID
    ) {
        selectedDocumentIDs.remove(id)

        persistPreferences()
        refreshFilteredDueCount()
    }

    // MARK: - Card types

    private func toggleCardType(
        _ type: ReviewCardType
    ) {
        if selectedCardTypes.contains(type) {
            selectedCardTypes.remove(type)
        } else {
            selectedCardTypes.insert(type)
        }

        refreshMaterialsPreservingSelection()

        persistPreferences()
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

    // MARK: - Load / refresh

    private func loadStudyScope() {
        do {
            let saved =
                preferencesStore.load()

            if let saved {
                selectedCardTypes = Set(
                    saved.cardTypes.compactMap {
                        ReviewCardType(
                            rawValue: $0
                        )
                    }
                )

                reviewCount =
                    [0, 10, 20, 30]
                        .contains(
                            saved.reviewCount
                        )
                    ? saved.reviewCount
                    : 20
            } else {
                selectedCardTypes = Set(
                    ReviewCardType.allCases
                )
                reviewCount = 20
            }

            let repository =
                LearningRepository(
                    context: modelContext
                )

            // This is the key AI-status check.
            // studyMaterials() returns ALL active documents,
            // with cardCount == 0 when no active generated cards exist.
            materials =
                try repository.studyMaterials(
                    cardTypes:
                        selectedCardTypeIDs
                )

            let eligibleIDs =
                eligibleMaterialIDs

            if let saved {
                if let savedDocumentIDs =
                    saved.documentIDs {
                    selectedDocumentIDs =
                        savedDocumentIDs
                            .intersection(
                                eligibleIDs
                            )
                } else {
                    // Backward compatibility for old preferences
                    // that stored only source keys.
                    selectedDocumentIDs = Set(
                        materials
                            .filter {
                                eligibleIDs
                                    .contains(
                                        $0.id
                                    )
                                && saved.sourceKeys
                                    .contains(
                                        $0.sourceKey
                                    )
                            }
                            .map(\.id)
                    )
                }
            } else {
                // New configuration starts empty.
                // User explicitly adds material card groups.
                selectedDocumentIDs = []
            }

            stagedMaterialIDs = []

            persistPreferences()
            refreshFilteredDueCount()
        } catch {
            materials = []
            selectedDocumentIDs = []
            stagedMaterialIDs = []
            filteredDueCount = 0
        }
    }

    private func refreshMaterialsPreservingSelection() {
        do {
            let repository =
                LearningRepository(
                    context: modelContext
                )

            materials =
                try repository.studyMaterials(
                    cardTypes:
                        selectedCardTypeIDs
                )

            // A review group must still have active cards.
            selectedDocumentIDs
                .formIntersection(
                    eligibleMaterialIDs
                )

            stagedMaterialIDs
                .formIntersection(
                    eligibleMaterialIDs
                )
        } catch {
            // Keep last known list if refresh fails.
        }
    }

    // MARK: - Review count

    private func refreshFilteredDueCount() {
        guard
            !selectedDocumentIDs.isEmpty,
            !selectedCardTypes.isEmpty
        else {
            filteredDueCount = 0
            return
        }

        do {
            let repository =
                LearningRepository(
                    context: modelContext
                )

            filteredDueCount =
                try repository.dueCardCount(
                    sourceKeys:
                        selectedSourceKeys,
                    cardTypes:
                        selectedCardTypeIDs,
                    sourceDocumentIDs:
                        selectedDocumentIDs
                )
        } catch {
            filteredDueCount = 0
        }
    }

    // MARK: - Preferences

    private func persistPreferences() {
        do {
            try preferencesStore.save(
                StudyScopePreferences(
                    sourceKeys:
                        selectedSourceKeys,
                    cardTypes:
                        selectedCardTypeIDs,
                    documentIDs:
                        selectedDocumentIDs,
                    reviewCount:
                        reviewCount
                )
            )
        } catch {
            // Non-critical preference persistence.
        }
    }

    // MARK: - Presets

    private func loadPresets() {
        presets = presetStore.load()
    }

    private func saveCurrentPreset() {
        do {
            _ = try presetStore.save(
                name: presetNameDraft,
                sourceKeys:
                    selectedSourceKeys,
                cardTypes:
                    selectedCardTypeIDs,
                documentIDs:
                    selectedDocumentIDs,
                reviewCount:
                    reviewCount
            )

            loadPresets()

            presetStatusMessage =
                language.text(
                    "学习方案已保存。",
                    "学習プリセットを保存しました。"
                )
        } catch StudyPresetStoreError.emptyName {
            presetStatusMessage =
                language.text(
                    "方案名称不能为空。",
                    "プリセット名を入力してください。"
                )
        } catch {
            presetStatusMessage =
                language.text(
                    "无法保存学习方案。",
                    "学習プリセットを保存できませんでした。"
                )
        }
    }

    private func applyPreset(
        _ preset: SavedStudyPreset
    ) {
        selectedCardTypes = Set(
            preset.cardTypes.compactMap {
                ReviewCardType(
                    rawValue: $0
                )
            }
        )

        reviewCount =
            [0, 10, 20, 30]
                .contains(
                    preset.reviewCount
                )
            ? preset.reviewCount
            : 20

        refreshMaterialsPreservingSelection()

        if let documentIDs =
            preset.documentIDs {
            selectedDocumentIDs =
                documentIDs
                    .intersection(
                        eligibleMaterialIDs
                    )
        } else {
            // Legacy preset:
            // select all card-bearing documents
            // from its old source-key scope.
            selectedDocumentIDs = Set(
                materials
                    .filter {
                        $0.cardCount > 0
                        && preset.sourceKeys
                            .contains(
                                $0.sourceKey
                            )
                    }
                    .map(\.id)
            )
        }

        stagedMaterialIDs = []

        persistPreferences()
        refreshFilteredDueCount()

        if selectedDocumentIDs.isEmpty
            || selectedCardTypes.isEmpty {
            presetStatusMessage =
                language.text(
                    "方案“\(preset.name)”中的资料当前没有可用的复习卡片，请重新选择后保存。",
                    "プリセット「\(preset.name)」の資料には現在利用可能な復習カードがありません。選び直して保存してください。"
                )
        } else {
            presetStatusMessage =
                language.text(
                    "已应用：\(preset.name)",
                    "適用済み：\(preset.name)"
                )
        }
    }

    private func deletePreset(
        _ preset: SavedStudyPreset
    ) {
        do {
            try presetStore.delete(
                id: preset.id
            )

            loadPresets()

            presetStatusMessage =
                language.text(
                    "已删除：\(preset.name)",
                    "削除済み：\(preset.name)"
                )
        } catch {
            presetStatusMessage =
                language.text(
                    "无法删除学习方案。",
                    "学習プリセットを削除できませんでした。"
                )
        }
    }

    private func presetDocumentLabel(
        _ preset: SavedStudyPreset
    ) -> String {
        guard let ids =
            preset.documentIDs
        else {
            return language.text(
                "全部卡片组",
                "全カードグループ"
            )
        }

        return language.text(
            "\(ids.count) 个卡片组",
            "\(ids.count)カードグループ"
        )
    }

    private func presetCountLabel(
        _ count: Int
    ) -> String {
        count == 0
            ? language.text(
                "全部到期",
                "期限分すべて"
            )
            : language.text(
                "\(count) 张",
                "\(count)枚"
            )
    }
}
