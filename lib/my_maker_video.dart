/// Flutter video processing helpers backed by FFmpegKit.
///
/// Use [MyMakerVideo.ffmpegKit] for image-to-video, watermark, quality,
/// and GIF helpers.
library;

import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:flutter/foundation.dart';

part 'src/ffmpeg_kit.dart';

/// Entry point for MyMakerVideo helpers.
class MyMakerVideo {
  /// Prevent instantiation.
  MyMakerVideo._();

  /// Shared FFmpeg helper instance.
  static const $FfmpegKit ffmpegKit = $FfmpegKit();
}
