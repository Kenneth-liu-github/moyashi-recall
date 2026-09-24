import Foundation

public enum NotionAPIError: Error, Equatable {
    case invalidResponse
    case http(statusCode: Int, message: String)
    case invalidURL
    case malformedPayload
}

public protocol HTTPTransport {
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
}

public struct URLSessionHTTPTransport: HTTPTransport {
    public init() {}

    public func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        try await URLSession.shared.data(for: request)
    }
}

public struct NotionAPIClient: LearningContentSource {
    public static let apiVersion = "2026-03-11"

    public let kind = "notion"

    private let token: String
    private let transport: HTTPTransport
    private let baseURL: URL

    public init(
        token: String,
        transport: HTTPTransport = URLSessionHTTPTransport(),
        baseURL: URL = URL(string: "https://api.notion.com")!
    ) {
        self.token = token
        self.transport = transport
        self.baseURL = baseURL
    }

    public func fetchDocument(id: String) async throws -> ImportedDocument {
        let result = try await fetchDocumentAndBlocks(id: id)
        return result.document
    }

    public func fetchDocumentTree(
        rootID: String,
        maxDepth: Int = 8,
        maxPages: Int = 200
    ) async throws -> [ImportedDocument] {
        let safeDepth = max(0, maxDepth)
        let safePageLimit = max(1, maxPages)

        var queue: [(id: String, depth: Int)] = [(rootID, 0)]
        var visited = Set<String>()
        var documents: [ImportedDocument] = []

        while !queue.isEmpty && documents.count < safePageLimit {
            let next = queue.removeFirst()

            guard visited.insert(next.id).inserted else {
                continue
            }

            let result = try await fetchDocumentAndBlocks(id: next.id)
            documents.append(result.document)

            guard next.depth < safeDepth else {
                continue
            }

            let children = childPageIDs(in: result.blocks)
            for childID in children where !visited.contains(childID) {
                queue.append((childID, next.depth + 1))
            }
        }

        return documents
    }

    public func searchPages(
        query: String,
        pageSize: Int = 50
    ) async throws -> [NotionPageSummary] {
        let url = baseURL
            .appendingPathComponent("v1")
            .appendingPathComponent("search")

        var pages: [NotionPageSummary] = []
        var cursor: String?

        repeat {
            var body: [String: Any] = [
                "query": query,
                "page_size": min(max(pageSize, 1), 100),
                "filter": [
                    "property": "object",
                    "value": "page"
                ]
            ]

            if let cursor {
                body["start_cursor"] = cursor
            }

            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.httpBody = try JSONSerialization.data(
                withJSONObject: body
            )
            applyHeaders(to: &request)

            let data = try await execute(request)
            let object = try JSONSerialization.jsonObject(with: data)

            guard let json = object as? [String: Any],
                  let results = json["results"] as? [[String: Any]]
            else {
                throw NotionAPIError.malformedPayload
            }

            pages.append(
                contentsOf: results.compactMap { page in
                    guard page["object"] as? String == "page",
                          let id = page["id"] as? String
                    else {
                        return nil
                    }

                    return NotionPageSummary(
                        id: id,
                        title: Self.extractPageTitle(from: page),
                        url: page["url"] as? String,
                        lastEditedAt: Self.parseISODate(
                            page["last_edited_time"] as? String
                        )
                    )
                }
            )

            let hasMore = json["has_more"] as? Bool ?? false
            cursor = hasMore
                ? json["next_cursor"] as? String
                : nil
        } while cursor != nil

        return pages
    }

    private func fetchDocumentAndBlocks(
        id: String
    ) async throws -> (
        document: ImportedDocument,
        blocks: [NotionContentBlock]
    ) {
        let page = try await retrievePage(id: id)
        let blocks = try await retrieveAllBlockChildren(parentID: id)

        let document = ImportedDocument(
            id: page.id,
            sourceKind: kind,
            title: page.title,
            sourceReference: page.url ?? "notion://page/\(page.id)",
            content: render(blocks: blocks),
            lastEditedAt: page.lastEditedAt
        )

        return (document, blocks)
    }

    public func retrievePage(id: String) async throws -> NotionPageSummary {
        let url = baseURL
            .appendingPathComponent("v1")
            .appendingPathComponent("pages")
            .appendingPathComponent(id)

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        applyHeaders(to: &request)

        let data = try await execute(request)
        let object = try JSONSerialization.jsonObject(with: data)
        guard let json = object as? [String: Any],
              let pageID = json["id"] as? String
        else {
            throw NotionAPIError.malformedPayload
        }

        return NotionPageSummary(
            id: pageID,
            title: Self.extractPageTitle(from: json),
            url: json["url"] as? String,
            lastEditedAt: Self.parseISODate(json["last_edited_time"] as? String)
        )
    }

