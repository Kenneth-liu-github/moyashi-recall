import XCTest
@testable import MoyashiRecall

final class FSRSSchedulerTests: XCTestCase {
    func testUsesPublishedFSRS6DefaultParameters() {
        XCTAssertEqual(FSRSScheduler.defaultParameters.count, 21)
        XCTAssertEqual(FSRSScheduler.defaultParameters[0], 0.212, accuracy: 0.000001)
        XCTAssertEqual(FSRSScheduler.defaultParameters[20], 0.1542, accuracy: 0.000001)
    }

    func testInitialGoodMatchesFSRS6ReferenceMath() {
        let scheduler = FSRSScheduler()
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let result = scheduler.schedule(
            FSRSCardState(due: now),
            rating: .good,
            now: now
        )

        XCTAssertEqual(result.state.stability, 2.3065, accuracy: 0.000001)
        XCTAssertEqual(result.state.difficulty, 2.118103970459015, accuracy: 0.000001)
        XCTAssertEqual(result.scheduledDays, 2)
        XCTAssertEqual(result.state.state, .review)
    }

    func testFiveDayGoodReviewMatchesFSRS6ReferenceMath() {
        let scheduler = FSRSScheduler()
        let last = Date(timeIntervalSince1970: 1_700_000_000)
        let initial = scheduler.schedule(
            FSRSCardState(due: last),
            rating: .good,
            now: last
        )
        let now = last.addingTimeInterval(5 * 86_400)

        let result = scheduler.schedule(
            initial.state,
            rating: .good,
            now: now
        )

        XCTAssertEqual(result.elapsedDays, 5)
        XCTAssertEqual(result.state.stability, 18.16785023507094, accuracy: 0.000001)
        XCTAssertEqual(result.state.difficulty, 2.1112142357853942, accuracy: 0.000001)
        XCTAssertEqual(result.scheduledDays, 18)
    }

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

    func testSameDayGoodCannotReduceStability() {
        let scheduler = FSRSScheduler()
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let card = FSRSCardState(
            due: now,
            stability: 3,
            difficulty: 4,
            repetitions: 2,
            state: .review,
            lastReview: now
        )

        let result = scheduler.schedule(card, rating: .good, now: now)

        XCTAssertGreaterThanOrEqual(result.state.stability, card.stability)
    }

    func testRetrievabilityFallsAsTimePasses() {
        let scheduler = FSRSScheduler()
        let today = scheduler.retrievability(stability: 5, elapsedDays: 0)
        let later = scheduler.retrievability(stability: 5, elapsedDays: 10)

        XCTAssertEqual(today, 1, accuracy: 0.000001)
        XCTAssertGreaterThan(today, later)
    }

    func testStabilityMeansNinetyPercentRetrievability() {
        let scheduler = FSRSScheduler()
        let retrievability = scheduler.retrievability(
            stability: 10,
            elapsedDays: 10
        )

        XCTAssertEqual(retrievability, 0.9, accuracy: 0.000001)
    }
}
