import SwiftUI
import SwiftData

public struct ReviewView: View {
    private let sourceKeys: Set<String>?
    private let cardTypes: Set<String>?
    private let sessionLimit: Int

    @EnvironmentObject private var language: LanguageStore
    @Environment(\.modelContext) private var modelContext

    @State private var revealed = false
    @State private var reviewed = 0
    @State private var sessionCards: [ReviewSessionCard] = []
    @State private var currentIndex = 0
    @State private var saveError: String?
    @State private var didLoadSession = false

    public init(
        sourceKeys: Set<String>? = nil,
        cardTypes: Set<String>? = nil,
        sessionLimit: Int = 20
    ) {
        self.sourceKeys = sourceKeys
        self.cardTypes = cardTypes
        self.sessionLimit = max(1, sessionLimit)
    }

    private var currentCard: ReviewSessionCard? {
        guard currentIndex < sessionCards.count else { return nil }
        return sessionCards[currentIndex]
    }

    public var body: some View {
        VStack(spacing: 0) {
            if !sessionCards.isEmpty {
                ProgressView(value: Double(reviewed), total: Double(sessionCards.count))
                    .tint(AppTheme.accent)
                    .padding(.horizontal)
                    .padding(.top, 10)
            }

            Group {
                if let card = currentCard {
                    reviewContent(card)
                } else if let saveError, !didLoadSession {
                    ContentUnavailableView(
                        language.text("无法读取复习队列", "復習キューを読み込めません"),
                        systemImage: "exclamationmark.triangle",
                        description: Text(saveError)
                    )
                } else if sessionCards.isEmpty {
                    emptyState
                } else {
                    completeState
                }
            }
        }
        .navigationTitle(language.text("复习", "復習"))
        .task {
            loadSessionIfNeeded()
        }
        .onAppear {
            refreshFinishedSessionIfNeeded()
        }
    }

    @ViewBuilder
    private func reviewContent(_ card: ReviewSessionCard) -> some View {
        ScrollView {
            VStack(spacing: 22) {
                HStack {
                    Text(cardTypeLabel(card.cardType))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AppTheme.accent)
                    Spacer()
                    Text("\(min(currentIndex + 1, sessionCards.count)) / \(sessionCards.count)")
                        .font(.caption)
                        .foregroundStyle(AppTheme.muted)
                }

                Spacer(minLength: 30)

                Text(card.prompt)
                    .font(.title2.bold())
                    .multilineTextAlignment(.center)

                Text(card.sourceDisplay)
                    .font(.caption)
                    .foregroundStyle(AppTheme.muted)

                if revealed {
                    Divider().padding(.vertical, 4)
                    VStack(spacing: 12) {
                        Text(card.answer)
                            .font(.title3.bold())
                        if !card.explanation.isEmpty {
                            Text(card.explanation)
                                .multilineTextAlignment(.center)
                        }
                        if !card.naturalEnglish.isEmpty {
                            Text("Natural English: \(card.naturalEnglish)")
                                .font(.subheadline)
                                .foregroundStyle(AppTheme.muted)
                        }
                        if let saveError {
                            Text(saveError)
                                .font(.caption)
                                .foregroundStyle(.red)
                        }
                    }
                }

                Spacer(minLength: 24)
            }
            .padding(20)
        }

        VStack(spacing: 12) {
            if revealed {
                HStack(spacing: 8) {
                    rating(language.text("重来", "もう一度"), .again, card: card)
                    rating(language.text("困难", "難しい"), .hard, card: card)
                    rating(language.text("良好", "良い"), .good, card: card)
                    rating(language.text("简单", "簡単"), .easy, card: card)
                }
            } else {
                Button {
                    saveError = nil
                    revealed = true
                } label: {
                    Text(language.text("显示答案", "答えを見る"))
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.borderedProminent)
                .tint(AppTheme.accent)
            }
        }
        .padding()
        .background(AppTheme.surface)
    }

    private var emptyState: some View {
        ContentUnavailableView(
            language.text("今天没有到期卡片", "今日は期限のカードがありません"),
            systemImage: "checkmark.circle",
            description: Text(
                language.text(
                    "完成得很好。新的卡片或到期卡片出现后会显示在这里。",
                    "新しいカードまたは期限のカードがここに表示されます。"
                )
            )
        )
    }

    private var completeState: some View {
        ContentUnavailableView(
            language.text("本次复习完成", "今回の復習が完了しました"),
            systemImage: "checkmark.circle.fill",
            description: Text(
                language.text(
                    "已完成 \(reviewed) 张卡片。",
                    "\(reviewed)枚のカードを完了しました。"
                )
            )
        )
    }

    private func rating(
        _ text: String,
        _ value: ReviewRating,
        card: ReviewSessionCard
    ) -> some View {
        Button(text) {
            do {
                let repository = LearningRepository(context: modelContext)
                _ = try repository.recordReview(
                    cardID: card.id,
                    rating: value
                )
                reviewed += 1
                currentIndex += 1
                revealed = false
                saveError = nil
            } catch {
                saveError = language.text(
                    "保存复习记录失败。",
                    "復習記録の保存に失敗しました。"
                )
            }
        }
        .buttonStyle(.bordered)
        .tint(AppTheme.accent)
        .frame(maxWidth: .infinity)
    }

    private func refreshFinishedSessionIfNeeded() {
        guard didLoadSession else { return }
        guard sessionCards.isEmpty || currentIndex >= sessionCards.count else { return }

        didLoadSession = false
        sessionCards = []
        currentIndex = 0
        reviewed = 0
        revealed = false
        saveError = nil
        loadSessionIfNeeded()
    }

    private func loadSessionIfNeeded() {
        guard !didLoadSession else { return }

        do {
            let repository = LearningRepository(context: modelContext)
            try repository.seedDemoIfNeeded()
            sessionCards = try repository.dueSessionCards(
                sourceKeys: sourceKeys,
                cardTypes: cardTypes,
                limit: sessionLimit
            )
            currentIndex = 0
            reviewed = 0
            didLoadSession = true
            saveError = nil
        } catch {
            saveError = language.text(
                "无法读取待复习卡片。",
                "復習待ちカードを読み込めませんでした。"
            )
        }
    }

    private func cardTypeLabel(_ type: String) -> String {
        switch type {
        case "zh-to-ja": return language.text("中 → 日", "中 → 日")
        case "ja-to-zh": return language.text("日 → 中", "日 → 中")
        case "cloze":
            return "Cloze"
        case "contrast":
            return language.text("对比", "比較")
        case "application":
            return language.text("应用", "応用")
        default:
            return language.text("复习", "復習")
        }
    }
}
