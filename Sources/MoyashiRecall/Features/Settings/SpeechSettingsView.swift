import SwiftUI

public struct SpeechSettingsView: View {
    @EnvironmentObject private var language: LanguageStore

    @State private var preferences =
        JapaneseSpeechPreferencesStore().load()
    @State private var statusMessage: String?

    private let store = JapaneseSpeechPreferencesStore()

    public init() {}

    public var body: some View {
        Form {
            Section {
                Picker(
                    language.text(
                        "语速",
                        "読み上げ速度"
                    ),
                    selection: $preferences.rate
                ) {
                    ForEach(
                        JapaneseSpeechRate.allCases
                    ) { rate in
                        Text(rateLabel(rate))
                            .tag(rate)
                    }
                }

                Toggle(
                    language.text(
                        "显示答案后自动朗读",
                        "答え表示後に自動読み上げ"
                    ),
                    isOn: $preferences.autoPlayAnswer
                )
            } header: {
                Text(
                    language.text(
                        "日语朗读",
                        "日本語読み上げ"
                    )
                )
            } footer: {
                Text(
                    language.text(
                        "朗读时会自动去掉漢字（かんじ）后的假名注音，避免把同一个词读两遍。",
                        "読み上げ時は漢字（かんじ）の後のふりがなを自動的に除き、同じ語を二重に読まないようにします。"
                    )
                )
            }

            if let statusMessage {
                Section {
                    Text(statusMessage)
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.muted)
                }
            }
        }
        .navigationTitle(
            language.text(
                "日语朗读",
                "日本語読み上げ"
            )
        )
        .onChange(of: preferences) { _, newValue in
            do {
                try store.save(newValue)
                statusMessage = language.text(
                    "朗读设置已保存。",
                    "読み上げ設定を保存しました。"
                )
            } catch {
                statusMessage = language.text(
                    "无法保存朗读设置。",
                    "読み上げ設定を保存できませんでした。"
                )
            }
        }
    }

    private func rateLabel(
        _ rate: JapaneseSpeechRate
    ) -> String {
        switch rate {
        case .slow:
            return language.text(
                "慢",
                "遅い"
            )
        case .normal:
            return language.text(
                "标准",
                "標準"
            )
        case .fast:
            return language.text(
                "快",
                "速い"
            )
        }
    }
}
