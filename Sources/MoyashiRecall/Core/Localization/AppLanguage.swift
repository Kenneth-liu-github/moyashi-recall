import Foundation
import SwiftUI

public enum AppLanguage: String, CaseIterable, Identifiable {
    case zhHans
    case ja

    public var id: String { rawValue }
    public var locale: Locale { Locale(identifier: self == .zhHans ? "zh-Hans" : "ja") }
    public var displayName: String { self == .zhHans ? "中文" : "日本語" }
}

@MainActor
public final class LanguageStore: ObservableObject {
    @AppStorage("interfaceLanguage") private var storedLanguage = AppLanguage.zhHans.rawValue

    @Published public var language: AppLanguage = .zhHans {
        didSet { storedLanguage = language.rawValue }
    }

    public init() {
        language = AppLanguage(rawValue: storedLanguage) ?? .zhHans
    }

    public func text(_ zh: String, _ ja: String) -> String {
        language == .zhHans ? zh : ja
    }
}
