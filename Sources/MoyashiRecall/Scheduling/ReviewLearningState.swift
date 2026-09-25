import Foundation

public enum ReviewLearningState: String, Codable, Sendable {
    case new
    case learning
    case review
    case relearning
}
