import SwiftUI
import SwiftData

public struct LibraryView: View {
    @EnvironmentObject private var language: LanguageStore
    @Environment(\.modelContext) private var modelContext

    @State private var counts: [String: Int] = [:]
    @State private var loadError: String?

    public init() {}

    public var body: some View {
        NavigationStack {
            Group {
                if let loadError {
                    ContentUnavailableView(
                        language.text("无法读取资料库", "ライブラリを読み込めません"),
                        systemImage: "exclamationmark.triangle",
                        description: Text(loadError)
                    )
                } else {
                    List(MockData.sources) { source in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(source.title)
                            Text(source.detail + " · \(counts[source.key, default: 0])")
                                .font(.caption)
                                .foregroundStyle(AppTheme.muted)
                        }
                    }
                }
            }
            .navigationTitle(language.text("资料库", "ライブラリ"))
            .onAppear { loadCounts() }
        }
    }

    private func loadCounts() {
        do {
            let repository = LearningRepository(context: modelContext)
            try repository.seedDemoIfNeeded()
            counts = try repository.cardCountsBySourceKey()
            loadError = nil
        } catch {
            loadError = language.text(
                "无法读取资料来源。",
                "学習ソースを読み込めませんでした。"
            )
        }
    }
}
