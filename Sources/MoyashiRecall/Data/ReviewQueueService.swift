import Foundation
import SwiftData

@MainActor
public struct ReviewQueueService {
    public init() {}

    public func dueCards(
        in context: ModelContext,
        now: Date = .now,
        sourceKeys: Set<String>? = nil,
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

        let stateByCard = states.reduce(into: [UUID: ReviewStateEntity]()) { result, state in
            if let existing = result[state.cardID] {
                if state.due < existing.due { result[state.cardID] = state }
            } else {
                result[state.cardID] = state
            }
        }

        let due = cards.filter { card in
            if let sourceKeys, !sourceKeys.isEmpty, !sourceKeys.contains(card.sourceKey) {
                return false
            }

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
                return false
            case (_, nil):
                return true
            case let (l?, r?):
                return l.due < r.due
            }
        }

        guard let limit else { return due }
        return Array(due.prefix(max(0, limit)))
    }
}
