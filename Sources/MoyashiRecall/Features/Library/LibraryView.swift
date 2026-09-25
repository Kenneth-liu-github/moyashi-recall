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

    public init() {}

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

                        if !importedItems.isEmpty {
                            Section(
                                language.text(
                                    "学习资料",
                                    "学習資料"
                                )
                            ) {
                                ForEach(importedItems) { item in
                                    NavigationLink {
                                        ImportedPageDetailView(
                                            item: item
                                        )
                                    } label: {
                                        importedRow(item)
                                    }
                                    .swipeActions {
                                        if item.sourceKind == "file",
                                           item.hierarchyDepth == 0 {
                                            Button(
                                                role: .destructive
                                            ) {
                                                archiveFileSource(item)
                                            } label: {
                                                Label(
                                                    language.text(
                                                        "归档",
                                                        "アーカイブ"
                                                    ),
                                                    systemImage: "archivebox"
                                                )
                                            }
                                        }
                                    }
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
            .image
        ]

        if let markdown = UTType(
            filenameExtension: "md"
        ) {
            types.append(markdown)
        }

        return types
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
                Text(item.title)

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
                        : item.needsAIRefresh
                            ? language.text(
                                "待 AI 生成/更新",
                                "AI生成・更新待ち"
                            )
                            : language.text(
                                "AI 已同步",
                                "AI同期済み"
                            ),
                    systemImage: !item.canGenerateAI
                        ? "folder"
                        : item.needsAIRefresh
                            ? "sparkles"
                            : "checkmark.circle"
                )
                .font(.caption2)
                .foregroundStyle(
                    item.canGenerateAI
                        && item.needsAIRefresh
                        ? AppTheme.accent
                        : AppTheme.muted
                )
            }
        }
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
                "导入完成：\(importedFiles) 个文件，\(importedDocuments) 个资料单元。",
                "読み込み完了：\(importedFiles)ファイル、\(importedDocuments)資料単位。"
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
        }
    }

    private func loadLibrary() {
        do {
            let repository = LearningRepository(
                context: modelContext
            )
            reviewSources = try repository.reviewSources()
            importedItems = try repository.importedDocuments()
            loadError = nil
        } catch {
            loadError = language.text(
                "无法读取资料来源。",
                "学習ソースを読み込めませんでした。"
            )
        }
    }
}
