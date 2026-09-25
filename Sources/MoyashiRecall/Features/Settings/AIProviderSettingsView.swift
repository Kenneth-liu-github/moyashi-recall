import SwiftUI

public struct AIProviderSettingsView: View {
    @EnvironmentObject private var language: LanguageStore

    @State private var provider: AIProviderKind = .openAI
    @State private var modelID = ""
    @State private var apiKeyDraft = ""
    @State private var hasStoredCredential = false
    @State private var statusMessage: String?
    @State private var isTestingConnection = false

    private let configurationStore = AIConfigurationStore()
    private let credentialStore = KeychainCredentialStore()

    public init() {}

    public var body: some View {
        Form {
            Section {
                Picker(
                    language.text(
                        "Provider",
                        "Provider"
                    ),
                    selection: $provider
                ) {
                    ForEach(AIProviderKind.allCases) { item in
                        Text(item.displayName)
                            .tag(item)
                    }
                }

                TextField(
                    language.text(
                        "模型 ID",
                        "モデルID"
                    ),
                    text: $modelID
                )
            } header: {
                Text(
                    language.text(
                        "AI Provider",
                        "AI Provider"
                    )
                )
            }

            Section {
                SecureField(
                    language.text(
                        "API Key",
                        "API Key"
                    ),
                    text: $apiKeyDraft
                )

                LabeledContent(
                    language.text(
                        "凭证状态",
                        "認証情報"
                    ),
                    value: hasStoredCredential
                        ? language.text(
                            "已安全保存",
                            "保存済み"
                        )
                        : language.text(
                            "未配置",
                            "未設定"
                        )
                )

                if hasStoredCredential {
                    Button(
                        language.text(
                            "删除 API Key",
                            "API Keyを削除"
                        ),
                        role: .destructive
                    ) {
                        deleteCredential()
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
                        "API Key 仅保存在 Apple Keychain。模型 ID 与 Provider 选择不属于敏感信息，保存在本机设置中。",
                        "API KeyはApple Keychainのみに保存されます。モデルIDとProvider選択は端末設定に保存されます。"
                    )
                )
            }

            Section {
                Button(
                    language.text(
                        "保存 AI 配置",
                        "AI設定を保存"
                    )
                ) {
                    saveConfiguration()
                }
                .disabled(
                    modelID
                        .trimmingCharacters(
                            in: .whitespacesAndNewlines
                        )
                        .isEmpty
                )

                Button {
                    Task {
                        await testConnection()
                    }
                } label: {
                    HStack {
                        if isTestingConnection {
                            ProgressView()
                        }
                        Text(
                            language.text(
                                "测试 AI 连接",
                                "AI接続をテスト"
                            )
                        )
                    }
                }
                .disabled(
                    isTestingConnection
                        || !hasUsableCredential
                        || modelID.trimmingCharacters(
                            in: .whitespacesAndNewlines
                        ).isEmpty
                )
            } footer: {
                Text(
                    language.text(
                        "使用 AI 生成功能时，所选资料页面的文本会发送给你配置的 AI Provider 进行处理。",
                        "AI生成を使用すると、選択した資料ページのテキストが設定したAI Providerへ送信されます。"
                    )
                )
            }

            if let statusMessage {
                Section {
                    Text(statusMessage)
                        .font(.subheadline)
                }
            }
        }
        .navigationTitle(
            language.text(
                "AI 设置",
                "AI設定"
            )
        )
        .onAppear {
            loadConfiguration()
        }
        .onChange(of: provider) { _, newProvider in
            modelID = configurationStore.modelID(
                for: newProvider
            )
            apiKeyDraft = ""
            statusMessage = nil
            refreshCredentialState()
        }
    }

    private var hasUsableCredential: Bool {
        hasStoredCredential
            || !apiKeyDraft.trimmingCharacters(
                in: .whitespacesAndNewlines
            ).isEmpty
    }

    private func loadConfiguration() {
        let configuration = configurationStore.load()
        provider = configuration.provider
        modelID = configuration.modelID
        refreshCredentialState()
    }

    private func refreshCredentialState() {
        do {
            hasStoredCredential = try credentialStore.read(
                account: AICredential.account(
                    for: provider
                )
            ) != nil
        } catch {
            hasStoredCredential = false
        }
    }

