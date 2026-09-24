import SwiftUI
import SwiftData

public struct LibraryView: View {
    @EnvironmentObject private var language: LanguageStore
    @Environment(\.modelContext) private var modelContext

    @State private var counts: [String: Int] = [:]
    @State private var importedItems: [ImportedKnowledgeSummary] = []
    @State private var loadError: String?

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
                        if !importedItems.isEmpty {
                            Section(
                                language.text(
                                    "已同步资料",
                                    "同期済み資料"
                                )
                            ) {
                                ForEach(importedItems) { item in
                                    importedRow(item)
                                }
                            }
                        }

                        Section(
                            language.text(
                                "复习卡片来源",
                                "復習カードのソース"
                            )
                        ) {
                            ForEach(MockData.sources) { source in
                                VStack(
                                    alignment: .leading,
                                    spacing: 4
                                ) {
                                    Text(source.title)
                                    Text(
                                        source.detail
                                            + " · "
                                            + "\(counts[source.key, default: 0])"
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
            .onAppear {
                loadLibrary()
            }
        }
    }

    private func importedRow(
        _ item: ImportedKnowledgeSummary
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
                systemName: item.hierarchyDepth == 0
                    ? "square.stack.3d.up"
                    : "doc.text"
            )
            .foregroundStyle(AppTheme.accent)
            .frame(width: 20)

            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)

                Text(item.sourcePath)
                    .font(.caption)
                    .foregroundStyle(AppTheme.muted)
                    .lineLimit(2)
            }
        }
        .accessibilityElement(children: .combine)
    }

    private func loadLibrary() {
        do {
            let repository = LearningRepository(
                context: modelContext
            )
            try repository.seedDemoIfNeeded()
            counts = try repository.cardCountsBySourceKey()
            importedItems = try repository.importedKnowledgeItems(
                sourceKind: "notion"
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
