import Foundation

public enum SourceKeyResolver {
    public static func resolve(
        sourceKind: String,
        sourcePath: [String]
    ) -> String {
        guard !sourcePath.isEmpty else {
            return sourceKind
        }

        let categoryTitle: String
        if sourceKind == "notion",
           sourcePath.first == "Learning Home",
           sourcePath.count >= 2 {
            categoryTitle = sourcePath[1]
        } else {
            categoryTitle = sourcePath[0]
        }

        switch categoryTitle {
        case "办公室日语学习":
            return "office-japanese"
        case "日语训练营":
            return "japanese-bootcamp"
        case "日语口语 私教":
            return "japanese-speaking"
        default:
            let slug = categoryTitle
                .folding(
                    options: [.diacriticInsensitive, .caseInsensitive],
                    locale: .current
                )
                .lowercased()
                .replacingOccurrences(
                    of: "[^a-z0-9]+",
                    with: "-",
                    options: .regularExpression
                )
                .trimmingCharacters(
                    in: CharacterSet(charactersIn: "-")
                )

            return slug.isEmpty
                ? "\(sourceKind)-uncategorized"
                : "\(sourceKind)-\(slug)"
        }
    }
}
