import SwiftUI

public struct SettingsView: View {
    @EnvironmentObject private var language: LanguageStore

    public init() {}

    public var body: some View {
        NavigationStack {
            Form {
                Section(language.text("界面", "インターフェース")) {
                    Picker(
                        language.text("界面语言", "表示言語"),
                        selection: $language.language
                    ) {
                        ForEach(AppLanguage.allCases) { item in
                            Text(item.displayName).tag(item)
                        }
                    }
                }

                Section(language.text("连接", "接続")) {
                    NavigationLink {
                        NotionConnectionView()
                    } label: {
                        LabeledContent(
                            "Notion",
                            value: language.text(
                                "配置与同步",
                                "設定と同期"
                            )
                        )
                    }

                    NavigationLink {
                        AIProviderSettingsView()
                    } label: {
                        LabeledContent(
                            "AI",
                            value: language.text(
                                "Provider 与模型",
                                "Providerとモデル"
                            )
                        )
                    }
                }

                Section(
                    language.text(
                        "状态",
                        "ステータス"
                    )
                ) {
                    NavigationLink {
                        DiagnosticsView()
                    } label: {
                        LabeledContent(
                            language.text(
                                "系统状态",
                                "システム状態"
                            ),
                            value: language.text(
                                "配置与数据检查",
                                "設定とデータ確認"
                            )
                        )
                    }
                }

                Section(
                    language.text(
                        "数据",
                        "データ"
                    )
                ) {
                    NavigationLink {
                        DataExportView()
                    } label: {
                        LabeledContent(
                            language.text(
                                "导出学习数据",
                                "学習データを書き出す"
                            ),
                            value: "JSON"
                        )
                    }
                }

                Section(
                    language.text(
                        "复习",
                        "復習"
                    )
                ) {
                    NavigationLink {
                        ReviewReminderSettingsView()
                    } label: {
                        LabeledContent(
                            language.text(
                                "每日提醒",
                                "毎日のリマインダー"
                            ),
                            value: language.text(
                                "通知设置",
                                "通知設定"
                            )
                        )
                    }

                    NavigationLink {
                        SpeechSettingsView()
                    } label: {
                        LabeledContent(
                            language.text(
                                "日语朗读",
                                "日本語読み上げ"
                            ),
                            value: language.text(
                                "语速与自动朗读",
                                "速度と自動読み上げ"
                            )
                        )
                    }

                    LabeledContent(
                        "FSRS",
                        value: "FSRS-6 · 90%"
                    )
                }
            }
            .navigationTitle(language.text("设置", "設定"))
        }
    }
}
