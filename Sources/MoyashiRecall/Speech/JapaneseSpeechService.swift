import Foundation
#if canImport(AVFoundation)
import AVFoundation

@MainActor
public final class JapaneseSpeechService: ObservableObject {
    private let synthesizer = AVSpeechSynthesizer()

    public init() {}

    public func speak(
        _ text: String
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
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate
        synthesizer.speak(utterance)
    }

    public func stop() {
        synthesizer.stopSpeaking(
            at: .immediate
        )
    }
}
#endif
