import Foundation

public enum JapaneseSpeechText {
    public static func normalized(
        _ text: String
    ) -> String {
        text.replacingOccurrences(
            of: "（[ぁ-ゖァ-ヺー]+）",
            with: "",
            options: .regularExpression
        )
    }

    public static func containsJapanese(
        _ text: String
    ) -> Bool {
        text.range(
            of: "[ぁ-ゖァ-ヺ一-龯々〆ヵヶ]",
            options: .regularExpression
        ) != nil
    }
}
