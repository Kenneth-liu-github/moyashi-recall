import XCTest
@testable import MoyashiRecall

final class FSRSSchedulerTests: XCTestCase {
    func testNewCardIntervalsIncreaseWithRating() {
        let scheduler = FSRSScheduler()
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let card = FSRSCardState(due: now)

        let again = scheduler.schedule(card, rating: .again, now: now)
        let hard = scheduler.schedule(card, rating: .hard, now: now)
        let good = scheduler.schedule(card, rating: .good, now: now)
        let easy = scheduler.schedule(card, rating: .easy, now: now)

        XCTAssertLessThanOrEqual(again.scheduledDays, hard.scheduledDays)
        XCTAssertLessThan(hard.scheduledDays, good.scheduledDays)
        XCTAssertLessThan(good.scheduledDays, easy.scheduledDays)
    }

    func testAgainIncrementsLapsesForReviewedCard() {
        let scheduler = FSRSScheduler()
        let last = Date(timeIntervalSince1970: 1_700_000_000)
        let now = last.addingTimeInterval(5 * 86_400)
        let card = FSRSCardState(
            due: last,
            stability: 5,
            difficulty: 5,
            repetitions: 3,
            lapses: 0,
            state: .review,
            lastReview: last
        )

        let result = scheduler.schedule(card, rating: .again, now: now)

        XCTAssertEqual(result.state.lapses, 1)
        XCTAssertEqual(result.state.state, .relearning)
        XCTAssertEqual(result.elapsedDays, 5)
        XCTAssertLessThan(result.state.stability, card.stability)
    }

    func testRetrievabilityFallsAsTimePasses() {
        let scheduler = FSRSScheduler()
        let today = scheduler.retrievability(stability: 5, elapsedDays: 0)
        let later = scheduler.retrievability(stability: 5, elapsedDays: 10)
        XCTAssertGreaterThan(today, later)
    }
}
