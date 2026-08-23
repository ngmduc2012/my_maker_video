[![codecov](https://codecov.io/gh/ngmduc2012/my_maker_video/branch/main/graph/badge.svg)](https://codecov.io/gh/ngmduc2012/my_maker_video)
[![GitHub](https://img.shields.io/badge/Nguyen_Duc-GitHub-black?logo=github)](https://github.com/ngmduc2012)
_[![Buy Me A Coffee](https://img.shields.io/badge/Donate-Buy_Me_A_Coffee-blue?logo=buymeacoffee)](https://www.buymeacoffee.com/ducmng12g)_
_[![PayPal](https://img.shields.io/badge/Donate-PayPal-blue?logo=paypal)](https://paypal.me/ngmduc)_
_[![Sponsor](https://img.shields.io/badge/Sponsor-Become_A_Sponsor-blue?logo=githubsponsors)](https://github.com/sponsors/ngmduc2012)_
_[![Support Me on Ko-fi](https://img.shields.io/badge/Donate-Ko_fi-red?logo=ko-fi)](https://ko-fi.com/I2I81AEJG8)_

# MyMakerVideo

Inspect and edit media, create an MP4 from a numbered PNG sequence, add an
image/video watermark, reduce video quality, or convert a video to GIF from
Flutter.

MyMakerVideo supports Android and iOS and uses a maintained Full-GPL FFmpegKit
build with `libx264`.

## Requirements

- Flutter 3.47.1 or newer
- Dart 3.13.1 or newer
- Android API 24 or newer
- iOS 15.0 or newer

## Installation

Run:

```sh
flutter pub add my_maker_video
flutter pub add path_provider
```

Then import the packages:

```dart
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:my_maker_video/my_maker_video.dart';
import 'package:path_provider/path_provider.dart';
```

`path_provider` is only used in the examples below to create an app-scoped
output directory. It is not a dependency of MyMakerVideo.

## Storage and permissions

MyMakerVideo only reads and writes the file paths supplied by your app. It does
not require Android `MANAGE_EXTERNAL_STORAGE`, legacy read/write storage
permissions, or iOS photo-library permission by itself.

Prefer files returned by a system picker and write output to an app-scoped
directory such as the directory returned by `path_provider`. If your app itself
opens the photo library or another protected source, declare only the permission
required by that feature.

## Quick start

Every helper returns `({bool isSuccess, String message})`. Always `await` the
operation and check the result:

```dart
Future<Directory> createVideoOutputDirectory() async {
  final documents = await getApplicationDocumentsDirectory();
  return Directory('${documents.path}/my_maker_video').create(recursive: true);
}

Future<String?> createSlideshow(String imagesDirectoryPath) async {
  final outputDirectory = await createVideoOutputDirectory();
  final outputPath = '${outputDirectory.path}/slideshow.mp4';

  try {
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
  } on ArgumentError catch (error) {
    debugPrint('Invalid video option: $error');
    return null;
  }
}
```

The image directory must contain a consecutive numbered PNG sequence such as
`1.png`, `2.png`, and `3.png`. Do not leave gaps in the sequence. Images should
use the same dimensions for predictable output.

| Parameter | Accepted value | Meaning |
| --- | --- | --- |
| `framerate` | Positive integer | Number of input images shown each second |
| `fps` | Positive integer or `null` | Optional output frame rate |
| `quality` | `1` to `51` or `null` | H.264 CRF; lower is clearer and usually larger |

The output is H.264 MP4 with even dimensions, `yuv420p` pixel format, and
fast-start metadata for broad player compatibility.

## Inspect media

Read container and stream information before processing a file:

```dart
final result = await MyMakerVideo.ffmpegKit.inspectMedia(
  inputPath: inputVideoPath,
);

if (result.isSuccess) {
  final info = result.mediaInfo!;
  debugPrint('Duration: ${info.duration}');
  debugPrint('Video: ${info.videoStream?.codec} '
      '${info.videoStream?.width}x${info.videoStream?.height}');
  debugPrint('Audio: ${info.audioStream?.codec}');
}
```

`MediaInfo` includes format, duration, size, bitrate, tags, and typed audio,
video, subtitle, and data streams. Video streams include dimensions, frame
rate, and rotation metadata when FFprobe can determine them.

## Progress and cancellation

Every existing operation has a `start...` variant that returns an independent
`FfmpegJob`:

```dart
final job = await MyMakerVideo.ffmpegKit
    .startReduceVideoQualityByPercentage(
  inputPath: inputVideoPath,
  outputPath: outputVideoPath,
  qualityPercentage: 50,
);

final subscription = job.progress.listen((progress) {
  debugPrint('${progress.percentage?.toStringAsFixed(1)}%');
});

// Call this from a Cancel button when needed:
// await job.cancel();

final result = await job.result;
await subscription.cancel();
```

Available job methods are `startConvertImageDirectoryToVideo`,
`startAddWatermarkToVideo`, `startReduceVideoQualityByPercentage`,
`startCreateGifFromVideo`, `startExtractThumbnail`, and `startTrimVideo`.
Progress percentage is `null` when total duration cannot be determined. Failed
and cancelled jobs delete partial output by default; pass
`deletePartialOutput: false` to keep it.

## Add a watermark

```dart
final result = await MyMakerVideo.ffmpegKit.addWatermarkToVideo(
  videoPath: inputVideoPath,
  watermarkPath: watermarkPath,
  outputPath: outputVideoPath,
  x: 20,
  y: 30,
  width: 200,
  height: 200,
);
```

Pass both `width` and `height` to resize the watermark, or omit both to keep its
original size. Coordinates start at the top-left corner of the video. The input
audio stream is copied to the output without re-encoding.

## Reduce video quality

```dart
final result =
    await MyMakerVideo.ffmpegKit.reduceVideoQualityByPercentage(
  inputPath: inputVideoPath,
  outputPath: outputVideoPath,
  qualityPercentage: 30,
);
```

`qualityPercentage` accepts 0 to 100, where 100 keeps the highest quality used
by this helper and 0 produces the lowest. This is a convenient quality scale,
not an estimate of the final file-size reduction.

## Create a GIF

```dart
final result = await MyMakerVideo.ffmpegKit.createGifFromVideo(
  inputPath: inputVideoPath,
  outputPath: outputGifPath,
  fps: 2,
  quality: 10,
  scale: 320,
);
```

GIF `quality` accepts 1 to 31; a lower value means higher quality. `fps` and
`scale` must be greater than zero.

## Extract a thumbnail

```dart
final result = await MyMakerVideo.ffmpegKit.extractThumbnail(
  inputPath: inputVideoPath,
  outputPath: outputJpegPath,
  position: const Duration(seconds: 2),
  width: 320,
);
```

Use a `.jpg` or `.png` output path. Supply only `width` or `height` to preserve
the original aspect ratio, or supply both to fit inside that bounding box.

## Trim a video

Accurate mode re-encodes the selected range and is the default:

```dart
final result = await MyMakerVideo.ffmpegKit.trimVideo(
  inputPath: inputVideoPath,
  outputPath: outputVideoPath,
  start: const Duration(seconds: 2),
  duration: const Duration(seconds: 5),
  mode: VideoTrimMode.accurate,
  quality: 23,
);
```

Supply exactly one of `duration` and `end`. Use `VideoTrimMode.fast` to copy
streams without re-encoding. Fast mode is lossless and much quicker, but its
start can move to a nearby keyframe and the input streams must be compatible
with the output container.

## Results and errors

- A valid FFmpeg operation returns a result record. Check `isSuccess`; when it
  is false, `message` contains cancellation/failure information and FFmpeg
  output when available.
- Invalid paths or parameter ranges throw `ArgumentError` or `RangeError`
  before native processing starts. Catch `ArgumentError` at your UI boundary
  if values can come from users.
- Output files are overwritten when they already exist.
- Paths containing spaces and quote characters are passed to FFmpeg as
  individual arguments.
- Processing is asynchronous, but video encoding is CPU-intensive. Disable
  duplicate submit actions in the UI until the returned future completes.

## Common problems

### The image sequence cannot be read

Check that the directory exists, every file is a PNG, names are consecutive
numbers, and your app can read each path.

### FFmpeg returns a codec or container error

Keep the output extension consistent with the intended format (`.mp4` for
video and `.gif` for GIF). Some source audio codecs cannot be copied into every
container; the returned FFmpeg log contains the exact cause.

### The app cannot access a selected file

Use a system picker and copy the selected file to an app-scoped directory when
the platform only grants temporary access. The package does not request storage
or photo-library permissions on behalf of the app.

See [the step-by-step guide](doc/USAGE.md) for complete examples and
[the feature roadmap](doc/FEATURE_ROADMAP.md) for planned progress, metadata,
editing, audio, and GIF improvements.

## License notice

The Dart wrapper in this repository is MIT licensed. Its
`ffmpeg_kit_flutter_new` dependency is a Full-GPL FFmpeg build because these
helpers require `libx264`. Review the dependency's GPL terms and your app's
distribution obligations before release. This notice is not legal advice.

For more background, see the original article:
[FFmpeg Flutter](https://wong-coupon.gitbook.io/flutter/media/ffmpeg-flutter).

## Developer team

- [ThaoDoan](https://github.com/mia140602)
- [DucNguyen](https://github.com/ngmduc2012)
