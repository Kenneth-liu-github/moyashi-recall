import SwiftUI

public struct StudyScopeView: View {
    @EnvironmentObject private var language: LanguageStore
    @State private var selected = Set<UUID>()

    public init() {}

    public var body: some View {
        List {
            Section(language.text("学习来源", "学習ソース")) {
                ForEach(MockData.sources) { source in
                    Button {
                        if selected.contains(source.id) { selected.remove(source.id) } else { selected.insert(source.id) }
                    } label: {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(source.title).foregroundStyle(AppTheme.ink)
                                Text(source.detail).font(.caption).foregroundStyle(AppTheme.muted)
                            }
                            Spacer()
                            Text("\(source.itemCount)").foregroundStyle(AppTheme.muted)
                            Image(systemName: selected.contains(source.id) ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(AppTheme.accent)
                        }
                    }
                }
            }

            Section(language.text("卡片类型", "カードタイプ")) {
                Text(language.text("中→日 · 日→中 · Cloze · 语法对比", "中→日 · 日→中 · Cloze · 文法比較"))
            }

            Section {
                NavigationLink(language.text("开始复习", "復習を開始")) { ReviewView() }
            }
        }
        .navigationTitle(language.text("选择学习范围", "学習範囲を選択"))
    }
}
