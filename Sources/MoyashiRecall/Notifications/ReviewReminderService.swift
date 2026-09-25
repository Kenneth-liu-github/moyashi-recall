import Foundation
#if canImport(UserNotifications)
import UserNotifications

@MainActor
public final class ReviewReminderService {
    public static let requestIdentifier = "daily-review-reminder"

    private let center: UNUserNotificationCenter

    public init(
        center: UNUserNotificationCenter = .current()
    ) {
        self.center = center
    }

    public func authorizationStatus() async -> UNAuthorizationStatus {
        await center.notificationSettings()
            .authorizationStatus
    }

    public func isAuthorized() async -> Bool {
        Self.isAuthorized(
            await authorizationStatus()
        )
    }

    public static func isAuthorized(
        _ status: UNAuthorizationStatus
    ) -> Bool {
        if status == .authorized
            || status == .provisional {
            return true
        }

        #if os(iOS)
        if status == .ephemeral {
            return true
        }
        #endif

        return false
    }

    public func requestAuthorization() async throws -> Bool {
        try await center.requestAuthorization(
            options: [.alert, .sound]
        )
    }

    public func scheduleDaily(
        hour: Int,
        minute: Int,
        title: String,
        body: String
    ) async throws {
        center.removePendingNotificationRequests(
            withIdentifiers: [Self.requestIdentifier]
        )

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        var components = DateComponents()
        components.hour = min(max(hour, 0), 23)
        components.minute = min(max(minute, 0), 59)

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: components,
            repeats: true
        )
        let request = UNNotificationRequest(
            identifier: Self.requestIdentifier,
            content: content,
            trigger: trigger
        )

        try await center.add(request)
    }

    public func cancelDailyReminder() {
        center.removePendingNotificationRequests(
            withIdentifiers: [Self.requestIdentifier]
        )
    }
}
#endif
