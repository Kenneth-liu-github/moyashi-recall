import SwiftUI
import SwiftData

public struct MoyashiRecallRootView: View {
    @StateObject private var language = LanguageStore()
    @Environment(\.modelContext) private var modelContext
    @State private var migrationError: String?

    public init() {}

    public var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label(
                        language.text("首页", "ホーム"),
                        systemImage: "house"
                    )
                }

            NavigationStack {
                ReviewView()
            }
            .tabItem {
                Label(
                    language.text("复习", "復習"),
                    systemImage: "rectangle.stack"
                )
            }

            LibraryView()
                .tabItem {
                    Label(
                        language.text(
                            "资料库",
                            "ライブラリ"
                        ),
                        systemImage: "books.vertical"
                    )
                }

            CardsView()
                .tabItem {
                    Label(
                        language.text("卡片", "カード"),
                        systemImage: "square.stack.3d.up"
                    )
                }

            SettingsView()
                .tabItem {
                    Label(
                        language.text("设置", "設定"),
                        systemImage: "gearshape"
                    )
                }
        }
        .tint(AppTheme.accent)
        .environmentObject(language)
        .environment(
            \.locale,
            language.language.locale
        )
        .task {
            do {
                _ = try LearningRepository(
                    context: modelContext
                )
                .migrateLegacyImportedKnowledgeIfNeeded()
                migrationError = nil
            } catch {
                migrationError = language.text(
                    "本地学习数据升级失败。旧数据没有被删除，请重启 App 后重试。",
                    "ローカル学習データの更新に失敗しました。既存データは削除されていません。Appを再起動して再試行してください。"
                )
            }
        }
        .alert(
            language.text(
                "数据升级失败",
                "データ更新に失敗しました"
            ),
            isPresented: Binding(
                get: { migrationError != nil },
                set: { presented in
                    if !presented {
                        migrationError = nil
                    }
                }
            )
        ) {
            Button(
                language.text("知道了", "OK"),
                role: .cancel
            ) {
                migrationError = nil
            }
        } message: {
            if let migrationError {
                Text(migrationError)
            }
        }
    }
}
