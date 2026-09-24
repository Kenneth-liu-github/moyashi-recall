import SwiftUI
import SwiftData

public struct StudyScopeView: View {
    @EnvironmentObject private var language: LanguageStore
    @Environment(\.modelContext) private var modelContext
    @State private var selected = Set<UUID>()
    @State private var reviewCount = 20
    @State private var sourceCounts: [String: Int] = [:]

    public init() {}

    private var selectedSourceKeys: Set<String> {
        Set(MockData.sources.filter { selected.contains($0.id) }.map(\.key))
    }

    public var body: some View {
        List {
            Section {
                ForEach(MockData.sources) { source in
                    Button {
                        toggle(source.id)
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: selected.contains(source.id) ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(AppTheme.accent)
                            VStack(alignment: .leading, spacing: 3) {
                                Text(source.title).foregroundStyle(AppTheme.ink)
                                Text(source.detail).font(.caption).foregroundStyle(AppTheme.muted)
                            }
                            Spacer()
                            Text("\(sourceCounts[source.key, default: 0])").font(.subheadline).foregroundStyle(AppTheme.muted)
                        }
                    }
                }
            } header: {
                Text(language.text("学习来源（可多选）", "学習ソース（複数選択可）"))
            }

            Section(language.text("本次复习数量", "今回の復習枚数")) {
                Picker(language.text("卡片数量", "カード枚数"), selection: $reviewCount) {
                    Text("10").tag(10)
                    Text("20").tag(20)
                    Text("30").tag(30)
                }
                .pickerStyle(.segmented)
            }

            Section(language.text("卡片类型", "カードタイプ")) {
                Label(language.text("中→日 · 日→中 · Cloze · 语法对比", "中→日 · 日→中 · Cloze · 文法比較"), systemImage: "rectangle.stack")
                    .foregroundStyle(AppTheme.ink)
            }

            Section {
                NavigationLink {
                    ReviewView(sourceKeys: selectedSourceKeys, sessionLimit: reviewCount)
                } label: {
                    HStack {
                        Spacer()
                        Text(language.text("开始复习 · \(reviewCount) 张", "復習を開始 · \(reviewCount)枚"))
                            .fontWeight(.semibold)
                            .foregroundStyle(AppTheme.accent)
                        Spacer()
                    }
                }
                .disabled(selected.isEmpty)
            } footer: {
                if selected.isEmpty {
                    Text(language.text("请至少选择一个学习来源。", "学習ソースを1つ以上選択してください。"))
                }
            }
        }
        .navigationTitle(language.text("选择学习范围", "学習範囲を選択"))
        .onAppear {
            if selected.isEmpty {
                selected = Set(MockData.sources.map(\.id))
            }
            loadSourceCounts()
        }
    }

    private func toggle(_ id: UUID) {
        if selected.contains(id) { selected.remove(id) } else { selected.insert(id) }
    }

    private func loadSourceCounts() {
        do {
            let repository = LearningRepository(context: modelContext)
            try repository.seedDemoIfNeeded()
            sourceCounts = try repository.cardCountsBySourceKey()
        } catch {
            sourceCounts = [:]
        }
    }
}

