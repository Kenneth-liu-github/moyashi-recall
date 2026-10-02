import Foundation
import ZIPFoundation

enum DOCXTextExtractor {
    static func extract(url: URL) throws -> String {
        let archive: Archive
        do {
            archive = try Archive(
                url: url,
                accessMode: .read
            )
        } catch {
            throw LocalFileImportError.unreadableFile
        }

        guard let entry = archive["word/document.xml"] else {
            throw LocalFileImportError.unreadableFile
        }

        var xmlData = Data()
        _ = try archive.extract(entry) { chunk in
            xmlData.append(chunk)
        }

        let parser = DOCXXMLParser(data: xmlData)
        let text = try parser.parse()
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard !text.isEmpty else {
            throw LocalFileImportError.emptyContent
        }

        return text
    }
}

private final class DOCXXMLParser: NSObject, XMLParserDelegate {
    private let data: Data

    private var output = ""
    private var currentText = ""

    init(data: Data) {
        self.data = data
    }

    func parse() throws -> String {
        let parser = XMLParser(data: data)
        parser.delegate = self

        guard parser.parse() else {
            throw LocalFileImportError.unreadableFile
        }

        return output
    }

    func parser(
        _ parser: XMLParser,
        didStartElement elementName: String,
        namespaceURI: String?,
        qualifiedName qName: String?,
        attributes attributeDict: [String: String] = [:]
    ) {
        switch elementName {
        case "w:t":
            currentText = ""

        case "w:tab":
            output.append("\t")

        case "w:br", "w:cr":
            output.append("\n")

        default:
            break
        }
    }

    func parser(
        _ parser: XMLParser,
        foundCharacters string: String
    ) {
        currentText.append(string)
    }

    func parser(
        _ parser: XMLParser,
        didEndElement elementName: String,
        namespaceURI: String?,
        qualifiedName qName: String?
    ) {
        switch elementName {
        case "w:t":
            output.append(currentText)
            currentText = ""

        case "w:p":
            if !output.hasSuffix("\n") {
                output.append("\n")
            }

        default:
            break
        }
    }
}
