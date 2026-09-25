// swift-tools-version: 5.9
import PackageDescription

#if os(Linux)
let package = Package(
    name: "MoyashiRecall",
    products: [
        .library(name: "MoyashiRecall", targets: ["MoyashiRecall"])
    ],
    targets: [
        .target(
            name: "MoyashiRecall",
            path: "Sources/MoyashiRecall",
            sources: [
                "Scheduling/ReviewLearningState.swift",
                "Scheduling/FSRSScheduler.swift",
                "Models/LearningModels.swift",
                "Core/Networking/HTTPTransport.swift",
                "Core/Networking/AIHTTPRetryPolicy.swift",
                "AI/AICompletionProvider.swift",
                "AI/AIProviderConfiguration.swift",
                "AI/KnowledgeExtractionModels.swift",
                "AI/KnowledgeExtractionService.swift",
                "AI/DocumentChunker.swift",
                "AI/OpenAIResponsesProvider.swift",
                "AI/AnthropicMessagesProvider.swift",
                "Sources/LearningContentSource.swift",
                "Sources/SourceKeyResolver.swift",
                "Sources/Notion/NotionAPIClient.swift",
                "Features/StudyScope/StudyScopePreferences.swift",
                "Features/StudyScope/StudyPresetStore.swift",
                "Features/Review/ReviewSessionSummaryStore.swift",
                "Speech/JapaneseSpeechText.swift"
            ]
        ),
        .testTarget(
            name: "MoyashiRecallTests",
            dependencies: ["MoyashiRecall"],
            path: "Tests/MoyashiRecallTests",
            sources: [
                "FSRSSchedulerTests.swift",
                "NotionAPIClientTests.swift",
                "SourceKeyResolverTests.swift",
                "AIExtractionCoreTests.swift",
                "DocumentChunkerTests.swift",
                "OpenAIResponsesProviderTests.swift",
                "AnthropicMessagesProviderTests.swift",
                "AIHTTPRetryPolicyTests.swift",
                "AIProviderConfigurationTests.swift",
                "StudyScopePreferencesTests.swift",
                "StudyPresetStoreTests.swift",
                "ReviewSessionSummaryStoreTests.swift",
                "JapaneseSpeechTextTests.swift"
            ]
        )
    ]
)
#else
let package = Package(
    name: "MoyashiRecall",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(name: "MoyashiRecall", targets: ["MoyashiRecall"])
    ],
    targets: [
        .target(name: "MoyashiRecall"),
        .testTarget(
            name: "MoyashiRecallTests",
            dependencies: ["MoyashiRecall"]
        )
    ]
)
#endif
