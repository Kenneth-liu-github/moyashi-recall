import SwiftUI
import SwiftData
import UniformTypeIdentifiers

public struct LibraryView: View {
    @EnvironmentObject private var language: LanguageStore
    @Environment(\.modelContext) private var modelContext

    @State private var reviewSources: [StudySource] = []
    @State private var importedItems: [ImportedDocumentSummary] = []
    @State private var loadError: String?
    @State private var showingFileImporter = false
    @State private var isImportingFiles = false
    @State private var importStatusMessage: String?
    @State private var pendingArchiveItem: ImportedDocumentSummary?
    @State private var pendingDeleteItem: ImportedDocumentSummary?

    // Multi-select deletion is deliberately LOCAL-ONLY.
    // Notion is treated as a read-only external source.
    @State private var isLocalMultiSelectMode = false
    @State private var selectedLocalRootIDs = Set<UUID>()
    @State private var showingBulkDeleteConfirmation = false

    @State private var searchText = ""
    @State private var aiStatusFilter:
        LibraryAIStatusFilter = .all
    @State private var generatedCardCounts: [UUID: Int] = [:]

    public init() {}

    private var localItems: [ImportedDocumentSummary] {
        importedItems.filter {
            $0.sourceKind == "file"
                && matchesLibraryFilters($0)
        }
    }

    private var selectedLocalRootItems:
        [ImportedDocumentSummary]
    {
        importedItems.filter {
            $0.sourceKind == "file"
                && $0.hierarchyDepth == 0
                && selectedLocalRootIDs.contains(
                    $0.id
                )
        }
    }

    private var notionItems: [ImportedDocumentSummary] {
        importedItems.filter {
            $0.sourceKind == "notion"
                && matchesLibraryFilters($0)
        }
    }

    private func generatedCardCount(
        for item: ImportedDocumentSummary
    ) -> Int {
        generatedCardCounts[
            item.id,
            default: 0
        ]
    }

    private func hasGeneratedCards(
        _ item: ImportedDocumentSummary
    ) -> Bool {
        generatedCardCount(
            for: item
        ) > 0
    }

    private func matchesLibraryFilters(
        _ item: ImportedDocumentSummary
    ) -> Bool {
        let normalized =
            searchText
                .trimmingCharacters(
                    in: .whitespacesAndNewlines
                )

        if !normalized.isEmpty {
            let matchesSearch =
                item.title
                    .localizedCaseInsensitiveContains(
                        normalized
                    )
                || item.sourcePath
                    .localizedCaseInsensitiveContains(
                        normalized
                    )
                || item.content
                    .localizedCaseInsensitiveContains(
                        normalized
                    )

            if !matchesSearch {
                return false
            }
        }

        switch aiStatusFilter {
        case .all:
            return true

        case .generated:
            return hasGeneratedCards(item)

        case .pending:
            return item.canGenerateAI
                && !hasGeneratedCards(item)
        }
    }

