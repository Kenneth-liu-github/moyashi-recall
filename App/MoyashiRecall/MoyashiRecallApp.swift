import SwiftUI
import SwiftData
import MoyashiRecall

@main
struct MoyashiRecallApp: App {
    private let modelContainer: ModelContainer?

    init() {
        modelContainer = try? MoyashiRecallModelContainerFactory
            .makeDefault()
    }

    var body: some Scene {
        WindowGroup {
            if let modelContainer {
                MoyashiRecallRootView()
                    .modelContainer(modelContainer)
            } else {
                ContentUnavailableView {
                    Label(
                        "无法打开学习数据",
                        systemImage: "exclamationmark.triangle"
                    )
                } description: {
                    Text(
                        "Moyashi Recall 无法安全打开本地数据库。"
                        + " 请不要删除 App；请先保留现有数据并检查迁移问题。"
                    )
                }
            }
        }
    }
}
