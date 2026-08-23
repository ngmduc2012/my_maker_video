# MyMakerVideo usage

## 1. Add the dependencies

```sh
flutter pub add my_maker_video
flutter pub add path_provider
```

Requirements: Flutter 3.47.1+, Dart 3.13.1+, Android API 24+, and iOS 15+.

`path_provider` is used by this guide for safe output paths. MyMakerVideo does
not require it directly.

## 2. Choose input and output paths

Use a system file picker for input and an app-scoped directory for output. The
package does not need broad Android storage permissions or iOS photo-library
permission just to process paths supplied by the app.

```dart
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:my_maker_video/my_maker_video.dart';
import 'package:path_provider/path_provider.dart';

Future<Directory> getVideoOutputDirectory() async {
  final documents = await getApplicationDocumentsDirectory();
  return Directory('${documents.path}/my_maker_video').create(recursive: true);
}
```

If the application directly accesses a protected library, configure the narrow
permission required by that application feature.

## 3. Create a video from images

Name the PNG files consecutively: `1.png`, `2.png`, `3.png`, and so on. Do not
leave gaps, and prefer images with the same dimensions.

```dart
Future<String?> createVideoFromImages(String imagesDirectoryPath) async {
  final outputDirectory = await getVideoOutputDirectory();
  final outputPath = '${outputDirectory.path}/video.mp4';

  final result = await MyMakerVideo.ffmpegKit.convertImageDirectoryToVideo(
    imagesPath: imagesDirectoryPath,
    outputVideoPath: outputPath,
    framerate: 24,
    fps: 30,
    quality: 23,
  );

  if (!result.isSuccess) {
    debugPrint(result.message);
    return null;
  }

  return outputPath;
}
```

`framerate` and `fps` must be positive. Optional H.264 CRF `quality` accepts
1 to 51; lower values produce higher quality and usually a larger file. The
helper makes odd image dimensions even before encoding H.264.

## 4. Add a watermark

```dart
Future<String?> addWatermark({
  required String videoPath,
  required String watermarkPath,
}) async {
  final outputDirectory = await getVideoOutputDirectory();
  final outputPath = '${outputDirectory.path}/watermarked.mp4';

  final result = await MyMakerVideo.ffmpegKit.addWatermarkToVideo(
    watermarkPath: watermarkPath,
    videoPath: videoPath,
    outputPath: outputPath,
    x: 20,
    y: 30,
    width: 200,
    height: 200,
  );

  if (!result.isSuccess) {
    debugPrint(result.message);
    return null;
  }

  return outputPath;
}
```

Supply `width` and `height` together, or omit both. The `x` and `y`
coordinates are measured from the top-left corner. The watermark can be an
image or video, and the source audio is copied without re-encoding.

## 5. Reduce quality

```dart
Future<String?> reduceQuality(String videoPath) async {
  final outputDirectory = await getVideoOutputDirectory();
  final outputPath = '${outputDirectory.path}/reduced.mp4';

  final result =
      await MyMakerVideo.ffmpegKit.reduceVideoQualityByPercentage(
    inputPath: videoPath,
    outputPath: outputPath,
    qualityPercentage: 30,
  );

  if (!result.isSuccess) {
    debugPrint(result.message);
    return null;
  }

  return outputPath;
}
```

The percentage accepts 0 to 100. A higher value produces the higher-quality
output selected by this helper. It does not promise that the output file is
exactly that percentage of the input size.

## 6. Create a GIF

```dart
Future<String?> createGif(String videoPath) async {
  final outputDirectory = await getVideoOutputDirectory();
  final outputPath = '${outputDirectory.path}/preview.gif';

  final result = await MyMakerVideo.ffmpegKit.createGifFromVideo(
    inputPath: videoPath,
    outputPath: outputPath,
    quality: 10,
    scale: 320,
    fps: 2,
  );

  if (!result.isSuccess) {
    debugPrint(result.message);
    return null;
  }

  return outputPath;
}
```

GIF `quality` accepts 1 to 31; lower is clearer. `fps` and `scale` must be
positive.

## 7. Inspect media

```dart
Future<MediaInfo?> inspectVideo(String videoPath) async {
  final result = await MyMakerVideo.ffmpegKit.inspectMedia(
    inputPath: videoPath,
  );

  if (!result.isSuccess) {
    debugPrint(result.message);
    return null;
  }

  final info = result.mediaInfo!;
  debugPrint('Format: ${info.format}');
  debugPrint('Duration: ${info.duration}');
  debugPrint('Video codec: ${info.videoStream?.codec}');
  debugPrint('Audio codec: ${info.audioStream?.codec}');
  return info;
}
```

`MediaInfo.streams` contains every stream. Each `MediaStreamInfo` reports its
type, codec, bitrate, dimensions or sample rate, frame rate, rotation, and tags
when those values exist in the source.