    public var body: some View {
        NavigationStack {
            Group {
                if let loadError {
                    ContentUnavailableView(
                        language.text(
                            "无法读取资料库",
                            "ライブラリを読み込めません"
                        ),
                        systemImage: "exclamationmark.triangle",
                        description: Text(loadError)
                    )
                } else {
                    List {
                        if let importStatusMessage {
                            Section {
                                HStack(spacing: 10) {
                                    if isImportingFiles {
                                        ProgressView()
                                    }
                                    Text(importStatusMessage)
                                        .font(.caption)
                                        .foregroundStyle(AppTheme.muted)
                                }
                            }
                        }

                        Section {
                            Picker(
                                language.text(
                                    "AI 状态",
                                    "AI状態"
                                ),
                                selection: $aiStatusFilter
                            ) {
                                Text(
                                    language.text(
                                        "全部",
                                        "すべて"
                                    )
                                )
                                .tag(
                                    LibraryAIStatusFilter.all
                                )

                                Text(
                                    language.text(
                                        "已生成卡片",
                                        "カード生成済み"
                                    )
                                )
                                .tag(
                                    LibraryAIStatusFilter.generated
                                )

                                Text(
                                    language.text(
                                        "待生成卡片",
                                        "カード未生成"
                                    )
                                )
                                .tag(
                                    LibraryAIStatusFilter.pending
                                )
                            }
                            .pickerStyle(.segmented)
                        }

                        Section(
                            language.text(
                                "Notion",
                                "Notion"
                            )
                        ) {
                            NavigationLink {
                                NotionConnectionView()
                            } label: {
                                Label(
                                    language.text(
                                        "管理 / 同步 Notion",
                                        "Notionを管理・同期"
                                    ),
                                    systemImage: "arrow.triangle.2.circlepath"
                                )
                                .fontWeight(.semibold)
                                .foregroundStyle(AppTheme.accent)
                            }

                            Label(
                                language.text(
                                    "只读来源 · 不会修改或删除 Notion 原始页面",
                                    "読み取り専用 · Notionの元ページは変更・削除しません"
                                ),
                                systemImage: "lock.fill"
                            )
                            .font(.caption)
                            .foregroundStyle(AppTheme.muted)

                            if notionItems.isEmpty {
                                Text(
                                    language.text(
                                        "尚未同步 Notion 学习资料。",
                                        "Notionの学習資料はまだ同期されていません。"
                                    )
                                )
                                .font(.caption)
                                .foregroundStyle(AppTheme.muted)
                            } else {
                                ForEach(notionItems) { item in
                                    NavigationLink {
                                        ImportedPageDetailView(
                                            item: item
                                        )
                                    } label: {
                                        importedRow(item)
                                    }
                                }
                            }
                        }

                        Section(
                            language.text(
                                "本地文档",
                                "ローカル文書"
                            )
                        ) {
                            HStack {
                                Button {
                                    showingFileImporter = true
                                } label: {
                                    Label(
                                        language.text(
                                            "导入本地学习资料",
                                            "ローカル学習資料を読み込む"
                                        ),
                                        systemImage:
                                            "square.and.arrow.down"
                                    )
                                    .fontWeight(.semibold)
                                    .foregroundStyle(
                                        AppTheme.accent
                                    )
                                }
                                .disabled(
                                    isLocalMultiSelectMode
                                )

                                Spacer()

                                Button {
                                    if isLocalMultiSelectMode {
                                        selectedLocalRootIDs.removeAll()
                                        isLocalMultiSelectMode = false
                                    } else {
                                        selectedLocalRootIDs.removeAll()
                                        isLocalMultiSelectMode = true
                                    }
                                } label: {
                                    Label(
                                        language.text(
                                            isLocalMultiSelectMode
                                                ? "完成"
                                                : "多选",
                                            isLocalMultiSelectMode
                                                ? "完了"
                                                : "複数選択"
                                        ),
                                        systemImage:
                                            isLocalMultiSelectMode
                                                ? "checkmark"
                                                : "checklist"
                                    )
                                }
                            }

                            if localItems.isEmpty {
                                Text(
                                    language.text(
                                        "尚未导入本地文档。",
                                        "ローカル文書はまだありません。"
                                    )
                                )
                                .font(.caption)
                                .foregroundStyle(AppTheme.muted)
                            } else {
                                ForEach(localItems) { item in
                                    if isLocalMultiSelectMode {
                                        if item.hierarchyDepth == 0 {
                                            Button {
                                                toggleLocalSelection(
                                                    item.id
                                                )
                                            } label: {
                                                HStack(spacing: 10) {
                                                    Image(
                                                        systemName:
                                                            selectedLocalRootIDs
                                                                .contains(
                                                                    item.id
                                                                )
                                                            ? "checkmark.circle.fill"
                                                            : "circle"
                                                    )
                                                    .foregroundStyle(
                                                        AppTheme.accent
                                                    )

                                                    importedRow(item)
                                                }
                                                .contentShape(
                                                    Rectangle()
                                                )
                                            }
                                            .buttonStyle(.plain)
                                        } else {
                                            // Child pages are intentionally
                                            // not individually deletable.
                                            importedRow(item)
                                                .opacity(0.38)
                                        }
                                    } else {
                                        NavigationLink {
                                            ImportedPageDetailView(
                                                item: item
                                            )
                                        } label: {
                                            importedRow(item)
                                        }
                                        .swipeActions {
                                            if item.hierarchyDepth == 0 {
                                                Button {
                                                    pendingArchiveItem = item
                                                } label: {
                                                    Label(
                                                        language.text(
                                                            "归档",
                                                            "アーカイブ"
                                                        ),
                                                        systemImage:
                                                            "archivebox"
                                                    )
                                                }
                                                .tint(.orange)

                                                Button(
                                                    role: .destructive
                                                ) {
                                                    pendingDeleteItem = item
                                                } label: {
                                                    Label(
                                                        language.text(
                                                            "删除",
                                                            "削除"
                                                        ),
                                                        systemImage:
                                                            "trash"
                                                    )
                                                }
                                            }
                                        }
                                    }
                                }

                                if isLocalMultiSelectMode {
                                    Button(
                                        role: .destructive
                                    ) {
                                        showingBulkDeleteConfirmation = true
                                    } label: {
                                        Label(
                                            language.text(
                                                selectedLocalRootIDs.isEmpty
                                                    ? "删除已选资料"
                                                    : "删除已选资料 · \(selectedLocalRootIDs.count)",
                                                selectedLocalRootIDs.isEmpty
                                                    ? "選択資料を削除"
                                                    : "選択資料を削除 · \(selectedLocalRootIDs.count)"
                                            ),
                                            systemImage: "trash"
                                        )
                                        .frame(
                                            maxWidth: .infinity
                                        )
                                    }
                                    .disabled(
                                        selectedLocalRootIDs.isEmpty
                                    )
                                }
                            }
                        }

                        Section(
                            language.text(
                                "复习卡片来源",
                                "復習カードのソース"
                            )
                        ) {
                            ForEach(reviewSources) { source in
                                VStack(
                                    alignment: .leading,
                                    spacing: 4
                                ) {
                                    Text(source.title)
                                    Text(
                                        source.detail
                                            + " · "
                                            + "\(source.cardCount)"
                                    )
                                    .font(.caption)
                                    .foregroundStyle(AppTheme.muted)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle(
                language.text(
                    "资料库",
                    "ライブラリ"
                )
            )
            .searchable(
                text: $searchText,
                prompt: language.text(
                    "搜索标题、路径或正文",
                    "タイトル・パス・本文を検索"
                )
            )
            .toolbar {
                ToolbarItem(
                    placement: .primaryAction
                ) {
                    Button {
                        showingFileImporter = true
                    } label: {
                        Image(
                            systemName: "square.and.arrow.down"
                        )
                    }
                    .disabled(isImportingFiles)
                    .accessibilityLabel(
                        language.text(
                            "导入文件",
                            "ファイルを読み込む"
                        )
                    )
                }
            }
            .confirmationDialog(
                language.text(
                    "归档此文件？",
                    "このファイルをアーカイブしますか？"
                ),
                isPresented: Binding(
                    get: {
                        pendingArchiveItem != nil
                    },
                    set: { presented in
                        if !presented {
                            pendingArchiveItem = nil
                        }
                    }
                ),
                presenting: pendingArchiveItem
            ) { item in
                Button(
                    language.text(
                        "归档 \(item.title)",
                        "\(item.title) をアーカイブ"
                    ),
                    role: .destructive
                ) {
                    archiveFileSource(item)
                    pendingArchiveItem = nil
                }

                Button(
                    language.text(
                        "取消",
                        "キャンセル"
                    ),
                    role: .cancel
                ) {
                    pendingArchiveItem = nil
                }
            } message: { _ in
                Text(
                    language.text(
                        "资料及其生成卡片会从当前学习范围中停用，但复习历史会保留。",
                        "資料と生成カードは現在の学習対象から外れますが、復習履歴は保持されます。"
                    )
                )
            }
            .confirmationDialog(
                language.text(
                    "永久删除此资料？",
                    "この資料を完全に削除しますか？"
                ),
                isPresented: Binding(
                    get: {
                        pendingDeleteItem != nil
                    },
                    set: { presented in
                        if !presented {
                            pendingDeleteItem = nil
                        }
                    }
                ),
                presenting: pendingDeleteItem
            ) { item in
                Button(
                    language.text(
                        "永久删除 \(item.title)",
                        "\(item.title) を完全に削除"
                    ),
                    role: .destructive
                ) {
                    deleteFileSource(item)
                    pendingDeleteItem = nil
                }

                Button(
                    language.text(
                        "取消",
                        "キャンセル"
                    ),
                    role: .cancel
                ) {
                    pendingDeleteItem = nil
                }
            } message: { _ in
                Text(
                    language.text(
                        "这会从 Moyashi Recall 中永久删除该资料、AI 知识点、卡片及相关复习记录。原始 Word、PDF 或其他源文件不会被删除。此操作无法撤销。",
                        "Moyashi Recall 内の資料、AI知識、カード、および関連する復習履歴を完全に削除します。元の Word、PDF その他のファイルは削除されません。この操作は取り消せません。"
                    )
                )
            }

            .confirmationDialog(
                language.text(
                    "永久删除所选本地资料？",
                    "選択したローカル資料を完全に削除しますか？"
                ),
                isPresented:
                    $showingBulkDeleteConfirmation
            ) {
                Button(
                    language.text(
                        "永久删除 \(selectedLocalRootIDs.count) 项",
                        "\(selectedLocalRootIDs.count)件を完全に削除"
                    ),
                    role: .destructive
                ) {
                    bulkDeleteSelectedLocalSources()
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
                        "只会删除 Moyashi Recall 中所选本地资料及其 AI 知识、卡片和相关复习记录。不会删除 Mac 上的原始 Word、PDF 或其他源文件。Notion 资料不参与此操作。",
                        "Moyashi Recall内の選択したローカル資料、AI知識、カード、関連する復習履歴だけを削除します。Mac上の元のWord、PDF等は削除しません。Notion資料は対象外です。"
                    )
                )
            }

            .fileImporter(
                isPresented: $showingFileImporter,
                allowedContentTypes: supportedFileTypes,
                allowsMultipleSelection: true
            ) { result in
                switch result {
                case let .success(urls):
                    Task {
                        await importFiles(urls)
                    }

                case let .failure(error):
                    importStatusMessage = language.text(
                        "无法打开文件：\(error.localizedDescription)",
                        "ファイルを開けません：\(error.localizedDescription)"
                    )
                }
            }
            .onAppear {
                loadLibrary()
            }
        }
    }

    private var supportedFileTypes: [UTType] {
        var types: [UTType] = [
            .pdf,
            .plainText,
            .commaSeparatedText,
            .image
        ]

        for ext in [
            "md",
            "docx",
            "doc",
            "rtf",
            "odt",
            "tsv"
        ] {
            if let type = UTType(
                filenameExtension: ext
            ) {
                types.append(type)
            }
        }

        return Array(Set(types))
    }

    private func importedRow(
        _ item: ImportedDocumentSummary
    ) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Color.clear
                .frame(
                    width: CGFloat(
                        min(item.hierarchyDepth, 6) * 14
                    ),
                    height: 1
                )

            Image(
                systemName: sourceIcon(
                    item.sourceKind,
                    depth: item.hierarchyDepth
                )
            )
            .foregroundStyle(AppTheme.accent)
            .frame(width: 20)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(item.title)
                        .fontWeight(
                            hasGeneratedCards(item)
                                ? .semibold
                                : .regular
                        )

                    if hasGeneratedCards(item) {
                        Spacer()

                        Label(
                            "\(generatedCardCount(for: item))",
                            systemImage:
                                "rectangle.stack.fill"
                        )
                        .font(.caption2)
                        .foregroundStyle(
                            AppTheme.accent
                        )
                    }
                }

                Text(item.sourcePath)
                    .font(.caption)
                    .foregroundStyle(AppTheme.muted)
                    .lineLimit(2)

                Label(
                    !item.canGenerateAI
                        ? language.text(
                            "文档容器 · 请打开子页面",
                            "文書コンテナ · 子ページを開いてください"
                        )
                        : hasGeneratedCards(item)
                            ? (
                                item.needsAIRefresh
                                    ? language.text(
                                        "已有卡片 · 建议 AI 更新",
                                        "カードあり · AI更新推奨"
                                    )
                                    : language.text(
                                        "已生成 AI 卡片",
                                        "AIカード生成済み"
                                    )
                            )
                            : language.text(
                                "待 AI 生成卡片",
                                "AIカード生成待ち"
                            ),
                    systemImage: !item.canGenerateAI
                        ? "folder"
                        : hasGeneratedCards(item)
                            ? (
                                item.needsAIRefresh
                                    ? "arrow.triangle.2.circlepath"
                                    : "checkmark.circle.fill"
                            )
                            : "sparkles"
                )
                .font(.caption2)
                .foregroundStyle(
                    hasGeneratedCards(item)
                        ? AppTheme.accent
                        : AppTheme.muted
                )
            }
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 6)
        .background(
            hasGeneratedCards(item)
                ? AppTheme.accent.opacity(0.07)
                : Color.clear
        )
        .clipShape(
            RoundedRectangle(
                cornerRadius: 9
            )
        )
        .opacity(
            item.canGenerateAI
                && !hasGeneratedCards(item)
                ? 0.62
                : 1.0
        )
        .accessibilityElement(children: .combine)
    }

    private func sourceIcon(
        _ sourceKind: String,
        depth: Int
    ) -> String {
        if sourceKind == "file" {
            return depth == 0
                ? "doc"
                : "doc.text"
        }

        return depth == 0
            ? "square.stack.3d.up"
            : "doc.text"
    }

    private func toggleLocalSelection(
        _ id: UUID
    ) {
        if selectedLocalRootIDs.contains(id) {
            selectedLocalRootIDs.remove(id)
        } else {
            selectedLocalRootIDs.insert(id)
        }
    }

    private func bulkDeleteSelectedLocalSources() {
        let targets = selectedLocalRootItems

        guard !targets.isEmpty else {
            return
        }

        let repository = LearningRepository(
            context: modelContext
        )

        var deletedCount = 0
        var failedTitles: [String] = []

        for item in targets {
            // Hard safety boundary:
            // multi-delete is LOCAL-ONLY.
            guard item.sourceKind == "file",
                  item.hierarchyDepth == 0
            else {
                continue
            }

            do {
                _ = try repository.deleteImportedSource(
                    sourceKind: "file",
                    rootExternalID:
                        item.rootExternalSourceID
                )
                deletedCount += 1
            } catch {
                failedTitles.append(
                    item.title
                )
            }
        }

        selectedLocalRootIDs.removeAll()
        isLocalMultiSelectMode = false

        if failedTitles.isEmpty {
            importStatusMessage = language.text(
                "已删除 \(deletedCount) 项本地资料。原始文件未被删除。",
                "\(deletedCount)件のローカル資料を削除しました。元ファイルは削除されていません。"
            )
        } else {
            importStatusMessage = language.text(
                "已删除 \(deletedCount) 项；\(failedTitles.count) 项删除失败，请重试。",
                "\(deletedCount)件を削除しました。\(failedTitles.count)件は削除できませんでした。再試行してください。"
            )
        }

        loadLibrary()
    }

    @MainActor
    private func importFiles(
        _ urls: [URL]
    ) async {
        guard !urls.isEmpty else {
            return
        }

        isImportingFiles = true
        importStatusMessage = language.text(
            "正在导入 \(urls.count) 个文件…",
            "\(urls.count)個のファイルを読み込み中…"
        )
        defer {
            isImportingFiles = false
        }

        var importedFiles = 0
        var importedDocuments = 0
        var insertedDocuments = 0
        var updatedDocuments = 0
        var unchangedDocuments = 0
        var deactivatedDocuments = 0
        var failures: [String] = []

        for url in urls {
            let didAccess = url
                .startAccessingSecurityScopedResource()
            defer {
                if didAccess {
                    url.stopAccessingSecurityScopedResource()
                }
            }

            do {
                let parsed = try await Task.detached(
                    priority: .userInitiated
                ) {
                    try LocalFileImporter()
                        .importFile(at: url)
                }.value

                let repository = LearningRepository(
                    context: modelContext
                )
                let report = try LocalFileImportService(
                    repository: repository
                )
                .persist(parsed)

                importedFiles += 1
                importedDocuments += report.documentCount
                insertedDocuments += report.inserted
                updatedDocuments += report.updated
                unchangedDocuments += report.unchanged
                deactivatedDocuments += report.deactivated
            } catch let error as LocalFileImportError {
                failures.append(
                    url.lastPathComponent
                        + "（"
                        + importErrorLabel(error)
                        + "）"
                )
            } catch {
                failures.append(
                    url.lastPathComponent
                )
            }
        }

        loadLibrary()

        if failures.isEmpty {
            importStatusMessage = language.text(
                "导入完成：\(importedFiles) 个文件，\(importedDocuments) 个资料单元；新增 \(insertedDocuments)，更新 \(updatedDocuments)，未变化 \(unchangedDocuments)，归档旧单元 \(deactivatedDocuments)。",
                "読み込み完了：\(importedFiles)ファイル、\(importedDocuments)資料単位；追加 \(insertedDocuments)、更新 \(updatedDocuments)、変更なし \(unchangedDocuments)、旧単位をアーカイブ \(deactivatedDocuments)。"
            )
        } else {
            importStatusMessage = language.text(
                "已导入 \(importedFiles) 个文件；\(failures.count) 个失败：\(failures.joined(separator: "、"))",
                "\(importedFiles)ファイルを読み込み、\(failures.count)件失敗しました：\(failures.joined(separator: "、"))"
            )
        }
    }

    private func archiveFileSource(
        _ item: ImportedDocumentSummary
    ) {
        do {
            let repository = LearningRepository(
                context: modelContext
            )
            _ = try repository.archiveImportedSource(
                sourceKind: item.sourceKind,
                rootExternalID: item.rootExternalSourceID
            )
            importStatusMessage = language.text(
                "已归档：\(item.title)。相关学习历史仍然保留。",
                "アーカイブ済み：\(item.title)。学習履歴は保持されています。"
            )
            loadLibrary()
        } catch {
            importStatusMessage = language.text(
                "无法归档该文件。",
                "このファイルをアーカイブできませんでした。"
            )
        }
    }

    private func deleteFileSource(
        _ item: ImportedDocumentSummary
    ) {
        do {
            let repository = LearningRepository(
                context: modelContext
            )

            let deletedDocuments = try repository
                .deleteImportedSource(
                    sourceKind: item.sourceKind,
                    rootExternalID: item.rootExternalSourceID
                )

            importStatusMessage = language.text(
                "已永久删除：\(item.title)（\(deletedDocuments) 个资料单元）。原始文件未被删除。",
                "完全に削除しました：\(item.title)（\(deletedDocuments)件の資料単位）。元のファイルは削除されていません。"
            )

            loadLibrary()
        } catch {
            importStatusMessage = language.text(
                "无法删除该文件。",
                "このファイルを削除できませんでした。"
            )
        }
    }

    private func importErrorLabel(
        _ error: LocalFileImportError
    ) -> String {
        switch error {
        case let .unsupportedExtension(ext):
            return language.text(
                "暂不支持 .\(ext)",
                ".\(ext) は未対応"
            )
        case .unreadableFile:
            return language.text(
                "无法读取",
                "読み取り不可"
            )
        case .emptyContent:
            return language.text(
                "未提取到文本",
                "テキストを抽出できません"
            )
        case .pdfUnavailable:
            return language.text(
                "当前平台不支持 PDF",
                "現在の環境ではPDF未対応"
            )
        case .imageTextRecognitionUnavailable:
            return language.text(
                "当前平台不支持图片文字识别",
                "現在の環境では画像文字認識未対応"
            )
        case .richDocumentUnavailable:
            return language.text(
                "当前平台不支持此文档格式",
                "現在の環境ではこの文書形式に対応していません"
            )
        }
    }

    private func loadLibrary() {
        do {
            let repository = LearningRepository(
                context: modelContext
            )
            reviewSources = try repository.reviewSources()
            importedItems = try repository.importedDocuments()

            let materials =
                try repository.studyMaterials()

            generatedCardCounts =
                Dictionary(
                    uniqueKeysWithValues:
                        materials.map {
                            (
                                $0.id,
                                $0.cardCount
                            )
                        }
                )

            loadError = nil
        } catch {
            loadError = language.text(
                "无法读取资料来源。",
                "学習ソースを読み込めませんでした。"
            )
        }
    }
}


private enum LibraryAIStatusFilter:
    String,
    CaseIterable,
    Identifiable
{
    case all
    case generated
    case pending

    var id: String {
        rawValue
    }
}
