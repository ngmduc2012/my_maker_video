# Maintainer operations

## First run

```sh
make init
make verify
```

`make verify` checks formatting, analyzes the package and example, runs Dart and
native Android tests/lint, and builds Android and iOS examples.

## Integration test

Connect an Android or iOS device/emulator, then run:

```sh
cd example
flutter test integration_test/video_flow_test.dart -d <device-id>
```

This test executes real FFmpeg commands and verifies the generated files.

## Prepare a pub.dev release

1. Update `version` in `pubspec.yaml`.
2. Move the `Unreleased` changelog entries under the new version.
3. Run `make verify`.
4. Run `make publish-dry-run` and review every packaged file.
5. Commit and push the reviewed changes.
6. Run `dart pub publish` only after explicit release approval.

The repository does not provide an automatic `git add`, commit, push, or
publish target. Release operations remain deliberate and reviewable.
