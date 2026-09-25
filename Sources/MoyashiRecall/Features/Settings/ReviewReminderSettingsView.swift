import SwiftUI
import UserNotifications

public struct ReviewReminderSettingsView: View {
    @EnvironmentObject private var language: LanguageStore

    @State private var preferences = ReviewReminderPreferences()
    @State private var reminderTime = Date()
    @State private var statusMessage: String?
    @State private var isUpdating = false
    @State private var isLoadingPreferences = true

    private let store = ReviewReminderPreferencesStore()
    private let service = ReviewReminderService()

    public init() {}

    public var body: some View {
        Form {
            Section {
                Toggle(
                    language.text(
                        "每日复习提醒",
                        "毎日の復習リマインダー"
                    ),
                    isOn: $preferences.enabled
                )
                .disabled(isUpdating)
                .onChange(
                    of: preferences.enabled
                ) { _, enabled in
                    guard !isLoadingPreferences else {
                        return
                    }

                    Task {
                        await updateEnabled(
                            enabled
                        )
                    }
                }

                DatePicker(
                    language.text(
                        "提醒时间",
                        "通知時刻"
                    ),
                    selection: $reminderTime,
                    displayedComponents: .hourAndMinute
                )
                .disabled(
                    !preferences.enabled
                        || isUpdating
                )
                .onChange(
                    of: reminderTime
                ) { _, date in
                    guard !isLoadingPreferences else {
                        return
                    }
                    updateTime(date)
                }
            } footer: {
                Text(
                    language.text(
                        "提醒由 iPhone/iPad 本地通知发送。关闭后会取消已安排的每日提醒。",
                        "リマインダーはiPhone/iPadのローカル通知で送信されます。オフにすると予約済みの毎日通知はキャンセルされます。"
                    )
                )
            }

            if let statusMessage {
                Section {
                    HStack(spacing: 10) {
                        if isUpdating {
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
                "复习提醒",
                "復習リマインダー"
            )
        )
        .onAppear {
            loadPreferences()
        }
        .onChange(
            of: language.language
        ) { _, _ in
            guard preferences.enabled else {
                return
            }

            Task {
                await scheduleCurrentReminder()
            }
        }
    }

    private func loadPreferences() {
        isLoadingPreferences = true
        preferences = store.load()
        reminderTime = dateForPreferences(
            preferences
        )
        isLoadingPreferences = false

        Task {
            let status = await service.authorizationStatus()

            if preferences.enabled {
                if ReviewReminderService.isAuthorized(status) {
                    await scheduleCurrentReminder()
                } else {
                    setEnabledWithoutSideEffects(false)
                    service.cancelDailyReminder()
                    persistPreferences()
                    statusMessage = authorizationMessage(
                        status
                    )
                }
            } else {
                statusMessage = authorizationMessage(
                    status
                )
            }
        }
    }

    @MainActor
    private func updateEnabled(
        _ enabled: Bool
    ) async {
        isUpdating = true
        defer {
            isUpdating = false
        }

        if !enabled {
            service.cancelDailyReminder()
            persistPreferences()
            statusMessage = language.text(
                "每日提醒已关闭。",
                "毎日のリマインダーをオフにしました。"
            )
            return
        }

        do {
            let granted = try await service
                .requestAuthorization()

            guard granted else {
                setEnabledWithoutSideEffects(false)
                persistPreferences()
                statusMessage = language.text(
                    "通知权限未开启，因此无法启用提醒。",
                    "通知が許可されていないため、リマインダーを有効にできません。"
                )
                return
            }

            persistPreferences()
            try await scheduleCurrentReminder()
        } catch {
            setEnabledWithoutSideEffects(false)
            persistPreferences()
            statusMessage = language.text(
                "无法启用每日提醒。",
                "毎日のリマインダーを有効にできませんでした。"
            )
        }
    }

    private func setEnabledWithoutSideEffects(
        _ enabled: Bool
    ) {
        isLoadingPreferences = true
        preferences.enabled = enabled
        isLoadingPreferences = false
    }

    private func updateTime(
        _ date: Date
    ) {
        let components = Calendar.current
            .dateComponents(
                [.hour, .minute],
                from: date
            )
        preferences.hour = components.hour ?? 20
        preferences.minute = components.minute ?? 0
        persistPreferences()

        guard preferences.enabled else {
            return
        }

        Task {
            await scheduleCurrentReminder()
        }
    }

    @MainActor
    private func scheduleCurrentReminder() async {
        do {
            try await service.scheduleDaily(
                hour: preferences.hour,
                minute: preferences.minute,
                title: language.text(
                    "Moyashi Recall",
                    "Moyashi Recall"
                ),
                body: language.text(
                    "看看今天有哪些日语卡片到期了。",
                    "今日の期限カードを復習しましょう。"
                )
            )

            statusMessage = language.text(
                "每日提醒已安排在 \(timeText)。",
                "毎日のリマインダーを\(timeText)に設定しました。"
            )
        } catch {
            statusMessage = language.text(
                "无法安排每日提醒。",
                "毎日のリマインダーを設定できませんでした。"
            )
        }
    }

    private func persistPreferences() {
        do {
            try store.save(preferences)
        } catch {
            statusMessage = language.text(
                "无法保存提醒设置。",
                "リマインダー設定を保存できませんでした。"
            )
        }
    }

    private var timeText: String {
        reminderTime.formatted(
            date: .omitted,
            time: .shortened
        )
    }

    private func dateForPreferences(
        _ preferences: ReviewReminderPreferences
    ) -> Date {
        let calendar = Calendar.current
        let now = Date()
        return calendar.date(
            bySettingHour: preferences.hour,
            minute: preferences.minute,
            second: 0,
            of: now
        ) ?? now
    }

    private func authorizationMessage(
        _ status: UNAuthorizationStatus
    ) -> String {
        if ReviewReminderService.isAuthorized(status) {
            return language.text(
                "通知权限已开启。",
                "通知は許可されています。"
            )
        }

        switch status {
        case .denied:
            return language.text(
                "通知权限已关闭。需要在系统设置中重新开启后才能使用提醒。",
                "通知が無効です。使用するにはシステム設定で再度許可してください。"
            )
        case .notDetermined:
            return language.text(
                "启用提醒时会请求通知权限。",
                "リマインダーを有効にすると通知許可を求めます。"
            )
        default:
            return language.text(
                "无法确认通知权限状态。",
                "通知権限の状態を確認できません。"
            )
        }
    }
}
