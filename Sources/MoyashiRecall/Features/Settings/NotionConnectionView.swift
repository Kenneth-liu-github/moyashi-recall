import SwiftUI
import SwiftData

public struct NotionConnectionView: View {
    @EnvironmentObject private var language: LanguageStore
    @Environment(\.modelContext) private var modelContext

    @AppStorage("notionRootPageID") private var rootPageID = ""
    @State private var tokenDraft = ""
    @State private var searchText = "Learning Home"
    @State private var searchResults: [NotionPageSummary] = []
    @State private var statusMessage: String?
    @State private var hasStoredToken = false
    @State private var isWorking = false

    private let credentialStore = KeychainCredentialStore()

    public init() {}

    public var body: some View {
        Form {
            Section {
                SecureField(
                    language.text(
                        "Notion Integration Token",
                        "Notion Integration Token"
                    ),
                    text: $tokenDraft
                )
                .textContentType(.password)

                HStack {
                    Text(
                        language.text(
                            "凭证状态",
                            "認証情報"
                        )
                    )
                    Spacer()
                    Text(
                        hasStoredToken
                            ? language.text("已安全保存", "保存済み")
                            : language.text("未配置", "未設定")
                    )
                    .foregroundStyle(AppTheme.muted)
                }

                Button(
                    language.text(
                        "保存 Token",
                        "Tokenを保存"
                    )
                ) {
                    saveToken()
                }
                .disabled(
                    tokenDraft
                        .trimmingCharacters(
                            in: .whitespacesAndNewlines
                        )
                        .isEmpty
                )

                if hasStoredToken {
                    Button(
                        language.text(
                            "删除已保存 Token",
                            "保存済みTokenを削除"
                        ),
                        role: .destructive
                    ) {
                        deleteToken()
                    }
                }
            } header: {
                Text(
                    language.text(
                        "安全凭证",
                        "安全な認証情報"
                    )
                )
            } footer: {
                Text(
                    language.text(
                        "Token 仅保存在 Apple Keychain 中，不写入 GitHub、UserDefaults 或学习数据库。",
                        "TokenはApple Keychainのみに保存され、GitHubや学習データベースには保存されません。"
                    )
                )
            }

            Section {
                TextField(
                    language.text(
                        "搜索页面，例如 Learning Home",
                        "ページを検索"
                    ),
                    text: $searchText
                )

                Button(
                    language.text(
                        "搜索 Notion 页面",
                        "Notionページを検索"
                    )
                ) {
                    Task {
                        await searchPages()
                    }
                }
                .disabled(isWorking)

                ForEach(searchResults, id: \.id) { page in
                    Button {
                        rootPageID = page.id
                        statusMessage = language.text(
                            "已选择：\(page.title)",
                            "選択済み：\(page.title)"
                        )
                    } label: {
                        HStack {
                            VStack(
                                alignment: .leading,
                                spacing: 3
                            ) {
                                Text(page.title)
                                    .foregroundStyle(AppTheme.ink)
                                Text(page.id)
                                    .font(.caption2)
                                    .foregroundStyle(AppTheme.muted)
                                    .lineLimit(1)
                            }
                            Spacer()
                            if rootPageID == page.id {
                                Image(
                                    systemName: "checkmark.circle.fill"
                                )
                                .foregroundStyle(AppTheme.accent)
                            }
                        }
                    }
                }
            } header: {
                Text(
                    language.text(
                        "选择学习根页面",
                        "学習ルートページ"
                    )
                )
            }

            if !rootPageID.isEmpty {
                Section {
                    LabeledContent(
                        language.text(
                            "Root Page ID",
                            "Root Page ID"
                        ),
                        value: rootPageID
                    )

                    Button(
                        language.text(
                            "测试连接",
                            "接続をテスト"
                        )
                    ) {
                        Task {
                            await testConnection()
                        }
                    }
                    .disabled(isWorking)

                    Button(
                        language.text(
                            "同步此页面到本地",
                            "このページを同期"
                        )
                    ) {
                        Task {
                            await syncRootPage()
                        }
                    }
                    .disabled(isWorking)
                } header: {
                    Text(
                        language.text(
                            "连接测试",
                            "接続テスト"
                        )
                    )
                }
            }

            if let statusMessage {
                Section {
                    HStack(spacing: 10) {
                        if isWorking {
                            ProgressView()
                        }
                        Text(statusMessage)
                            .font(.subheadline)
                    }
                }
            }
        }
        .navigationTitle(
            language.text(
                "Notion 连接",
                "Notion接続"
            )
        )
        .onAppear {
            refreshCredentialState()
        }
    }