## 8. Show progress and cancel one job

Use a `start...` method when the UI needs progress or a Cancel button:

```dart
Future<FfmpegResult> compressWithProgress({
  required String inputPath,
  required String outputPath,
  required void Function(double? percentage) onProgress,
}) async {
  final job = await MyMakerVideo.ffmpegKit
      .startReduceVideoQualityByPercentage(
    inputPath: inputPath,
    outputPath: outputPath,
    qualityPercentage: 50,
  );

  final subscription = job.progress.listen((value) {
    onProgress(value.percentage);
  });

  try {
    return await job.result;
  } finally {
    await subscription.cancel();
  }
}
```

Keep the returned `FfmpegJob` in widget state and call `await job.cancel()` from
the Cancel button. Cancellation targets that session only. `percentage` is
`null` when the input duration is unknown; `processedDuration`, frames, output
size, bitrate, FPS, and speed remain available.

The job API deletes partial output after failure or cancellation by default.
Set `deletePartialOutput: false` only when the application intentionally wants
to inspect or keep incomplete output.

## 9. Extract a thumbnail

```dart
final result = await MyMakerVideo.ffmpegKit.extractThumbnail(
  inputPath: videoPath,
  outputPath: '${outputDirectory.path}/thumbnail.jpg',
  position: const Duration(seconds: 2),
  width: 320,
);
```

The position cannot be negative. Use a `.jpg` or `.png` output path. Supplying
one dimension preserves aspect ratio; supplying both fits the thumbnail inside
the requested bounds.

## 10. Trim a video

Frame-accurate mode decodes and re-encodes the selected range:

```dart
final result = await MyMakerVideo.ffmpegKit.trimVideo(
  inputPath: videoPath,
  outputPath: '${outputDirectory.path}/trimmed.mp4',
  start: const Duration(seconds: 3),
  end: const Duration(seconds: 8),
  mode: VideoTrimMode.accurate,
  quality: 23,
);
```

Fast mode copies streams without generation loss:

```dart
final result = await MyMakerVideo.ffmpegKit.trimVideo(
  inputPath: videoPath,
  outputPath: '${outputDirectory.path}/trimmed-fast.mp4',
  start: const Duration(seconds: 3),
  duration: const Duration(seconds: 5),
  mode: VideoTrimMode.fast,
);
```

Supply exactly one of `duration` and `end`. Fast mode is quicker but can start
at a nearby keyframe and requires source codecs compatible with the output
container.

## 11. Handle validation and unexpected errors

```dart
Future<void> runSafely(Future<void> Function() operation) async {
  try {
    await operation();
  } on ArgumentError catch (error) {
    // ArgumentError also covers RangeError.
    debugPrint('Invalid option: $error');
  } catch (error, stackTrace) {
    debugPrint('Unexpected error: $error');
    debugPrintStack(stackTrace: stackTrace);
  }
}
```

Valid calls return `({bool isSuccess, String message})`. A false result includes
the FFmpeg return code and output when available. Invalid empty paths or invalid
parameter ranges throw before FFmpeg starts.

Existing output files are overwritten. Await one operation before starting
another operation that uses the same output file.

## 12. Parameter reference

| Method | Parameter | Range/default |
| --- | --- | --- |
| Images to video | `framerate` | Positive; default `24` |
| Images to video | `fps` | Positive or `null` |
| Images to video | `quality` | H.264 CRF `1..51` or `null` |
| Watermark | `width`, `height` | Both positive or both omitted |
| Reduce quality | `qualityPercentage` | Finite `0..100` |
| Video to GIF | `fps` | Positive finite value |
| Video to GIF | `quality` | `1..31`; lower is clearer |
| Video to GIF | `scale` | Positive width; default `320` |
| Thumbnail | `position` | Zero or positive duration |
| Thumbnail | `width`, `height` | Positive or omitted |
| Trim | `start` | Zero or positive duration |
| Trim | `duration` / `end` | Exactly one valid range boundary |
| Accurate trim | `quality` | H.264 CRF `1..51`; default `23` |

## 13. Storage checklist

- Use a system picker for input files.
- Prefer an app-scoped output directory.
- Do not request `MANAGE_EXTERNAL_STORAGE` for this package.
- Request photo-library access only when your own app feature directly browses
  that library.
- Keep `.mp4` for video output and `.gif` for GIF output.
- Copy a picked file into app storage if the platform gives only temporary
  access to its original URI.

## 14. Full-GPL dependency

MyMakerVideo uses the Full-GPL `ffmpeg_kit_flutter_new` package to retain
`libx264`. Review its GPL terms before distributing an application.

## 15. Next features

See [FEATURE_ROADMAP.md](FEATURE_ROADMAP.md) for implementation status and the
next researched additions: clearer compression presets, resize/crop/rotate,
merge, audio operations, and higher-quality GIF palettes.
