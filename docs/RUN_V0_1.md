# Run V0.1 on a Mac

The current repository is structured as a Swift Package so the feature code can be compiled and tested continuously while the product UI evolves.

## Requirements
- macOS
- Xcode 16 or newer

## Validate the code
From the repository folder:
```bash
swift build
swift test
```

## iPhone/iPad simulator target

The next packaging step is the native Xcode application target. The reusable SwiftUI feature code already lives in `Sources/MoyashiRecall`. The app entry point is `MoyashiRecallApp.swift`.

Product baseline:
- iOS/iPadOS 17+
- SwiftUI
- Chinese UI by default
- Japanese UI optional