    private func saveToken() {
        let trimmed = tokenDraft.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        guard !trimmed.isEmpty else {
            return
        }

        do {
            try credentialStore.save(
                trimmed,
                account: KeychainCredentialStore.notionTokenAccount
            )
            tokenDraft = ""
            hasStoredToken = true
            statusMessage = language.text(
                "Token 已保存到 Keychain。",
                "TokenをKeychainに保存しました。"
            )
        } catch {
            statusMessage = language.text(
                "无法保存 Token。",
                "Tokenを保存できませんでした。"
            )
        }
    }

    private func deleteToken() {
        do {
            try credentialStore.delete(
                account: KeychainCredentialStore.notionTokenAccount
            )
            tokenDraft = ""
            hasStoredToken = false
            statusMessage = language.text(
                "已删除 Notion Token。",
                "Notion Tokenを削除しました。"
            )
        } catch {
            statusMessage = language.text(
                "无法删除 Token。",
                "Tokenを削除できませんでした。"
            )
        }
    }

    private func refreshCredentialState() {
        do {
            hasStoredToken = try credentialStore.read(
                account: KeychainCredentialStore.notionTokenAccount
            ) != nil
        } catch {
            hasStoredToken = false
        }
    }

    private func activeToken() throws -> String {
        let draft = tokenDraft.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        if !draft.isEmpty {
            return draft
        }

        if let stored = try credentialStore.read(
            account: KeychainCredentialStore.notionTokenAccount
        ),
        !stored.isEmpty {
            return stored
        }

        throw NotionConnectionUIError.missingToken
    }

    @MainActor
    private func searchPages() async {
        isWorking = true
        statusMessage = language.text(
            "正在搜索 Notion…",
            "Notionを検索中…"
        )
        defer { isWorking = false }

        do {
            let client = NotionAPIClient(
                token: try activeToken()
            )
            searchResults = try await client.searchPages(
                query: searchText
            )
            statusMessage = language.text(
                "找到 \(searchResults.count) 个页面。",
                "\(searchResults.count)件のページが見つかりました。"
            )
        } catch {
            statusMessage = connectionErrorMessage(error)
        }
    }

    @MainActor
    private func testConnection() async {
        isWorking = true
        statusMessage = language.text(
            "正在测试连接…",
            "接続をテスト中…"
        )
        defer { isWorking = false }

        do {
            let client = NotionAPIClient(
                token: try activeToken()
            )
            let page = try await client.retrievePage(
                id: rootPageID
            )
            statusMessage = language.text(
                "连接成功：\(page.title)",
                "接続成功：\(page.title)"
            )
        } catch {
            statusMessage = connectionErrorMessage(error)
        }
    }

    @MainActor
    private func syncRootPage() async {
        isWorking = true
        statusMessage = language.text(
            "正在同步 Notion 页面…",
            "Notionページを同期中…"
        )
        defer { isWorking = false }

        do {
            let client = NotionAPIClient(
                token: try activeToken()
            )
            let repository = LearningRepository(
                context: modelContext
            )
            let service = NotionImportService(
                repository: repository,
                client: client
            )
            let item = try await service.syncPage(
                id: rootPageID
            )

            statusMessage = language.text(
                "同步完成：\(item.title)",
                "同期完了：\(item.title)"
            )
        } catch {
            statusMessage = connectionErrorMessage(error)
        }
    }

    private func connectionErrorMessage(
        _ error: Error
    ) -> String {
        if case NotionConnectionUIError.missingToken = error {
            return language.text(
                "请先输入或保存 Notion Token。",
                "Notion Tokenを入力または保存してください。"
            )
        }

        if case let NotionAPIError.http(
            statusCode,
            message
        ) = error {
            return language.text(
                "Notion 返回错误 \(statusCode)：\(message)",
                "Notionエラー \(statusCode)：\(message)"
            )
        }

        return language.text(
            "Notion 连接失败。",
            "Notion接続に失敗しました。"
        )
    }
}

private enum NotionConnectionUIError: Error {
    case missingToken
}
