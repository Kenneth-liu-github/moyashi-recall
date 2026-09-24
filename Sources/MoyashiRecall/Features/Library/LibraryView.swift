import SwiftUI

public struct LibraryView: View {
    @EnvironmentObject private var language: LanguageStore
    public init() {}

    public var body: some View {
        NavigationStack {
            List(MockData.sources) { source in
                VStack(alignment: .leading, spacing: 4) {
                    Text(source.title)
                    Text(source.detail + " · \(source.itemCount)")
                        .font(.caption)
                        .foregroundStyle(AppTheme.muted)
                }
            }
            .navigationTitle(language.text("资料库", "ライブラリ"))
        }
    }
}
