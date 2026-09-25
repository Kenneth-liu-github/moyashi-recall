import SwiftUI
import SwiftData

public struct ReviewHistoryView: View {
    @EnvironmentObject private var language: LanguageStore
    @Environment(\.modelContext) private var modelContext

    @State private var items: [ReviewHistorySummary] = []
    @State private var loadError: String?

    public init() {}

    public var body: some View {
        Group {
            if let loadError {
                ContentUnavailableView(
                    language.text(
                        "无法读取复习记录",
                        "復習履歴を読み込めません"
                    ),
                    systemImage: "exclamationmark.triangle",
                    description: Text(loadError)
                )
            } else if items.isEmpty {
                ContentUnavailableView(
                    language.text(
                        "还没有复习记录",
                        "復習履歴はまだありません"
                    ),
                    systemImage: "clock.arrow.circlepath"
                )
            } else {
                List(items) { item in
                    VStack(
                        alignment: .leading,
                        spacing: 6
                    ) {
                        HStack {
                            Text(
                                ratingLabel(
                                    item.rating
                                )
                            )
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(AppTheme.accent)

                            Spacer()

                            Text(
                                item.reviewedAt.formatted(
                                    date: .abbreviated,
                                    time: .shortened
                                )
                            )
                            .font(.caption)
                            .foregroundStyle(AppTheme.muted)
                        }

                        Text(item.prompt)
                            .font(.headline)

                        Text(item.answer)
                            .foregroundStyle(AppTheme.muted)

                        if !item.sourceDisplay.isEmpty {
                            Text(item.sourceDisplay)
                                .font(.caption2)
                                .foregroundStyle(AppTheme.muted)
                                .lineLimit(2)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .navigationTitle(
            language.text(
                "复习记录",
                "復習履歴"
            )
        )
        .onAppear {
            loadHistory()
        }
    }

    private func loadHistory() {
        do {
            items = try LearningRepository(
                context: modelContext
            )
            .recentReviewHistory()
            loadError = nil
        } catch {
            loadError = language.text(
                "无法读取本地复习历史。",
                "ローカルの復習履歴を読み込めませんでした。"
            )
        }
    }

    private func ratingLabel(
        _ rating: ReviewRating
    ) -> String {
        switch rating {
        case .again:
            return language.text(
                "重来",
                "もう一度"
            )
        case .hard:
            return language.text(
                "困难",
                "難しい"
            )
        case .good:
            return language.text(
                "良好",
                "良い"
            )
        case .easy:
            return language.text(
                "简单",
                "簡単"
            )
        }
    }
}
