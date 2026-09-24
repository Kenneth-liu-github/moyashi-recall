import SwiftUI

/// Native app entry point.
///
/// This file is excluded from the Swift Package library build and is used by
/// the Xcode iOS/iPadOS application target. Keeping the reusable feature code
/// in the package lets CI validate the UI/domain modules independently.
@main
struct MoyashiRecallApp: App {
    var body: some Scene {
        WindowGroup {
            MoyashiRecallRootView()
        }
    }
}
