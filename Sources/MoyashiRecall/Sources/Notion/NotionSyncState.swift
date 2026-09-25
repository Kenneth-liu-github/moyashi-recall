import Foundation

public struct NotionSyncState: Codable, Equatable, Sendable {
    public let rootPageID: String
    public let lastSyncedAt: Date
    public let totalPages: Int
    public let inserted: Int
    public let updated: Int
    public let unchanged: Int
    public let deactivated: Int
    public let isComplete: Bool

    public init(
        rootPageID: String,
        lastSyncedAt: Date,
        report: NotionSyncReport
    ) {
        self.rootPageID = rootPageID
        self.lastSyncedAt = lastSyncedAt
        self.totalPages = report.totalPages
        self.inserted = report.inserted
        self.updated = report.updated
        self.unchanged = report.unchanged
        self.deactivated = report.deactivated
        self.isComplete = report.isComplete
    }
}

public struct NotionSyncStateStore {
    private static let key = "notionSyncState"

    public init() {}

    public func save(
        _ state: NotionSyncState,
        defaults: UserDefaults = .standard
    ) throws {
        let data = try JSONEncoder().encode(state)
        defaults.set(data, forKey: Self.key)
    }

    public func load(
        defaults: UserDefaults = .standard
    ) throws -> NotionSyncState? {
        guard let data = defaults.data(forKey: Self.key) else {
            return nil
        }
        return try JSONDecoder().decode(
            NotionSyncState.self,
            from: data
        )
    }

    public func clear(
        defaults: UserDefaults = .standard
    ) {
        defaults.removeObject(forKey: Self.key)
    }
}
