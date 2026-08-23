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

## 7. Handle validation and unexpected errors

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

## 8. Parameter reference

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

## 9. Storage checklist

- Use a system picker for input files.
- Prefer an app-scoped output directory.
- Do not request `MANAGE_EXTERNAL_STORAGE` for this package.
- Request photo-library access only when your own app feature directly browses
  that library.
- Keep `.mp4` for video output and `.gif` for GIF output.
- Copy a picked file into app storage if the platform gives only temporary
  access to its original URI.

## 10. Full-GPL dependency

MyMakerVideo uses the Full-GPL `ffmpeg_kit_flutter_new` package to retain
`libx264`. Review its GPL terms before distributing an application.

## 11. Next features

See [FEATURE_ROADMAP.md](FEATURE_ROADMAP.md) for the researched roadmap. The
recommended first additions are media metadata, progress/cancellation,
thumbnail extraction, trimming, and clearer compression presets.
