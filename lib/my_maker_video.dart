/// Flutter video processing helpers backed by FFmpegKit.
///
/// Use [MyMakerVideo.ffmpegKit] for media inspection, progress/cancellation,
/// image-to-video, watermark, thumbnail, trim, quality, and GIF helpers.
library;

import 'dart:async';
import 'dart:io';

import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/ffprobe_kit.dart';
import 'package:flutter/foundation.dart';

part 'src/media_info.dart';
part 'src/video_job.dart';
part 'src/ffmpeg_kit.dart';

/// Entry point for MyMakerVideo helpers.
class MyMakerVideo {
  /// Prevent instantiation.
  MyMakerVideo._();

  /// Shared FFmpeg helper instance.
  static const $FfmpegKit ffmpegKit = $FfmpegKit();
}
