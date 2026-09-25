import XCTest
@testable import MoyashiRecall

final class LocalFileImporterTests: XCTestCase {
    func testImportsUTF8TextFile() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(
                UUID().uuidString,
                isDirectory: true
            )
        try FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true
        )
        defer {
            try? FileManager.default.removeItem(
                at: directory
            )
        }

        let url = directory.appendingPathComponent(
            "lesson.txt"
        )
        try "進（すす）め方（かた）について".write(
            to: url,
            atomically: true,
            encoding: .utf8
        )

        let result = try LocalFileImporter()
            .importFile(at: url)

        XCTAssertEqual(result.documents.count, 1)

        let document = try XCTUnwrap(
            result.documents.first
        )
        XCTAssertEqual(document.sourceKind, "file")
        XCTAssertEqual(document.title, "lesson.txt")
        XCTAssertEqual(
            document.content,
            "進（すす）め方（かた）について"
        )
        XCTAssertEqual(
            document.sourcePath,
            ["Imported Files", "lesson.txt"]
        )
        XCTAssertEqual(document.hierarchyDepth, 0)
        XCTAssertEqual(
            document.rootExternalID,
            document.id
        )
        XCTAssertFalse(
            document.id.contains(
                directory.path.lowercased()
            )
        )
    }

    func testImportsMarkdownAsText() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(
                UUID().uuidString,
                isDirectory: true
            )
        try FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true
        )
        defer {
            try? FileManager.default.removeItem(
                at: directory
            )
        }

        let url = directory.appendingPathComponent(
            "notes.md"
        )
        try "# 文法（ぶんぽう）\n\nために / ように".write(
            to: url,
            atomically: true,
            encoding: .utf8
        )

        let result = try LocalFileImporter()
            .importFile(at: url)

        XCTAssertEqual(result.documents.count, 1)
        XCTAssertTrue(
            result.documents[0].content.contains(
                "ために / ように"
            )
        )
    }

    func testRejectsEmptyTextFile() throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(
                "\(UUID().uuidString).txt"
            )
        try "   \n".write(
            to: url,
            atomically: true,
            encoding: .utf8
        )
        defer {
            try? FileManager.default.removeItem(
                at: url
            )
        }

        XCTAssertThrowsError(
            try LocalFileImporter().importFile(at: url)
        ) { error in
            XCTAssertEqual(
                error as? LocalFileImportError,
                .emptyContent
            )
        }
    }

    func testRejectsUnsupportedExtension() throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(
                "\(UUID().uuidString).docx"
            )
        try Data("test".utf8).write(to: url)
        defer {
            try? FileManager.default.removeItem(
                at: url
            )
        }

        XCTAssertThrowsError(
            try LocalFileImporter().importFile(at: url)
        ) { error in
            XCTAssertEqual(
                error as? LocalFileImportError,
                .unsupportedExtension("docx")
            )
        }
    }

    func testSameFilenameInDifferentFoldersGetsDifferentExternalIDs() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent(
                UUID().uuidString,
                isDirectory: true
            )
        let firstDirectory = root
            .appendingPathComponent(
                "one",
                isDirectory: true
            )
        let secondDirectory = root
            .appendingPathComponent(
                "two",
                isDirectory: true
            )

        try FileManager.default.createDirectory(
            at: firstDirectory,
            withIntermediateDirectories: true
        )
        try FileManager.default.createDirectory(
            at: secondDirectory,
            withIntermediateDirectories: true
        )
        defer {
            try? FileManager.default.removeItem(
                at: root
            )
        }

        let first = firstDirectory
            .appendingPathComponent("notes.txt")
        let second = secondDirectory
            .appendingPathComponent("notes.txt")

        try "first".write(
            to: first,
            atomically: true,
            encoding: .utf8
        )
        try "second".write(
            to: second,
            atomically: true,
            encoding: .utf8
        )

        let importer = LocalFileImporter()
        let firstID = try importer
            .importFile(at: first)
            .documents[0].id
        let secondID = try importer
            .importFile(at: second)
            .documents[0].id

        XCTAssertNotEqual(firstID, secondID)

        let firstDocument = try importer
            .importFile(at: first)
            .documents[0]
        let secondDocument = try importer
            .importFile(at: second)
            .documents[0]

        XCTAssertNotEqual(
            firstDocument.sourceKeyHint,
            secondDocument.sourceKeyHint
        )
        XCTAssertEqual(
            firstDocument.sourcePath,
            secondDocument.sourcePath
        )
    }
    #if !canImport(Vision)
    func testImageImportReportsUnavailableWithoutVision() throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(
                "\(UUID().uuidString).png"
            )
        try Data([0, 1, 2]).write(to: url)
        defer {
            try? FileManager.default.removeItem(
                at: url
            )
        }

        XCTAssertThrowsError(
            try LocalFileImporter().importFile(at: url)
        ) { error in
            XCTAssertEqual(
                error as? LocalFileImportError,
                .imageTextRecognitionUnavailable
            )
        }
    }
    #endif


}
