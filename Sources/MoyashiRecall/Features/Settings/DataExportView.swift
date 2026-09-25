import SwiftUI
import SwiftData
import UniformTypeIdentifiers

public struct DataExportView: View {
    @EnvironmentObject private var language: LanguageStore
    @Environment(\.modelContext) private var modelContext

    @State private var document: LearningDataExportDocument?
    @State private var isExporting = false
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
                "数据导出",
                "データ書き出し"
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

    private var defaultFilename: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(
            identifier: "en_US_POSIX"
        )
        formatter.dateFormat = "yyyy-MM-dd"
        return "MoyashiRecall-Backup-\(formatter.string(from: .now))"
    }
}
