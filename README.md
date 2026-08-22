# MultiCamStudio

A dual-camera app for iOS. One `AVCaptureMultiCamSession` runs the back and front cameras at the
same time.

- **Camera** — live preview of both lenses. Photo mode takes a back photo, then a front photo.
  Video mode records both cameras simultaneously, with audio.
- **Feed** — every capture in a grid. Tap a photo capture for a larger view; tap a video capture to
  play both movies in sync.

Captures are stored in the app container and indexed with SwiftData. The Photos library is never
touched.

## Requirements

- iOS 17.6 or later
- Xcode 26


### Optional tooling

```bash
brew install swiftlint swift-format
```

## Demo

- [`recording.MP4`](recording.MP4)
- [Project walkthrough on Loom](https://www.loom.com/share/936208edc9b84d76bb681ed567ebbf2d)
