import XCTest
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
@testable import MoyashiRecall

final class AIHTTPRetryPolicyTests: XCTestCase {
    func testRetriesRateLimitsAndTransientServerFailures() {
        for status in [408, 429, 500, 502, 503, 504] {
            XCTAssertTrue(
                AIHTTPRetryPolicy.shouldRetry(
                    statusCode: status,
                    attempt: 0,
                    maximumRetries: 2
                )
            )
        }

        XCTAssertFalse(
            AIHTTPRetryPolicy.shouldRetry(
                statusCode: 401,
                attempt: 0,
                maximumRetries: 2
            )
        )
        XCTAssertFalse(
            AIHTTPRetryPolicy.shouldRetry(
                statusCode: 503,
                attempt: 2,
                maximumRetries: 2
            )
        )
    }

    func testRetryAfterHeaderOverridesBackoff() throws {
        let url = try XCTUnwrap(
            URL(string: "https://example.test")
        )
        let response = try XCTUnwrap(
            HTTPURLResponse(
                url: url,
                statusCode: 429,
                httpVersion: nil,
                headerFields: ["Retry-After": "0"]
            )
        )

        XCTAssertEqual(
            AIHTTPRetryPolicy.delaySeconds(
                response: response,
                attempt: 2
            ),
            0
        )
    }

    func testBackoffIsBoundedWhenHeaderMissing() throws {
        let url = try XCTUnwrap(
            URL(string: "https://example.test")
        )
        let response = try XCTUnwrap(
            HTTPURLResponse(
                url: url,
                statusCode: 503,
                httpVersion: nil,
                headerFields: nil
            )
        )

        XCTAssertEqual(
            AIHTTPRetryPolicy.delaySeconds(
                response: response,
                attempt: 0
            ),
            1
        )
        XCTAssertEqual(
            AIHTTPRetryPolicy.delaySeconds(
                response: response,
                attempt: 3
            ),
            8
        )
    }
}
