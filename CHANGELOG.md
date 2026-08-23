# CHANGELOG

## [0.2.0] - 2026-08-23
- Add typed media inspection backed by FFprobe.
- Add per-session progress streams and cancellation for long-running jobs.
- Add thumbnail extraction and accurate/fast video trimming helpers.

## [0.1.0] - 2026-08-23
- Upgrade the supported toolchain to Flutter 3.47.1 and Dart 3.13.1.
- Replace the retired FFmpegKit dependency with maintained Full-GPL
  `ffmpeg_kit_flutter_new` 4.6.2 while retaining `libx264` support.
- Upgrade Android to Gradle 9.3.1, AGP 9.1.0, Kotlin 2.4.0, Java 17, and API 24.
- Upgrade iOS deployment support to iOS 15, repair Swift Package Manager
  integration, and migrate the example away from legacy CocoaPods wiring.
- Pass FFmpeg arguments without reparsing paths, validate public inputs in
  release builds, and return accurate success/cancellation/failure messages.
- Remove broad storage permissions from the example and expand usage, license,
  testing, and release documentation.
- Add copy-paste usage examples, parameter/error guidance, troubleshooting, and
  a researched roadmap for progress, cancellation, metadata, and editing APIs.

## [0.0.4+1] - 2025-12-29
- Add Swift Package Manager support for iOS.
- Improve public API documentation coverage.
- Clean up example logging and async handling.

## [0.0.3+2] - 2025-12-29
- Add unit/integration test coverage and test helpers.
- Add coverage workflow, Makefile, and short docs.
- Update README with Codecov badge and usage links.

## [0.0.2] - 2025-03-05
- Finish version

## [0.0.1] - 2025-01-14
- Finish version
