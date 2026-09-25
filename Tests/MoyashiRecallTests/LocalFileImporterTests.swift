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


    #if !(canImport(AppKit) || canImport(UIKit))
    func testWordImportReportsUnavailableWithoutAppleTextSystem() throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(
                "\(UUID().uuidString).docx"
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
                .richDocumentUnavailable
            )
        }
    }
    #endif


    #if canImport(PDFKit)
    func testPDFImportCreatesPageLevelDocuments() throws {
        let base64 = """
        JVBERi0xLjMKJZOMi54gUmVwb3J0TGFiIEdlbmVyYXRlZCBQREYgZG9jdW1lbnQgKG9wZW5zb3VyY2UpCjEgMCBvYmoKPDwKL0YxIDIgMCBSCj4+CmVuZG9iagoyIDAgb2JqCjw8Ci9CYXNlRm9udCAvSGVsdmV0aWNhIC9FbmNvZGluZyAvV2luQW5zaUVuY29kaW5nIC9OYW1lIC9GMSAvU3VidHlwZSAvVHlwZTEgL1R5cGUgL0ZvbnQKPj4KZW5kb2JqCjMgMCBvYmoKPDwKL0NvbnRlbnRzIDcgMCBSIC9NZWRpYUJveCBbIDAgMCAzMDAgMzAwIF0gL1BhcmVudCA2IDAgUiAvUmVzb3VyY2VzIDw8Ci9Gb250IDEgMCBSIC9Qcm9jU2V0IFsgL1BERiAvVGV4dCAvSW1hZUIgL0ltYWdlQyAvSW1hZ2VJIF0KPj4gL1JvdGF0ZSAwIC9UcmFucyA8PAoKPj4gCiAgL1R5cGUgL1BhZ2UKPj4KZW5kb2JqCjQgMCBvYmoKPDwKL1BhZ2VNb2RlIC9Vc2VOb25lIC9QYWdlcyA2IDAgUiAvVHlwZSAvQ2F0YWxvZwo+PgplbmRvYmoKNSAwIG9iago8PAovQXV0aG9yIChhbm9ueW1vdXMpIC9DcmVhdGlvbkRhdGUgKEQ6MjAyNjA5MjUwNTA5MDgrMDAnMDAnKSAvQ3JlYXRvciAoYW5vbnltb3VzKSAvS2V5d29yZHMgKCkgL01vZERhdGUgKEQ6MjAyNjA5MjUwNTA5MDgrMDAnMDAnKSAvUHJvZHVjZXIgKFJlcG9ydExhYiBQREYgTGlicmFyeSAtIFwob3BlbnNvdXJjZVwpKSAKICAvU3ViamVjdCAodW5zcGVjaWZpZWQpIC9UaXRsZSAodW50aXRsZWQpIC9UcmFwcGVkIC9GYWxzZQo+PgplbmRvYmoKNiAwIG9iago8PAovQ291bnQgMSAvS2lkcyBbIDMgMCBSIF0gL1R5cGUgL1BhZ2VzCj4+CmVuZG9iago3IDAgb2JqCjw8Ci9GaWx0ZXIgWyAvQVNDSUk4NURlY29kZSAvRmxhdGVEZWNvZGUgXSAvTGVuZ3RoIDExMgo+PgpzdHJlYW0KR2FwUWgwRT1GLDBVXEgzVFxwTllUXlFLaz90Yz5JUCw7VydVMV4yM2loUEVNXz9DVzRLSVNpNjpiWFheOj5HOUNkLiM7YDlKJEsxPChaR183O1s+b2Y6SzkqdTwhXlREI2dpXWY7O19LVVIwIikiPn5lbmRzdHJlYW0KZW5kb2JqCnhyZWYKMCA4CjAwMDAwMDAwMDAgNjU1MzUgZiAKMDAwMDAwMDA2MSAwMDAwMCBuIAowMDAwMDAwMDkyIDAwMDAwIG4gCjAwMDAwMDAxOTkgMDAwMDAgbiAKMDAwMDAwMDM5MiAwMDAwMCBuIAowMDAwMDAwNDYwIDAwMDAwIG4gCjAwMDAwMDA3MjEgMDAwMDAgbiAKMDAwMDAwMDc4MCAwMDAwMCBuIAp0cmFpbGVyCjw8Ci9JRCAKWzw5YjRhZTE2MjNlZjlhODYxOTdlNzk5OGM4YTZlZWYxMD48OWI0YWUxNjIzZWY5YTg2MTk3ZTc5OThjOGE2ZWVmMTA+XQolIFJlcG9ydExhYiBnZW5lcmF0ZWQgUERGIGRvY3VtZW50IC0tIGRpZ2VzdCAob3BlbnNvdXJjZSkKCi9JbmZvIDUgMCBSCi9Sb290IDQgMCBSCi9TaXplIDgKPj4Kc3RhcnR4cmVmCjk4MgolJUVPRgo=
        """

        let data = try XCTUnwrap(
            Data(base64Encoded: base64)
        )
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(
                "\(UUID().uuidString).pdf"
            )
        try data.write(to: url)
        defer {
            try? FileManager.default.removeItem(
                at: url
            )
        }

        let result = try LocalFileImporter()
            .importFile(at: url)

        XCTAssertEqual(result.documents.count, 2)

        let root = result.documents[0]
        let page = result.documents[1]

        XCTAssertTrue(root.content.isEmpty)
        XCTAssertEqual(page.hierarchyDepth, 1)
        XCTAssertEqual(
            page.parentExternalID,
            root.id
        )
        XCTAssertEqual(
            page.rootExternalID,
            root.id
        )
        XCTAssertEqual(
            page.sourceKeyHint,
            root.sourceKeyHint
        )
        XCTAssertTrue(
            page.content.contains(
                "Moyashi PDF Page 1"
            )
        )
        XCTAssertTrue(
            page.sourceReference.contains(
                "#page=1"
            )
        )
    }
    #endif


    #if canImport(AppKit) || canImport(UIKit)
    func testDOCXImportExtractsText() throws {
        let base64 = """
        UEsDBBQAAAAIAD0pOV15bjPX6AAAAK0BAAATAAAAW0NvbnRlbnRfVHlwZXNdLnhtbH1QyU7DMBD9FWuuKHHggBCK0wPLETiUDxjZk8SqN3nc0v49Tlt6QIXjzFv1+tXeO7GjzDYGBbdtB4KCjsaGScHn+rV5AMEFg0EXAyk4EMNq6NeHRCyqNrCCuZT0KCXrmTxyGxOFiowxeyz1zJNMqDc4kbzrunupYygUSlMWDxj6Zxpx64p42df3qUcmxyCeTsQlSwGm5KzGUnG5C+ZXSnNOaKvyyOHZJr6pBJBXExbk74Cz7r0Ok60h8YG5vKGvLPkVs5Em6q2vyvZ/mys94zhaTRf94pZy1MRcF/euvSAebfjpL49zD99QSwMEFAAAAAgAPSk5XZv9N+qtAAAAKQEAAAsAAABfcmVscy8ucmVsc43POw7CMAwG4KtE3mlaBoRQ0y4IqSsqB7ASN61oHkrCo7cnAwNFDIy2f3+W6/ZpZnanECdnBVRFCYysdGqyWsClP232wGJCq3B2lgQsFKFt6jPNmPJKHCcfWTZsFDCm5A+cRzmSwVg4TzZPBhcMplwGzT3KK2ri27Lc8fBpwNpknRIQOlUB6xdP/9huGCZJRydvhmz6ceIrkWUMmpKAhwuKq3e7yCzwpuarF5sXUEsDBBQAAAAIAD0pOV3wNzbqrAAAAOUAAAARAAAAd29yZC9kb2N1bWVudC54bWxFjrsOwjAMRX8lyk5TGBCq+hhAbAiGIrGGxNBIjV3FgdK/pykDy7F8bR3dsvn4XrwhsCOs5DrLpQA0ZB0+K3ltj6udFBw1Wt0TQiUnYNnU5VhYMi8PGMUsQC7GSnYxDoVSbDrwmjMaAOfbg4LXcV7DU40U7BDIAPPs973a5PlWee1QJuWd7JTmkBASYn2iSXPnxOG8v4kWOJYqxYlh4fLMYOIlqCX4WdS/Yf0FUEsBAhQDFAAAAAgAPSk5XXluM9foAAAArQEAABMAAAAAAAAAAAAAAIABAAAAAFtDb250ZW50X1R5cGVzXS54bWxQSwECFAMUAAAACAA9KTldm/036q0AAAApAQAACwAAAAAAAAAAAAAAgAEZAQAAX3JlbHMvLnJlbHNQSwECFAMUAAAACAA9KTld8Dc26qwAAADlAAAAEQAAAAAAAAAAAAAAgAHvAQAAd29yZC9kb2N1bWVudC54bWxQSwUGAAAAAAMAAwC5AAAAygIAAAAA
        """

        let data = try XCTUnwrap(
            Data(base64Encoded: base64)
        )
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(
                "\(UUID().uuidString).docx"
            )
        try data.write(to: url)
        defer {
            try? FileManager.default.removeItem(
                at: url
            )
        }

        let result = try LocalFileImporter()
            .importFile(at: url)

        XCTAssertEqual(result.documents.count, 1)
        XCTAssertTrue(
            result.documents[0].content.contains(
                "Moyashi DOCX Test"
            )
        )
        XCTAssertEqual(
            result.documents[0].sourceKind,
            "file"
        )
    }
    #endif


    func testImportsCSVAsText() throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(
                "\(UUID().uuidString).csv"
            )
        try "日本語,中文\n進め方,推进方式".write(
            to: url,
            atomically: true,
            encoding: .utf8
        )
        defer {
            try? FileManager.default.removeItem(
                at: url
            )
        }

        let result = try LocalFileImporter()
            .importFile(at: url)

        XCTAssertEqual(result.documents.count, 1)
        XCTAssertTrue(
            result.documents[0].content.contains(
                "進め方,推进方式"
            )
        )
    }


}
