import Foundation
#if canImport(AVFoundation)
import AVFoundation
import Combine

@MainActor
public final class JapaneseSpeechService: ObservableObject {
    private let synthesizer = AVSpeechSynthesizer()

    public init() {}

    public func speak(
        _ text: String,
        rate: JapaneseSpeechRate = .normal
    ) {
        let normalized = JapaneseSpeechText.normalized(
            text
        )
        guard !normalized.trimmingCharacters(
            in: .whitespacesAndNewlines
        ).isEmpty else {
            return
        }

        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(
                at: .immediate
            )
        }

        let utterance = AVSpeechUtterance(
            string: normalized
        )
        utterance.voice = AVSpeechSynthesisVoice(
            language: "ja-JP"
        )
        let adjustedRate =
            AVSpeechUtteranceDefaultSpeechRate
            * Float(rate.multiplier)
        utterance.rate = min(
            max(
                adjustedRate,
                AVSpeechUtteranceMinimumSpeechRate
            ),
            AVSpeechUtteranceMaximumSpeechRate
        )
        synthesizer.speak(utterance)
    }

    public func stop() {
        synthesizer.stopSpeaking(
            at: .immediate
        )
    }
}
#endif
