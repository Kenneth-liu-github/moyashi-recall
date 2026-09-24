import Foundation
import SwiftUI
import SwiftData

public struct ImportedPageDetailView: View {
    @EnvironmentObject private var language: LanguageStore
    @Environment(\.modelContext) private var modelContext

    @State private var isProcessing = false
    @State private var aiStatusMessage: String?
    @State private var isAIUpToDate: Bool
    @State private var generatedSummary = GeneratedContentSummary(
        knowledgeCount: 0,
        cardCount: 0
    )
    @State private var generatedKnowledge: [GeneratedKnowledgeSummary] = []

    private let item: ImportedDocumentSummary

    public init(item: ImportedDocumentSummary) {
        self.item = item
        _isAIUpToDate = State(
            initialValue: !item.needsAIRefresh
        )
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(item.title)
                        .font(.title2.bold())

                    Text(item.sourcePath)
                        .font(.caption)
                        .foregroundStyle(AppTheme.muted)
                }

                Divider()

                if item.content
                    .trimmingCharacters(
                        in: .whitespacesAndNewlines
                    )
                    .isEmpty {
                    Text(
                        language.text(
                            "此页面当前没有可显示的文本内容。",
                            "このページには表示できるテキストがありません。"
                        )
                    )
                    .foregroundStyle(AppTheme.muted)
                } else {
                    Text(item.content)
                        .font(.body)
                        .textSelection(.enabled)

                    Button {
                        Task {
                            await processWithAI()
                        }
                    } label: {
                        HStack {
                            if isProcessing {
                                ProgressView()
                            } else {
                                Image(
                                    systemName: "sparkles"
                                )
                            }

                            Text(
                                language.text(
                                    "AI 提取知识并生成卡片",
                                    "AIで知識とカードを生成"
                                )
                            )
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(AppTheme.accent)
                    .disabled(isProcessing)
                }

                HStack(spacing: 12) {
                    Label(
                        "\(generatedSummary.knowledgeCount) "
                            + language.text(
                                "知识点",
                                "知識"
                            ),
                        systemImage: "brain"
                    )
                    Label(
                        "\(generatedSummary.cardCount) "
                            + language.text(
                                "卡片",
                                "カード"
                            ),
                        systemImage: "rectangle.stack"
                    )
                }
                .font(.caption)
                .foregroundStyle(AppTheme.muted)

                HStack(spacing: 8) {
                    Image(
                        systemName: isAIUpToDate
                            ? "checkmark.circle"
                            : "sparkles"
                    )
                    .foregroundStyle(
                        isAIUpToDate
                            ? AppTheme.muted
                            : AppTheme.accent
                    )

                    Text(
                        isAIUpToDate
                            ? language.text(
                                "AI 内容与当前资料一致",
                                "AI内容は現在の資料と一致しています"
                            )
                            : language.text(
                                "资料有新内容，建议重新生成",
                                "資料が更新されています。再生成を推奨します"
                            )
                    )
                    .font(.caption)
                    .foregroundStyle(AppTheme.muted)
                }

                if let aiStatusMessage {
                    Text(aiStatusMessage)
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.muted)
                }

                if !generatedKnowledge.isEmpty {
                    Divider()

                    VStack(alignment: .leading, spacing: 12) {
                        Text(
                            language.text(
                                "AI 提取的知识",
                                "AIが抽出した知識"
                            )
                        )
                        .font(.headline)

                        ForEach(generatedKnowledge) { knowledge in
                            VStack(
                                alignment: .leading,
                                spacing: 5
                            ) {
                                HStack {
                                    Text(knowledge.title)
                                        .font(.subheadline.bold())

                                    Spacer()

                                    Text(
                                        "\(knowledge.cardCount) "
                                            + language.text(
                                                "卡",
                                                "枚"
                                            )
                                    )
                                    .font(.caption2)
                                    .foregroundStyle(AppTheme.muted)
                                }

                                if !knowledge.canonicalExpression.isEmpty {
                                    Text(
                                        knowledge.canonicalExpression
                                    )
                                    .font(.subheadline)
                                }

                                if !knowledge.meaning.isEmpty {
                                    Text(knowledge.meaning)
                                        .font(.caption)
                                        .foregroundStyle(
                                            AppTheme.muted
                                        )
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }

                Divider()

                VStack(alignment: .leading, spacing: 6) {
                    LabeledContent(
                        language.text(
                            "来源",
                            "ソース"
                        ),
                        value: item.sourceKind
                    )

                    if let sourceLastEditedAt = item.sourceLastEditedAt {
                        LabeledContent(
                            language.text(
                                "来源最后修改",
                                "ソース最終更新"
                            ),
                            value: sourceLastEditedAt.formatted(
                                date: .abbreviated,
                                time: .shortened
                            )
                        )
                    }

                    if let lastSyncedAt = item.lastSyncedAt {
                        LabeledContent(
                            language.text(
                                "最近同步",
                                "最終同期"
                            ),
                            value: lastSyncedAt.formatted(
                                date: .abbreviated,
                                time: .shortened
                            )
                        )
                    }
                }
                .font(.caption)
                .foregroundStyle(AppTheme.muted)
            }
            .padding()
        }
        .navigationTitle(
            language.text(
                "资料详情",
                "資料詳細"
            )
        )
        .onAppear {
            loadGeneratedSummary()
        }
    }

    @MainActor
    private func processWithAI() async {
        isProcessing = true
        aiStatusMessage = language.text(
            "正在提取知识并生成卡片…",
            "知識とカードを生成中…"
        )
        defer {
            isProcessing = false
        }

        do {
            let provider = try AIProviderFactory
                .makeConfiguredProvider()
            let repository = LearningRepository(
                context: modelContext
            )
            let service = AIProcessingService(
                repository: repository,
                provider: provider
            )

            let result = try await service.process(
                sourceDocumentID: item.id
            )

            isAIUpToDate = true
            loadGeneratedSummary()
            aiStatusMessage = language.text(
                "完成：提取 \(result.extractedItems) 个知识点；新增卡片 \(result.persistence.cardsInserted)，更新 \(result.persistence.cardsUpdated)，未变化 \(result.persistence.cardsUnchanged)。",
                "完了：\(result.extractedItems)件の知識を抽出；カード追加 \(result.persistence.cardsInserted)、更新 \(result.persistence.cardsUpdated)、変更なし \(result.persistence.cardsUnchanged)。"
            )
        } catch let error as AIProviderError {
            aiStatusMessage = providerErrorMessage(error)
        } catch let error as AIProcessingError {
            switch error {
            case .sourceDocumentNotFound:
                aiStatusMessage = language.text(
                    "找不到该本地资料，请返回资料库后重试。",
                    "ローカル資料が見つかりません。ライブラリから再試行してください。"
                )

            case .emptySourceDocument:
                aiStatusMessage = language.text(
                    "此页面没有可供 AI 提取的文本内容。",
                    "このページにはAI抽出に使えるテキストがありません。"
                )
            }
        } catch {
            aiStatusMessage = language.text(
                "AI 处理失败。",
                "AI処理に失敗しました。"
            )
        }
    }

    private func loadGeneratedSummary() {
        do {
            let repository = LearningRepository(
                context: modelContext
            )
            generatedSummary = try repository
                .generatedContentSummary(
                    sourceDocumentID: item.id
                )
            generatedKnowledge = try repository
                .generatedKnowledgeItems(
                    sourceDocumentID: item.id
                )
        } catch {
            generatedSummary = GeneratedContentSummary(
                knowledgeCount: 0,
                cardCount: 0
            )
            generatedKnowledge = []
        }
    }

    private func providerErrorMessage(
        _ error: AIProviderError
    ) -> String {
        switch error {
        case let .missingConfiguration(field):
            return language.text(
                "请先在设置中完成 AI 配置：\(field)。",
                "設定でAI構成を完了してください：\(field)。"
            )

        case let .http(statusCode, message):
            return language.text(
                "AI Provider 返回错误 \(statusCode)：\(message)",
                "AI Provider エラー \(statusCode)：\(message)"
            )

        case .invalidResponse, .decodingFailed:
            return language.text(
                "AI 返回的数据格式无效。",
                "AIの応答形式が無効です。"
            )
        }
    }
}
