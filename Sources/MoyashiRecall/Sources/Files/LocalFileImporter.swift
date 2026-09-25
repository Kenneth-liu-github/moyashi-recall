import Foundation

public enum LocalFileImportError: Error, Equatable {
    case unsupportedExtension(String)
    case unreadableFile
    case emptyContent
    case pdfUnavailable
}

public struct LocalFileImportResult: Equatable, Sendable {
    public let documents: [ImportedDocument]

    public init(documents: [ImportedDocument]) {
        self.documents = documents
    }
}

public struct LocalFileImporter {
    public init() {}

    public func importFile(
        at url: URL,
        modifiedAt: Date? = nil
    ) throws -> LocalFileImportResult {
        let ext = url.pathExtension.lowercased()
        let title = url.lastPathComponent
        let rootID = Self.externalID(
            for: url
        )
        let lastEditedAt = modifiedAt
            ?? Self.modificationDate(for: url)

        switch ext {
        case "txt", "md", "markdown":
            let content = try readTextFile(url)
            guard !content
                .trimmingCharacters(
                    in: .whitespacesAndNewlines
                )
                .isEmpty
            else {
                throw LocalFileImportError.emptyContent
            }

            return LocalFileImportResult(
                documents: [
                    ImportedDocument(
                        id: rootID,
                        sourceKind: "file",
                        title: title,
                        sourceReference: "local-file://\(title)",
                        content: content,
                        lastEditedAt: lastEditedAt,
                        rootExternalID: rootID,
                        sourcePath: [
                            "Imported Files",
                            title
                        ],
                        hierarchyDepth: 0
                    )
                ]
            )

        case "pdf":
            return try importPDF(
                url: url,
                title: title,
                rootID: rootID,
                lastEditedAt: lastEditedAt
            )

        default:
            throw LocalFileImportError
                .unsupportedExtension(ext)
        }
    }

    private func readTextFile(
        _ url: URL
    ) throws -> String {
        if let value = try? String(
            contentsOf: url,
            encoding: .utf8
        ) {
            return value
        }

        if let value = try? String(
            contentsOf: url,
            encoding: .unicode
        ) {
            return value
        }

        throw LocalFileImportError.unreadableFile
    }

    private func importPDF(
        url: URL,
        title: String,
        rootID: String,
        lastEditedAt: Date?
    ) throws -> LocalFileImportResult {
        #if canImport(PDFKit)
        return try PDFTextExtractor.extract(
            url: url,
            title: title,
            rootID: rootID,
            lastEditedAt: lastEditedAt
        )
        #else
        throw LocalFileImportError.pdfUnavailable
        #endif
    }

    private static func modificationDate(
        for url: URL
    ) -> Date? {
        try? url.resourceValues(
            forKeys: [.contentModificationDateKey]
        ).contentModificationDate
    }

    private static func externalID(
        for url: URL
    ) -> String {
        let normalizedName = url.lastPathComponent
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )
            .lowercased()
        let normalizedPath = url
            .standardizedFileURL
            .path
            .lowercased()

        var hash: UInt64 = 14_695_981_039_346_656_037
        for byte in normalizedPath.utf8 {
            hash ^= UInt64(byte)
            hash &*= 1_099_511_628_211
        }

        let pathHash = String(
            hash,
            radix: 16
        )
        return "local-file:\(normalizedName):\(pathHash)"
    }
}

#if canImport(PDFKit)
import PDFKit

private enum PDFTextExtractor {
    static func extract(
        url: URL,
        title: String,
        rootID: String,
        lastEditedAt: Date?
    ) throws -> LocalFileImportResult {
        guard let pdf = PDFDocument(url: url) else {
            throw LocalFileImportError.unreadableFile
        }

        var documents: [ImportedDocument] = []
        var nonEmptyPages = 0

        for index in 0..<pdf.pageCount {
            guard let page = pdf.page(at: index) else {
                continue
            }

            let text = (page.string ?? "")
                .trimmingCharacters(
                    in: .whitespacesAndNewlines
                )
            guard !text.isEmpty else {
                continue
            }

            nonEmptyPages += 1
            let pageNumber = index + 1
            let pageTitle = "Page \(pageNumber)"

            documents.append(
                ImportedDocument(
                    id: "\(rootID)#page-\(pageNumber)",
                    sourceKind: "file",
                    title: pageTitle,
                    sourceReference:
                        "local-file://\(title)#page=\(pageNumber)",
                    content: text,
                    lastEditedAt: lastEditedAt,
                    parentExternalID: rootID,
                    rootExternalID: rootID,
                    sourcePath: [
                        "Imported Files",
                        title,
                        pageTitle
                    ],
                    hierarchyDepth: 1
                )
            )
        }

        guard nonEmptyPages > 0 else {
            throw LocalFileImportError.emptyContent
        }

        let root = ImportedDocument(
            id: rootID,
            sourceKind: "file",
            title: title,
            sourceReference: "local-file://\(title)",
            content: "",
            lastEditedAt: lastEditedAt,
            rootExternalID: rootID,
            sourcePath: [
                "Imported Files",
                title
            ],
            hierarchyDepth: 0
        )

        return LocalFileImportResult(
            documents: [root] + documents
        )
    }
}
#endif
