import Foundation

public enum NotionAPIError: Error, Equatable {
    case invalidResponse
    case httpStatus(Int)
    case missingTitle
}

public struct NotionConfiguration: Sendable {
    public let token: String
    public let apiVersion: String
    public let baseURL: URL

    public init(
        token: String,
        apiVersion: String = "2022-06-28",
        baseURL: URL = URL(string: "https://api.notion.com/v1")!
    ) {
        self.token = token
        self.apiVersion = apiVersion
        self.baseURL = baseURL
    }
}

public protocol HTTPTransport: Sendable {
    func data(for request: URLRequest) async throws -> (Data, HTTPURLResponse)
}

public struct URLSessionTransport: HTTPTransport {
    public init() {}

    public func data(for request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw NotionAPIError.invalidResponse
        }
        return (data, http)
    }
}

public struct NotionContentSourceService<Transport: HTTPTransport>: ContentSourceService {
    private let configuration: NotionConfiguration
    private let transport: Transport
    private let decoder: JSONDecoder

    public init(configuration: NotionConfiguration, transport: Transport) {
        self.configuration = configuration
        self.transport = transport
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        self.decoder = decoder
    }

    public func fetchDocument(id: String) async throws -> SourceDocument {
        async let page = fetchPage(id: id)
        async let blocks = fetchAllBlockChildren(id: id)

        let (pageValue, blockValues) = try await (page, blocks)
        let title = pageValue.title ?? "Untitled"
        let text = blockValues
            .compactMap(\.plainText)
            .filter { !$0.isEmpty }
            .joined(separator: "\n")

        return SourceDocument(
            id: pageValue.id,
            sourceKind: .notion,
            title: title,
            parentID: pageValue.parent.parentID,
            path: [title],
            plainText: text,
            sourceReference: "Notion · \(title)",
            lastEditedAt: pageValue.lastEditedTime
        )
    }

    private func fetchPage(id: String) async throws -> NotionPageResponse {
        var request = URLRequest(url: configuration.baseURL.appending(path: "pages/\(id)"))
        applyHeaders(to: &request)

        let (data, response) = try await transport.data(for: request)
        guard (200..<300).contains(response.statusCode) else {
            throw NotionAPIError.httpStatus(response.statusCode)
        }
        return try decoder.decode(NotionPageResponse.self, from: data)
    }

    private func fetchAllBlockChildren(id: String) async throws -> [NotionBlock] {
        var results: [NotionBlock] = []
        var cursor: String?

        repeat {
            var components = URLComponents(
                url: configuration.baseURL.appending(path: "blocks/\(id)/children"),
                resolvingAgainstBaseURL: false
            )!
            var queryItems = [URLQueryItem(name: "page_size", value: "100")]
            if let cursor {
                queryItems.append(URLQueryItem(name: "start_cursor", value: cursor))
            }
            components.queryItems = queryItems

            var request = URLRequest(url: components.url!)
            applyHeaders(to: &request)
            let (data, response) = try await transport.data(for: request)

            guard (200..<300).contains(response.statusCode) else {
                throw NotionAPIError.httpStatus(response.statusCode)
            }

            let page = try decoder.decode(NotionBlockChildrenResponse.self, from: data)
            results.append(contentsOf: page.results)
            cursor = page.hasMore ? page.nextCursor : nil
        } while cursor != nil

        return results
    }

    private func applyHeaders(to request: inout URLRequest) {
        request.setValue("Bearer \(configuration.token)", forHTTPHeaderField: "Authorization")
        request.setValue(configuration.apiVersion, forHTTPHeaderField: "Notion-Version")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    }
}

public extension NotionContentSourceService where Transport == URLSessionTransport {
    init(configuration: NotionConfiguration) {
        self.init(configuration: configuration, transport: URLSessionTransport())
    }
}

private struct NotionPageResponse: Decodable {
    let id: String
    let parent: NotionParent
    let lastEditedTime: Date?
    let properties: [String: NotionProperty]

    enum CodingKeys: String, CodingKey {
        case id, parent, properties
        case lastEditedTime = "last_edited_time"
    }

    var title: String? {
        properties.values
            .compactMap(\.titleText)
            .first(where: { !$0.isEmpty })
    }
}

private struct NotionParent: Decodable {
    let pageID: String?
    let databaseID: String?
    let workspace: Bool?

    enum CodingKeys: String, CodingKey {
        case pageID = "page_id"
        case databaseID = "database_id"
        case workspace
    }

    var parentID: String? { pageID ?? databaseID }
}

private struct NotionProperty: Decodable {
    let type: String?
    let title: [NotionRichText]?

    var titleText: String? {
        guard type == "title", let title else { return nil }
        return title.map(\.plainText).joined()
    }
}

private struct NotionBlockChildrenResponse: Decodable {
    let results: [NotionBlock]
    let nextCursor: String?
    let hasMore: Bool

    enum CodingKeys: String, CodingKey {
        case results
        case nextCursor = "next_cursor"
        case hasMore = "has_more"
    }
}

private struct NotionBlock: Decodable {
    let type: String
    let paragraph: NotionRichTextContainer?
    let heading1: NotionRichTextContainer?
    let heading2: NotionRichTextContainer?
    let heading3: NotionRichTextContainer?
    let bulletedListItem: NotionRichTextContainer?
    let numberedListItem: NotionRichTextContainer?
    let quote: NotionRichTextContainer?
    let callout: NotionRichTextContainer?
    let toggle: NotionRichTextContainer?

    enum CodingKeys: String, CodingKey {
        case type, paragraph, quote, callout, toggle
        case heading1 = "heading_1"
        case heading2 = "heading_2"
        case heading3 = "heading_3"
        case bulletedListItem = "bulleted_list_item"
        case numberedListItem = "numbered_list_item"
    }

    var plainText: String? {
        let container: NotionRichTextContainer?
        switch type {
        case "paragraph": container = paragraph
        case "heading_1": container = heading1
        case "heading_2": container = heading2
        case "heading_3": container = heading3
        case "bulleted_list_item": container = bulletedListItem
        case "numbered_list_item": container = numberedListItem
        case "quote": container = quote
        case "callout": container = callout
        case "toggle": container = toggle
        default: container = nil
        }
        return container?.richText.map(\.plainText).joined()
    }
}

private struct NotionRichTextContainer: Decodable {
    let richText: [NotionRichText]

    enum CodingKeys: String, CodingKey {
        case richText = "rich_text"
    }
}

private struct NotionRichText: Decodable {
    let plainText: String

    enum CodingKeys: String, CodingKey {
        case plainText = "plain_text"
    }
}
