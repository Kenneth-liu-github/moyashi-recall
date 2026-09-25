import SwiftUI
import SwiftData
import UniformTypeIdentifiers

public struct DataExportView: View {
    @EnvironmentObject private var language: LanguageStore
    @Environment(\.modelContext) private var modelContext

    @State private var document: LearningDataExportDocument?
    @State private var isExporting = false
    @State private var isImporting = false
    @State private var pendingRestoreData: Data?
    @State private var pendingRestoreReport:
        LearningDataImportValidationReport?
    @State private var showingRestoreConfirmation = false
    @State private var statusMessage: String?

    public init() {}

    public var body: some View {
        Form {
            Section {
                Button {
                    prepareExport()
                } label: {
                    Label(
                        language.text(
                            "导出学习数据",
                            "学習データを書き出す"
                        ),
                        systemImage: "square.and.arrow.up"
                    )
                }
            } header: {
                Text(
                    language.text(
                        "JSON 备份",
                        "JSONバックアップ"
                    )
                )
            } footer: {
                Text(
                    language.text(
                        "备份包含同步资料文本、AI 生成知识与卡片、FSRS 状态和复习历史；不包含 Notion Token、AI API Key 或其他 Keychain 凭证。",
                        "バックアップには同期資料、AI生成知識・カード、FSRS状態、復習履歴が含まれます。Notion Token、AI API KeyなどのKeychain認証情報は含まれません。"
                    )
                )
            }

            Section {
                Button {
                    isImporting = true
                } label: {
                    Label(
                        language.text(
                            "从 JSON 备份恢复",
                            "JSONバックアップから復元"
                        ),
                        systemImage: "square.and.arrow.down"
                    )
                }
            } header: {
                Text(
                    language.text(
                        "安全恢复",
                        "安全な復元"
                    )
                )
            } footer: {
                Text(
                    language.text(
                        "恢复采用非破坏式合并：缺失记录会新增；备份中更新、且比本地更新的记录会更新；本地独有或更新的数据不会被删除或回退。凭证与设置不会导入。",
                        "復元は非破壊マージです。欠けている記録は追加し、バックアップ側がより新しい記録のみ更新します。ローカル独自またはより新しいデータは削除・巻き戻しされません。認証情報や設定は読み込みません。"
                    )
                )
            }

            if let pendingRestoreReport {
                Section(
                    language.text(
                        "待恢复备份",
                        "復元予定バックアップ"
                    )
                ) {
                    LabeledContent(
                        language.text(
                            "资料",
                            "資料"
                        ),
                        value: "\(pendingRestoreReport.sourceCount)"
                    )
                    LabeledContent(
                        language.text(
                            "知识点",
                            "知識項目"
                        ),
                        value: "\(pendingRestoreReport.knowledgeItemCount)"
                    )
                    LabeledContent(
                        language.text(
                            "卡片",
                            "カード"
                        ),
                        value: "\(pendingRestoreReport.flashcardCount)"
                    )
                    LabeledContent(
                        "FSRS",
                        value: "\(pendingRestoreReport.reviewStateCount)"
                    )
                    LabeledContent(
                        language.text(
                            "复习记录",
                            "復習履歴"
                        ),
                        value: "\(pendingRestoreReport.reviewHistoryCount)"
                    )

                    Button {
                        showingRestoreConfirmation = true
                    } label: {
                        Label(
                            language.text(
                                "确认安全合并",
                                "安全なマージを確認"
                            ),
                            systemImage: "checkmark.shield"
                        )
                    }

                    Button(
                        language.text(
                            "取消此次恢复",
                            "今回の復元をキャンセル"
                        ),
                        role: .cancel
                    ) {
                        clearPendingRestore()
                    }
                }
            }

            if let statusMessage {
                Section {
                    Text(statusMessage)
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.muted)
                }
            }
        }
        .navigationTitle(
            language.text(
                "数据备份",
                "データバックアップ"
            )
        )
        .fileExporter(
            isPresented: $isExporting,
            document: document,
            contentType: .json,
            defaultFilename: defaultFilename
        ) { result in
            switch result {
            case .success:
                statusMessage = language.text(
                    "学习数据已导出。",
                    "学習データを書き出しました。"
                )
            case .failure:
                statusMessage = language.text(
                    "数据导出未完成。",
                    "データ書き出しが完了しませんでした。"
                )
            }
        }
        .fileImporter(
            isPresented: $isImporting,
            allowedContentTypes: [.json],
            allowsMultipleSelection: false
        ) { result in
            handleImport(result)
        }
        .confirmationDialog(
            language.text(
                "确认恢复学习数据？",
                "学習データを復元しますか？"
            ),
            isPresented: $showingRestoreConfirmation,
            titleVisibility: .visible
        ) {
            Button(
                language.text(
                    "安全合并到本地",
                    "ローカルへ安全にマージ"
                )
            ) {
                performRestore()
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
                    "此操作不会删除本地独有数据，也不会导入任何凭证。",
                    "この操作はローカル独自データを削除せず、認証情報も読み込みません。"
                )
            )
        }
    }

    private func prepareExport() {
        do {
            let data = try LearningDataExportService(
                context: modelContext
            ).makeJSONData()
            document = LearningDataExportDocument(
                data: data
            )
            isExporting = true
            statusMessage = nil
        } catch {
            document = nil
            isExporting = false
            statusMessage = language.text(
                "无法生成学习数据备份。",
                "学習データのバックアップを生成できませんでした。"
            )
        }
    }

    private func handleImport(
        _ result: Result<[URL], Error>
    ) {
        clearPendingRestore()

        do {
            let urls = try result.get()
            guard let url = urls.first else {
                return
            }

            let accessed = url.startAccessingSecurityScopedResource()
            defer {
                if accessed {
                    url.stopAccessingSecurityScopedResource()
                }
            }

            let limits = LearningDataImportValidationLimits.standard
            let fileSize = try url.resourceValues(
                forKeys: [.fileSizeKey]
            ).fileSize

            if let fileSize,
               fileSize > limits.maximumBytes {
                throw LearningDataImportValidationError
                    .backupTooLarge(fileSize)
            }

            let data = try Data(
                contentsOf: url,
                options: [.mappedIfSafe]
            )
            let validated = try LearningDataImportValidator
                .decodeAndValidate(
                    data,
                    limits: limits
                )

            pendingRestoreData = data
            pendingRestoreReport = validated.report
            statusMessage = language.text(
                "备份验证通过。请检查数量后确认安全合并。",
                "バックアップの検証に成功しました。件数を確認して安全なマージを実行してください。"
            )
        } catch let error as LearningDataImportValidationError {
            statusMessage = validationErrorMessage(
                error
            )
        } catch {
            statusMessage = language.text(
                "无法读取所选备份文件。",
                "選択したバックアップファイルを読み込めませんでした。"
            )
        }
    }

    private func performRestore() {
        guard let pendingRestoreData else {
            return
        }

        do {
            let report = try LearningDataRestoreService(
                context: modelContext
            ).restore(data: pendingRestoreData)

            clearPendingRestore()
            statusMessage = language.text(
                "恢复完成：新增 \(report.insertedTotal)，更新 \(report.updatedTotal)。本地独有或更新的数据已保留。",
                "復元完了：追加 \(report.insertedTotal)、更新 \(report.updatedTotal)。ローカル独自またはより新しいデータは保持されています。"
            )
        } catch let error as LearningDataImportValidationError {
            clearPendingRestore()
            statusMessage = validationErrorMessage(
                error
            )
        } catch {
            statusMessage = language.text(
                "恢复失败，本地数据未完成写入。",
                "復元に失敗しました。ローカルデータへの書き込みは完了していません。"
            )
        }
    }

    private func clearPendingRestore() {
        pendingRestoreData = nil
        pendingRestoreReport = nil
        showingRestoreConfirmation = false
    }

    private func validationErrorMessage(
        _ error: LearningDataImportValidationError
    ) -> String {
        switch error {
        case .decodingFailed:
            return language.text(
                "备份文件不是有效的 Moyashi Recall JSON。",
                "有効なMoyashi Recall JSONバックアップではありません。"
            )
        case .unsupportedSchema:
            return language.text(
                "备份版本与当前 App 不兼容。",
                "バックアップのバージョンは現在のAppと互換性がありません。"
            )
        case .backupTooLarge,
             .tooManySources,
             .tooManyKnowledgeItems,
             .tooManyFlashcards,
             .tooManyReviewStates,
             .tooManyReviewHistory:
            return language.text(
                "备份内容超过安全导入上限。",
                "バックアップが安全な読み込み上限を超えています。"
            )
        default:
            return language.text(
                "备份内部数据关系或复习状态无效，为保护本地数据已停止恢复。",
                "バックアップ内部のデータ関係または復習状態が無効なため、ローカルデータ保護のため復元を停止しました。"
            )
        }
    }

    private var defaultFilename: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(
            identifier: "en_US_POSIX"
        )
        formatter.dateFormat = "yyyy-MM-dd"
        return "MoyashiRecall-Backup-\(formatter.string(from: .now))"
    }
}