    public func retrieveAllBlockChildren(parentID: String) async throws -> [NotionContentBlock] {
        try await retrieveAllBlockChildren(parentID: parentID, depth: 0)
    }

    private func retrieveAllBlockChildren(
        parentID: String,
        depth: Int
    ) async throws -> [NotionContentBlock] {
        guard depth < 50 else { return [] }

        var all: [NotionContentBlock] = []
        var cursor: String?

        repeat {
            var components = URLComponents(
                url: baseURL
                    .appendingPathComponent("v1")
                    .appendingPathComponent("blocks")
                    .appendingPathComponent(parentID)
                    .appendingPathComponent("children"),
                resolvingAgainstBaseURL: false
            )

            var queryItems = [URLQueryItem(name: "page_size", value: "100")]
            if let cursor {
                queryItems.append(URLQueryItem(name: "start_cursor", value: cursor))
            }
            components?.queryItems = queryItems

            guard let url = components?.url else {
                throw NotionAPIError.invalidURL
            }

            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            applyHeaders(to: &request)

            let data = try await execute(request)
            let page = try JSONDecoder().decode(
                NotionBlockListResponse.self,
                from: data
            )

            for dto in page.results {
                let children = dto.hasChildren
                    ? try await retrieveAllBlockChildren(
                        parentID: dto.id,
                        depth: depth + 1
                    )
                    : []

                all.append(
                    NotionContentBlock(
                        id: dto.id,
                        type: dto.type,
                        text: dto.plainText,
                        children: children
                    )
                )
            }

            cursor = page.hasMore ? page.nextCursor : nil
        } while cursor != nil

        return all
    }

    private func applyHeaders(to request: inout URLRequest) {
        request.setValue(
            "Bearer \(token)",
            forHTTPHeaderField: "Authorization"
        )
        request.setValue(
            Self.apiVersion,
            forHTTPHeaderField: "Notion-Version"
        )
        request.setValue(
            "application/json",
            forHTTPHeaderField: "Content-Type"
        )
    }

    private func execute(_ request: URLRequest) async throws -> Data {
        let (data, response) = try await transport.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw NotionAPIError.invalidResponse
        }

        guard (200..<300).contains(http.statusCode) else {
            throw NotionAPIError.http(
                statusCode: http.statusCode,
                message: Self.extractErrorMessage(from: data)
            )
        }

        return data
    }

    private func childPageIDs(
        in blocks: [NotionContentBlock]
    ) -> [String] {
        blocks.flatMap { block in
            var ids: [String] = []
            if block.type == "child_page" {
                ids.append(block.id)
            }
            ids.append(contentsOf: childPageIDs(in: block.children))
            return ids
        }
    }

    private func render(
        blocks: [NotionContentBlock],
        level: Int = 0
    ) -> String {
        blocks.compactMap { block in
            let prefix = String(repeating: "  ", count: level)
            let line: String

            switch block.type {
            case "heading_1":
                line = "# \(block.text)"
            case "heading_2":
                line = "## \(block.text)"
            case "heading_3":
                line = "### \(block.text)"
            case "bulleted_list_item":
                line = "\(prefix)- \(block.text)"
            case "numbered_list_item":
                line = "\(prefix)1. \(block.text)"
            case "to_do":
                line = "\(prefix)- \(block.text)"
            case "table_row":
                line = "| \(block.text) |"
            case "equation":
                line = block.text
            case "quote":
                line = "> \(block.text)"
            case "code":
                line = "CODE:\n\(block.text)"
            case "divider":
                line = "---"
            case "child_page", "child_database":
                line = "## \(block.text)"
            default:
                line = block.text
            }

            let nested = render(
                blocks: block.children,
                level: level + 1
            )
            if nested.isEmpty { return line }
            if line.isEmpty { return nested }
            return line + "\n" + nested
        }
        .filter {
            !$0.trimmingCharacters(
                in: .whitespacesAndNewlines
            ).isEmpty
        }
        .joined(separator: "\n\n")
    }

    private static func extractPageTitle(
        from json: [String: Any]
    ) -> String {
        if let properties = json["properties"] as? [String: Any] {
            for value in properties.values {
                guard let property = value as? [String: Any],
                      property["type"] as? String == "title",
                      let titleItems = property["title"] as? [[String: Any]]
                else {
                    continue
                }

                let text = titleItems.compactMap {
                    $0["plain_text"] as? String
                }.joined()

                if !text.isEmpty {
                    return text
                }
            }
        }
        return "Untitled"
    }

    private static func extractErrorMessage(
        from data: Data
    ) -> String {
        guard let object = try? JSONSerialization.jsonObject(
            with: data
        ),
        let json = object as? [String: Any],
        let message = json["message"] as? String
        else {
            return "Unknown Notion API error"
        }
        return message
    }

    private static func parseISODate(
        _ value: String?
    ) -> Date? {
        guard let value else { return nil }

        let fractional = ISO8601DateFormatter()
        fractional.formatOptions = [
            .withInternetDateTime,
            .withFractionalSeconds
        ]
        if let date = fractional.date(from: value) {
            return date
        }

        return ISO8601DateFormatter().date(from: value)
    }
}

