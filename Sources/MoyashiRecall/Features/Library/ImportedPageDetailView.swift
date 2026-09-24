import Foundation
import SwiftUI

public struct ImportedPageDetailView: View {
    @EnvironmentObject private var language: LanguageStore
    private let item: ImportedDocumentSummary

    public init(item: ImportedDocumentSummary) {
        self.item = item
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
    }
}
