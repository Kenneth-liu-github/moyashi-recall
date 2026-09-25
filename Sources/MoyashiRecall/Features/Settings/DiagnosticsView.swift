import SwiftUI
import SwiftData

public struct DiagnosticsView: View {
    @EnvironmentObject private var language: LanguageStore
    @Environment(\.modelContext) private var modelContext

    @State private var snapshot: AppReadinessSnapshot?
    @State private var loadError: String?

    public init() {}

    public var body: some View {
        Form {
            if let snapshot {
                Section(
                    language.text(
                        "就绪状态",
                        "準備状況"
                    )
                ) {
                    statusRow(
                        language.text(
                            "Notion Token",
                            "Notion Token"
                        ),
                        ready: snapshot.notionCredentialConfigured
                    )
                    statusRow(
                        language.text(
                            "Notion 根页面",
                            "Notionルートページ"
                        ),
                        ready: snapshot.notionRootSelected
                    )
                    LabeledContent(
                        language.text(
                            "已同步页面",
                            "同期済みページ"
                        ),
                        value: "\(snapshot.syncedDocumentCount)"
                    )

                    statusRow(
                        language.text(
                            "AI 模型",
                            "AIモデル"
                        ),
                        ready: snapshot.aiModelConfigured,
                        detail: snapshot.aiProviderName
                    )
                    statusRow(
                        language.text(
                            "AI 凭证",
                            "AI認証情報"
                        ),
                        ready: snapshot.aiCredentialConfigured
                    )
                    LabeledContent(
                        language.text(
                            "知识点",
                            "知識項目"
                        ),
                        value: "\(snapshot.activeKnowledgeCount)"
                    )
                    LabeledContent(
                        language.text(
                            "可复习卡片",
                            "復習可能カード"
                        ),
                        value: "\(snapshot.activeCardCount)"
                    )
                    LabeledContent(
                        language.text(
                            "当前到期",
                            "現在の期限カード"
                        ),
                        value: "\(snapshot.dueCardCount)"
                    )
                    LabeledContent(
                        language.text(
                            "复习记录",
                            "復習履歴"
                        ),
                        value: "\(snapshot.reviewHistoryCount)"
                    )

                    if let latestReviewAt = snapshot.latestReviewAt {
                        LabeledContent(
                            language.text(
                                "最近复习",
                                "最終復習"
                            ),
                            value: latestReviewAt.formatted(
                                date: .abbreviated,
                                time: .shortened
                            )
                        )
                    }
                }

                Section(
                    language.text(
                        "整体状态",
                        "全体ステータス"
                    )
                ) {
                    statusRow(
                        language.text(
                            "资料源",
                            "資料ソース"
                        ),
                        ready: snapshot.notionReady
                    )
                    statusRow(
                        "AI",
                        ready: snapshot.aiReady
                    )
                    statusRow(
                        language.text(
                            "复习系统",
                            "復習システム"
                        ),
                        ready: snapshot.readyForReview
                    )
                }

                Section(
                    language.text(
                        "App",
                        "App"
                    )
                ) {
                    LabeledContent(
                        language.text(
                            "版本",
                            "バージョン"
                        ),
                        value: appVersion
                    )
                    LabeledContent(
                        language.text(
                            "Build",
                            "Build"
                        ),
                        value: appBuild
                    )
                }

                if !snapshot.notionReady {
                    Section {
                        NavigationLink {
                            NotionConnectionView()
                        } label: {
                            Label(
                                language.text(
                                    "完成 Notion 配置",
                                    "Notion設定を完了"
                                ),
                                systemImage: "arrow.right.circle"
                            )
                        }
                    }
                }

                if !snapshot.aiReady {
                    Section {
                        NavigationLink {
                            AIProviderSettingsView()
                        } label: {
                            Label(
                                language.text(
                                    "完成 AI 配置",
                                    "AI設定を完了"
                                ),
                                systemImage: "arrow.right.circle"
                            )
                        }
                    }
                }
            } else if let loadError {
                ContentUnavailableView(
                    language.text(
                        "无法读取系统状态",
                        "システム状態を読み込めません"
                    ),
                    systemImage: "exclamationmark.triangle",
                    description: Text(loadError)
                )
            } else {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
            }
        }
        .navigationTitle(
            language.text(
                "系统状态",
                "システム状態"
            )
        )
        .onAppear {
            loadSnapshot()
        }
    }

    @ViewBuilder
    private func statusRow(
        _ title: String,
        ready: Bool,
        detail: String? = nil
    ) -> some View {
        HStack {
            VStack(
                alignment: .leading,
                spacing: 2
            ) {
                Text(title)
                if let detail,
                   !detail.isEmpty {
                    Text(detail)
                        .font(.caption)
                        .foregroundStyle(AppTheme.muted)
                }
            }

            Spacer()

            Label(
                ready
                    ? language.text(
                        "就绪",
                        "準備完了"
                    )
                    : language.text(
                        "待配置",
                        "未設定"
                    ),
                systemImage: ready
                    ? "checkmark.circle.fill"
                    : "circle"
            )
            .font(.caption.weight(.semibold))
            .foregroundStyle(
                ready
                    ? AppTheme.accent
                    : AppTheme.muted
            )
        }
    }

    private var appVersion: String {
        Bundle.main.object(
            forInfoDictionaryKey: "CFBundleShortVersionString"
        ) as? String ?? "—"
    }

    private var appBuild: String {
        Bundle.main.object(
            forInfoDictionaryKey: "CFBundleVersion"
        ) as? String ?? "—"
    }

    private func loadSnapshot() {
        do {
            snapshot = try AppReadinessService(
                context: modelContext
            ).snapshot()
            loadError = nil
        } catch {
            snapshot = nil
            loadError = language.text(
                "无法读取本地配置或学习数据。",
                "ローカル設定または学習データを読み込めませんでした。"
            )
        }
    }
}
