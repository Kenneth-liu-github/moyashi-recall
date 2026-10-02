import SwiftUI
import SwiftData

public struct MoyashiRecallRootView: View {
    @StateObject private var language = LanguageStore()
    @StateObject private var notionMonitor =
        NotionConnectionMonitor()

    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @State private var migrationError: String?
    @State private var selectedTab: MoyashiRootTab = .home

    public init() {}

    public var body: some View {
        TabView(selection: $selectedTab) {
            HomeView {
                selectedTab = .review
            }
                .tag(MoyashiRootTab.home)
                .tabItem {
                    Label(
                        language.text("首页", "ホーム"),
                        systemImage: "house"
                    )
                }

            NavigationStack {
                ScopedReviewTabView()
            }
            .tag(MoyashiRootTab.review)
            .tabItem {
                Label(
                    language.text("复习", "復習"),
                    systemImage: "rectangle.stack"
                )
            }

            LibraryView()
                .tag(MoyashiRootTab.library)
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
                .tag(MoyashiRootTab.cards)
                .tabItem {
                    Label(
                        language.text("卡片", "カード"),
                        systemImage: "square.stack.3d.up"
                    )
                }

            SettingsView()
                .tag(MoyashiRootTab.settings)
                .tabItem {
                    Label(
                        language.text("设置", "設定"),
                        systemImage: "gearshape"
                    )
                }
        }
        .tint(AppTheme.accent)
        .environmentObject(language)
        .environmentObject(notionMonitor)
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
        .task(id: scenePhase) {
            guard scenePhase == .active else {
                return
            }

            await notionMonitor.checkNow()

            while !Task.isCancelled {
                do {
                    try await Task.sleep(
                        nanoseconds:
                            300_000_000_000
                    )
                } catch {
                    return
                }

                guard
                    !Task.isCancelled,
                    scenePhase == .active
                else {
                    return
                }

                await notionMonitor.checkNow()
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


private enum MoyashiRootTab: Hashable {
    case home
    case review
    case library
    case cards
    case settings
}

private struct ScopedReviewTabView: View {
    @EnvironmentObject private var language: LanguageStore

    @State private var scope: StudyScopePreferences?
    @State private var reviewIdentity = UUID()

    private var validDocumentIDs: Set<UUID>? {
        guard
            let ids = scope?.documentIDs,
            !ids.isEmpty
        else {
            return nil
        }

        return ids
    }

    private var hasValidScope: Bool {
        guard
            let scope,
            !scope.cardTypes.isEmpty,
            let ids = scope.documentIDs,
            !ids.isEmpty
        else {
            return false
        }

        return true
    }

    var body: some View {
        Group {
            if hasValidScope,
               let scope,
               let documentIDs = validDocumentIDs {
                ReviewView(
                    sourceKeys: scope.sourceKeys,
                    cardTypes: scope.cardTypes,
                    sourceDocumentIDs: documentIDs,
                    sessionLimit: scope.reviewCount
                )
                .id(reviewIdentity)
            } else {
                ContentUnavailableView(
                    language.text(
                        "尚未选择复习卡片",
                        "復習カードが選択されていません"
                    ),
                    systemImage: "rectangle.stack",
                    description: Text(
                        language.text(
                            "请先在首页的“选择学习范围”中添加复习卡片。",
                            "ホームの「学習範囲を選択」から復習カードを追加してください。"
                        )
                    )
                )
                .navigationTitle(
                    language.text(
                        "复习",
                        "復習"
                    )
                )
            }
        }
        .onAppear {
            reloadScope()
        }
    }

    private func reloadScope() {
        let newScope =
            StudyScopePreferencesStore()
                .load()

        if newScope != scope {
            scope = newScope
            reviewIdentity = UUID()
        }
    }
}
