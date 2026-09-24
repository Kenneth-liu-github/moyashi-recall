import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public protocol HTTPTransport: Sendable {
    func data(
        for request: URLRequest
    ) async throws -> (Data, URLResponse)
}

public struct URLSessionHTTPTransport: HTTPTransport {
    public init() {}

    public func data(
        for request: URLRequest
    ) async throws -> (Data, URLResponse) {
        try await URLSession.shared.data(for: request)
    }
}
