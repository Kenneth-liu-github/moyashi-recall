import Foundation
import SwiftData

@MainActor
public struct ReviewQueueService {
    public init() {}

    public func dueCards(
        in context: ModelContext,
        now: Date = .now,
        limit: Int? = nil
    ) throws -> [FlashcardEntity] {
        let cards = try context.fetch(
            FetchDescriptor<FlashcardEntity>(
                sortBy: [SortDescriptor(\.createdAt, order: .forward)]
            )
        )
        let states = try context.fetch(
            FetchDescriptor<ReviewStateEntity>(
                sortBy: [SortDescriptor(\.due, order: .forward)]
            )
        )

        let stateByCard = Dictionary(uniqueKeysWithValues: states.map { ($0.cardID, $0) })

        let due = cards.filter { card in
            guard let state = stateByCard[card.id] else { return true }
            return state.due <= now
        }
        .sorted { lhs, rhs in
            let lhsState = stateByCard[lhs.id]
            let rhsState = stateByCard[rhs.id]

            switch (lhsState, rhsState) {
            case (nil, nil):
                return lhs.createdAt < rhs.createdAt
            case (nil, _):
                return true
            case (_, nil):
                return false
            case let (l?, r?):
                return l.due < r.due
            }
        }

        guard let limit else { return due }
        return Array(due.prefix(max(0, limit)))
    }
}