public struct NotionPageSummary: Equatable, Sendable {
    public let id: String
    public let title: String
    public let url: String?
    public let lastEditedAt: Date?

    public init(
        id: String,
        title: String,
        url: String?,
        lastEditedAt: Date?
    ) {
        self.id = id
        self.title = title
        self.url = url
        self.lastEditedAt = lastEditedAt
    }
}

public struct NotionContentBlock: Identifiable, Equatable, Sendable {
    public let id: String
    public let type: String
    public let text: String
    public let children: [NotionContentBlock]

    public init(
        id: String,
        type: String,
        text: String,
        children: [NotionContentBlock]
    ) {
        self.id = id
        self.type = type
        self.text = text
        self.children = children
    }
}

private struct NotionBlockListResponse: Decodable {
    let results: [NotionBlockDTO]
    let nextCursor: String?
    let hasMore: Bool

    enum CodingKeys: String, CodingKey {
        case results
        case nextCursor = "next_cursor"
        case hasMore = "has_more"
    }
}

private struct NotionBlockDTO: Decodable {
    let id: String
    let type: String
    let hasChildren: Bool

    let paragraph: NotionTextContainer?
    let heading1: NotionTextContainer?
    let heading2: NotionTextContainer?
    let heading3: NotionTextContainer?
    let bulletedListItem: NotionTextContainer?
    let numberedListItem: NotionTextContainer?
    let toDo: NotionTextContainer?
    let toggle: NotionTextContainer?
    let quote: NotionTextContainer?
    let callout: NotionTextContainer?
    let code: NotionTextContainer?
    let tableRow: NotionTableRow?
    let equation: NotionEquation?
    let childPage: NotionChildPage?
    let childDatabase: NotionChildPage?

    enum CodingKeys: String, CodingKey {
        case id
        case type
        case hasChildren = "has_children"
        case paragraph
        case heading1 = "heading_1"
        case heading2 = "heading_2"
        case heading3 = "heading_3"
        case bulletedListItem = "bulleted_list_item"
        case numberedListItem = "numbered_list_item"
        case toDo = "to_do"
        case toggle
        case quote
        case callout
        case code
        case tableRow = "table_row"
        case equation
        case childPage = "child_page"
        case childDatabase = "child_database"
    }

    var plainText: String {
        if let childPage {
            return childPage.title
        }
        if let childDatabase {
            return childDatabase.title
        }
        if let tableRow {
            return tableRow.cells
                .map { cell in
                    cell.map(\.plainText).joined()
                }
                .joined(separator: " | ")
        }
        if let equation {
            return equation.expression
        }

        let container: NotionTextContainer?
        switch type {
        case "paragraph":
            container = paragraph
        case "heading_1":
            container = heading1
        case "heading_2":
            container = heading2
        case "heading_3":
            container = heading3
        case "bulleted_list_item":
            container = bulletedListItem
        case "numbered_list_item":
            container = numberedListItem
        case "to_do":
            container = toDo
        case "toggle":
            container = toggle
        case "quote":
            container = quote
        case "callout":
            container = callout
        case "code":
            container = code
        default:
            container = nil
        }

        return container?.richText
            .map(\.plainText)
            .joined() ?? ""
    }
}

private struct NotionTextContainer: Decodable {
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

private struct NotionChildPage: Decodable {
    let title: String
}

private struct NotionTableRow: Decodable {
    let cells: [[NotionRichText]]
}

private struct NotionEquation: Decodable {
    let expression: String
}
