import SwiftUI

public struct SettingsView: View {
    @EnvironmentObject private var language: LanguageStore
    @EnvironmentObject private var notionMonitor:
        NotionConnectionMonitor

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
                        LabeledContent {
                            VStack(
                                alignment: .trailing,
                                spacing: 3
                            ) {
                                HStack(spacing: 6) {
                                    if notionMonitor.status
                                        == .checking {
                                        ProgressView()
                                            .controlSize(.small)
                                    } else {
                                        Circle()
                                            .fill(
                                                notionStatusColor
                                            )
                                            .frame(
                                                width: 8,
                                                height: 8
                                            )
                                    }

                                    Text(
                                        notionStatusText
                                    )
                                    .foregroundStyle(
                                        notionStatusColor
                                    )
                                }

                                if let checkedAt =
                                    notionMonitor
                                        .lastCheckedAt {
                                    Text(
                                        language.text(
                                            "最近检查 ",
                                            "最終確認 "
                                        )
                                        + checkedAt.formatted(
                                            date: .omitted,
                                            time: .shortened
                                        )
                                    )
                                    .font(.caption2)
                                    .foregroundStyle(
                                        AppTheme.muted
                                    )
                                }
                            }
                        } label: {
                            Text("Notion")
                        }
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

    private var notionStatusText: String {
        switch notionMonitor.status {
        case .unconfigured:
            return language.text(
                "未配置",
                "未設定"
            )

        case .checking:
            return language.text(
                "检查中",
                "確認中"
            )

        case .connected:
            return language.text(
                "已连接",
                "接続済み"
            )

        case .disconnected:
            return language.text(
                "连接失败",
                "接続失敗"
            )
        }
    }

    private var notionStatusColor: Color {
        switch notionMonitor.status {
        case .unconfigured:
            return .secondary

        case .checking:
            return .secondary

        case .connected:
            return .green

        case .disconnected:
            return .red
        }
    }
}


// MARK: - Notion Connection Monitor

public enum NotionMonitorStatus:
    Equatable {
    case unconfigured
    case checking
    case connected
    case disconnected
}

@MainActor
public final class NotionConnectionMonitor:
    ObservableObject {

    @Published public private(set)
    var status:
        NotionMonitorStatus = .unconfigured

    @Published public private(set)
    var lastCheckedAt: Date?

    @Published public private(set)
    var detail: String?

    private let profileStore =
        NotionConfigurationProfileStore()

    private let credentialStore =
        KeychainCredentialStore()

    private var isChecking = false

    public init() {}

    public func checkNow() async {
        guard !isChecking else {
            return
        }

        guard
            let profile =
                profileStore.activeProfile()
        else {
            status = .unconfigured
            lastCheckedAt = nil
            detail = nil
            return
        }

        isChecking = true
        status = .checking

        defer {
            isChecking = false
            lastCheckedAt = .now
        }

        do {
            guard
                let token =
                    try credentialStore.read(
                        account:
                            profile
                                .credentialAccount
                    ),
                !token
                    .trimmingCharacters(
                        in:
                            .whitespacesAndNewlines
                    )
                    .isEmpty
            else {
                status = .disconnected
                detail =
                    "Notion Token 未配置。"
                return
            }

            let client =
                NotionAPIClient(
                    token: token
                )

            let page =
                try await client
                    .retrievePage(
                        id:
                            profile.rootPageID
                    )

            let title =
                page.title
                    .trimmingCharacters(
                        in:
                            .whitespacesAndNewlines
                    )

            guard
                title.localizedCaseInsensitiveCompare(
                    "Learning Home"
                ) == .orderedSame
            else {
                status = .disconnected
                detail =
                    "当前 Root Page 不是 Learning Home。"
                return
            }

            status = .connected
            detail = nil

        } catch let apiError
            as NotionAPIError {

            status = .disconnected

            if case let .http(
                statusCode,
                _
            ) = apiError {
                switch statusCode {
                case 401:
                    detail =
                        "Notion Token 无效或已失效（HTTP 401）。"

                case 403:
                    detail =
                        "当前 Integration 无权访问 Learning Home（HTTP 403）。"

                case 404:
                    detail =
                        "Learning Home 不存在或未共享给 Integration（HTTP 404）。"

                case 429:
                    detail =
                        "Notion API 请求过于频繁（HTTP 429）。"

                case 500...599:
                    detail =
                        "Notion 服务暂时异常（HTTP \\(statusCode)）。"

                default:
                    detail =
                        "Notion API 请求失败（HTTP \\(statusCode)）。"
                }
            } else {
                detail =
                    "Notion API 连接失败。"
            }

        } catch {
            status = .disconnected

            let nsError =
                error as NSError

            if nsError.domain
                == NSURLErrorDomain {
                detail =
                    "Notion 网络错误（\\(nsError.code)）。"
            } else {
                detail =
                    "Notion 连接测试失败。"
            }
        }
    }
}
