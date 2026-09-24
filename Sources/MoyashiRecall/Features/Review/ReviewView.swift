import SwiftUI
import SwiftData

public struct ReviewView: View {
    @EnvironmentObject private var language: LanguageStore
    @Environment(\.modelContext) private var modelContext
    @State private var revealed = false
    @State private var reviewed = 0
    @State private var scheduleMessage: String?
    @State private var saveError: String?

    public init() {}

    public var body: some View {
        VStack(spacing: 0) {
            ProgressView(value: Double(reviewed), total: 20)
                .tint(AppTheme.accent)
                .padding(.horizontal)
                .padding(.top, 10)

            ScrollView {
                VStack(spacing: 22) {
                    HStack {
                        Text(language.text("中 → 日", "中 → 日"))
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(AppTheme.accent)
                        Spacer()
                        Text("\(min(reviewed + 1, 20)) / 20")
                            .font(.caption)
                            .foregroundStyle(AppTheme.muted)
                    }

                    Spacer(minLength: 30)

                    Text(MockData.reviewCard.prompt)
                        .font(.title2.bold())
                        .multilineTextAlignment(.center)

                    Text(MockData.reviewCard.source)
                        .font(.caption)
                        .foregroundStyle(AppTheme.muted)

                    if revealed {
                        Divider().padding(.vertical, 4)
                        VStack(spacing: 12) {
                            Text(MockData.reviewCard.answer)
                                .font(.title3.bold())
                            Text(MockData.reviewCard.meaning)
                                .multilineTextAlignment(.center)
                            Text("Natural English: \(MockData.reviewCard.naturalEnglish)")
                                .font(.subheadline)
                                .foregroundStyle(AppTheme.muted)

                            if let scheduleMessage {
                                Text(scheduleMessage)
                                    .font(.caption)
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
                        rating(language.text("重来", "もう一度"), .again)
                        rating(language.text("困难", "難しい"), .hard)
                        rating(language.text("良好", "良い"), .good)
                        rating(language.text("简单", "簡単"), .easy)
                    }
                } else {
                    Button {
                        scheduleMessage = nil
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
        .navigationTitle(language.text("复习", "復習"))
    }

    private func rating(_ text: String, _ value: ReviewRating) -> some View {
        Button(text) {
            do {
                let result = try ReviewRecorder().record(
                    cardID: MockData.reviewCard.id,
                    rating: value,
                    in: modelContext
                )
                reviewed = min(reviewed + 1, 20)
                scheduleMessage = language.text(
                    "已记录 · 下次约 \(result.scheduledDays) 天后复习",
                    "記録済み · 次回は約\(result.scheduledDays)日後"
                )
                saveError = nil
                revealed = false
            } catch {
                saveError = language.text("保存复习记录失败。", "復習記録の保存に失敗しました。")
            }
        }
        .buttonStyle(.bordered)
        .tint(AppTheme.accent)
        .frame(maxWidth: .infinity)
    }
}
