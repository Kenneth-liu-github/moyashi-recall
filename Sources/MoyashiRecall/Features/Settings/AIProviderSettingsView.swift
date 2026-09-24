import SwiftUI

public struct AIProviderSettingsView: View {
    @EnvironmentObject private var language: LanguageStore

    @State private var provider: AIProviderKind = .openAI
    @State private var modelID = ""
    @State private var apiKeyDraft = ""
    @State private var hasStoredCredential = false
    @State private var statusMessage: String?

    private let configurationStore = AIConfigurationStore()
    private let credentialStore = KeychainCredentialStore()

    public init() {}

    public var body: some View {
        Form {
            Section(
                language.text(
                    "AI Provider",
                    "AI Provider"
                )
            ) {
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
            }

            Section(
                language.text(
                    "安全凭证",
                    "安全な認証情報"
                )
            ) {
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
        .onChange(of: provider) { _, _ in
            refreshCredentialState()
        }
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