    private func saveConfiguration() {
        do {
            let trimmedModel = modelID
                .trimmingCharacters(
                    in: .whitespacesAndNewlines
                )
            try configurationStore.save(
                AIProviderConfiguration(
                    provider: provider,
                    modelID: trimmedModel
                )
            )

            let trimmedKey = apiKeyDraft
                .trimmingCharacters(
                    in: .whitespacesAndNewlines
                )
            if !trimmedKey.isEmpty {
                try credentialStore.save(
                    trimmedKey,
                    account: AICredential.account(
                        for: provider
                    )
                )
                apiKeyDraft = ""
            }

            refreshCredentialState()
            statusMessage = language.text(
                "AI 配置已保存。",
                "AI設定を保存しました。"
            )
        } catch {
            statusMessage = language.text(
                "无法保存 AI 配置。",
                "AI設定を保存できませんでした。"
            )
        }
    }

    @MainActor
    private func testConnection() async {
        isTestingConnection = true
        statusMessage = language.text(
            "正在测试 AI 连接…",
            "AI接続をテスト中…"
        )
        defer {
            isTestingConnection = false
        }

        do {
            let configuration = AIProviderConfiguration(
                provider: provider,
                modelID: modelID
            )
            let provider = try AIProviderFactory.makeProvider(
                configuration: configuration,
                secret: try activeSecret()
            )

            let response = try await provider.complete(
                request: AICompletionRequest(
                    systemPrompt: "Return the requested JSON only.",
                    userPrompt: "Set ok to true.",
                    responseSchemaName: "connection_probe",
                    responseSchemaJSON: """
                    {
                      "type": "object",
                      "properties": {
                        "ok": {
                          "type": "boolean"
                        }
                      },
                      "required": ["ok"],
                      "additionalProperties": false
                    }
                    """
                )
            )

            guard
                let data = response.text.data(
                    using: .utf8
                ),
                let probe = try? JSONDecoder().decode(
                    AIConnectionProbe.self,
                    from: data
                ),
                probe.ok
            else {
                throw AIProviderError.invalidResponse
            }

            statusMessage = language.text(
                "连接成功：\(response.providerID) · \(response.modelID)",
                "接続成功：\(response.providerID) · \(response.modelID)"
            )
        } catch let error as AIProviderError {
            switch error {
            case let .missingConfiguration(field):
                statusMessage = language.text(
                    "AI 配置不完整：\(field)。",
                    "AI設定が不完全です：\(field)。"
                )
            case let .http(statusCode, message):
                statusMessage = language.text(
                    "AI Provider 返回错误 \(statusCode)：\(message)",
                    "AI Provider エラー \(statusCode)：\(message)"
                )
            case let .refused(message):
                statusMessage = language.text(
                    "AI 拒绝了连接测试：\(message)",
                    "AIが接続テストを拒否しました：\(message)"
                )
            case let .incomplete(reason):
                statusMessage = language.text(
                    "AI 连接测试输出未完成：\(reason)。",
                    "AI接続テストの出力が未完了です：\(reason)。"
                )
            case .invalidResponse, .decodingFailed:
                statusMessage = language.text(
                    "AI 返回的数据格式无效。",
                    "AIの応答形式が無効です。"
                )
            }
        } catch {
            statusMessage = language.text(
                "AI 连接测试失败。",
                "AI接続テストに失敗しました。"
            )
        }
    }

    private func activeSecret() throws -> String {
        let draft = apiKeyDraft.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        if !draft.isEmpty {
            return draft
        }

        let account = AICredential.account(
            for: provider
        )
        if let stored = try credentialStore.read(
            account: account
        ),
        !stored.trimmingCharacters(
            in: .whitespacesAndNewlines
        ).isEmpty {
            return stored
        }

        throw AIProviderError.missingConfiguration(
            "\(provider.displayName) API key"
        )
    }

    private func deleteCredential() {
        do {
            try credentialStore.delete(
                account: AICredential.account(
                    for: provider
                )
            )
            apiKeyDraft = ""
            hasStoredCredential = false
            statusMessage = language.text(
                "API Key 已删除。",
                "API Keyを削除しました。"
            )
        } catch {
            statusMessage = language.text(
                "无法删除 API Key。",
                "API Keyを削除できませんでした。"
            )
        }
    }
}


private struct AIConnectionProbe: Decodable {
    let ok: Bool
}
