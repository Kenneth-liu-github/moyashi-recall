# Run Moyashi Recall V0.1

V0.1 now includes a native iOS/iPadOS Xcode application target plus a reusable Swift Package.

## Requirements
- macOS
- Xcode 16 or newer
- iOS Simulator

## Open and run the app
1. Clone or pull this repository.
2. Open `App/MoyashiRecall.xcodeproj` in Xcode.
3. Select the shared scheme `MoyashiRecall`.
4. Select an iPhone simulator (iOS 17+).
5. Press Run.

Simulator builds do not require Apple code signing. A physical iPhone/iPad will require a development team/signing configuration.

## Validate the reusable package
From the repository root:

```bash
swift build
swift test
```

## Continuous integration
GitHub Actions validates both:
- reusable Swift Package build + unit tests
- native iOS Simulator build

## Product baseline
- iPhone + iPad
- iOS/iPadOS 17+
- SwiftUI
- Chinese UI by default
- Japanese UI optional in Settings
- cold minimal visual system: white / black-gray / one blue accent
