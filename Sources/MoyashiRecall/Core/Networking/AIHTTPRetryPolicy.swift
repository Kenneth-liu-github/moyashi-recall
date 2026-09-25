import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public enum AIHTTPRetryPolicy {
    public static let retryableStatusCodes: Set<Int> = [
        408,
        429,
        500,
        502,
        503,
        504
    ]

    public static func shouldRetry(
        statusCode: Int,
        attempt: Int,
        maximumRetries: Int
    ) -> Bool {
        attempt < maximumRetries
            && retryableStatusCodes.contains(statusCode)
    }

    public static func delaySeconds(
        response: HTTPURLResponse,
        attempt: Int
    ) -> Double {
        if let raw = response.value(
            forHTTPHeaderField: "Retry-After"
        ),
        let seconds = Double(raw),
        seconds >= 0 {
            return min(seconds, 60)
        }

        let exponent = max(0, min(attempt, 3))
        let seconds = Double(1 << exponent)
        return min(seconds, 8)
    }
}
