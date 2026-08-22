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

`scripts/lint.sh` and `scripts/format.sh` run them. A pre-commit hook lives in `.githooks/`; link it
with `ln -s ../../.githooks/pre-commit .git/hooks/pre-commit`.

## Demo

Recording and Loom link — coming soon.
