import SwiftUI

public struct MoyashiRecallRootView: View {
    @StateObject private var language = LanguageStore()

    public init() {}

    public var body: some View {
        TabView {
            HomeView()
                .tabItem { Label(language.text("首页", "ホーム"), systemImage: "house") }
            NavigationStack {
                ReviewView()
            }
                .tabItem { Label(language.text("复习", "復習"), systemImage: "rectangle.stack") }
            LibraryView()
                .tabItem { Label(language.text("资料库", "ライブラリ"), systemImage: "books.vertical") }
            CardsView()
                .tabItem { Label(language.text("卡片", "カード"), systemImage: "square.stack.3d.up") }
            SettingsView()
                .tabItem { Label(language.text("设置", "設定"), systemImage: "gearshape") }
        }
        .tint(AppTheme.accent)
        .environmentObject(language)
        .environment(\.locale, language.language.locale)
    }
}
