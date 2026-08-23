part of '../my_maker_video.dart';

/// Signature for executing an FFmpeg command.
typedef FfmpegExecuteFn = Future<dynamic> Function(String command);

/// Signature for executing an FFmpeg argument list without reparsing paths.
typedef FfmpegExecuteArgumentsFn = Future<dynamic> Function(
  List<String> arguments,
);

/// Signature for starting an asynchronous FFmpeg argument list.
typedef FfmpegExecuteArgumentsAsyncFn = Future<dynamic> Function(
  List<String> arguments,
  void Function(dynamic session)? completeCallback,
  void Function(dynamic statistics)? statisticsCallback,
);

/// Minimal session interface for FFmpeg results.
abstract class FfmpegSession {
  /// Returns the underlying FFmpeg return code.
  Future<dynamic> getReturnCode();

  /// Returns the FFmpeg command output, if any.
  Future<String?> getOutput();
}

/// Optional capability implemented by sessions that can be cancelled.
abstract class CancellableFfmpegSession {
  /// Returns the native session identifier when available.
  int? getSessionId();

  /// Requests cancellation of this session.
  Future<void> cancel();
}

/// Runs an FFmpeg command and returns a session.
abstract class FfmpegExecutor {
  /// Default executor constructor.
  const FfmpegExecutor();

  /// Executes the given command and returns a session.
  Future<FfmpegSession> execute(String command);

  /// Executes FFmpeg with pre-split [arguments].
  ///
  /// Existing custom executors only need to implement [execute]. The default
  /// implementation serializes the arguments for backwards compatibility.
  Future<FfmpegSession> executeWithArguments(List<String> arguments) {
    return execute(_commandFromArguments(arguments));
  }
}

/// Optional capability implemented by executors with asynchronous callbacks.
abstract class AsyncFfmpegExecutor {
  /// Starts FFmpeg with per-session completion and statistics callbacks.
  Future<FfmpegSession> executeWithArgumentsAsync(
    List<String> arguments, {
    void Function(FfmpegSession session)? onComplete,
    void Function(FfmpegStatistics statistics)? onStatistics,
  });
}

/// Wraps the native FFmpegKit session.
class FfmpegKitSession implements FfmpegSession, CancellableFfmpegSession {
  /// Creates an adapter around the native session.
  FfmpegKitSession(this._session);

  final dynamic _session;

  @override
  Future<dynamic> getReturnCode() => _session.getReturnCode();

  @override
  Future<String?> getOutput() => _session.getOutput();

  @override
  int? getSessionId() => _session.getSessionId();

  @override
  Future<void> cancel() => _session.cancel();
}

/// Default executor that delegates to FFmpegKit.
class FfmpegKitExecutor implements FfmpegExecutor, AsyncFfmpegExecutor {
  /// Creates a default FFmpegKit executor.
  const FfmpegKitExecutor();

  /// Overridable entrypoint for tests.
  @visibleForTesting
  static FfmpegExecuteFn executeImpl = FFmpegKit.execute;

  /// Overridable argument-list entrypoint for tests.
  @visibleForTesting
  static FfmpegExecuteArgumentsFn executeWithArgumentsImpl =
      FFmpegKit.executeWithArguments;

  /// Overridable asynchronous entrypoint for tests.
  @visibleForTesting
  static FfmpegExecuteArgumentsAsyncFn executeWithArgumentsAsyncImpl =
      (arguments, completeCallback, statisticsCallback) {
        return FFmpegKit.executeWithArgumentsAsync(
          arguments,
          completeCallback == null
              ? null
              : (session) => completeCallback(session),
          null,
          statisticsCallback == null
              ? null
              : (statistics) => statisticsCallback(statistics),
        );
      };

  @override
  Future<FfmpegSession> execute(String command) async {
    final session = await executeImpl(command);
    return FfmpegKitSession(session);
  }

  @override
  Future<FfmpegSession> executeWithArguments(List<String> arguments) async {
    final session = await executeWithArgumentsImpl(arguments);
    return FfmpegKitSession(session);
  }

  @override
  Future<FfmpegSession> executeWithArgumentsAsync(
    List<String> arguments, {
    void Function(FfmpegSession session)? onComplete,
    void Function(FfmpegStatistics statistics)? onStatistics,
  }) async {
    final session = await executeWithArgumentsAsyncImpl(
      arguments,
      onComplete == null
          ? null
          : (nativeSession) => onComplete(FfmpegKitSession(nativeSession)),
      onStatistics == null
          ? null
          : (statistics) => onStatistics(FfmpegKitStatistics(statistics)),
    );
    return FfmpegKitSession(session);
  }
}

/// High-level helpers built on top of FFmpegKit.
class $FfmpegKit {
  /// Creates a helper with an optional custom executor (for tests).
  const $FfmpegKit({
    FfmpegExecutor executor = const FfmpegKitExecutor(),
    FfmpegProbeExecutor probeExecutor = const FfmpegKitProbeExecutor(),
  }) : this._(executor, probeExecutor);

  const $FfmpegKit._(this._executor, this._probeExecutor);

  final FfmpegExecutor _executor;
  final FfmpegProbeExecutor _probeExecutor;
  /*
   Learn more: https://pub.dev/packages/ffmpeg_kit_flutter_new

   The maintained package bundles the Full-GPL build because these helpers use
   libx264. Applications using this package must comply with the GPL terms.

   Thay thế cho thư viện gify https://pub.dev/packages/gify, gify sử dụng các tương tự nhưng khá chậm
*/

  /// Inspects a media file with FFprobe and returns typed information.
  Future<MediaInfoResult> inspectMedia({required String inputPath}) async {
    _validatePath(inputPath, 'inputPath');

    try {
      final session = await _probeExecutor.inspect(inputPath);
      final properties = session.getMediaProperties();
      if (properties != null) {
        return MediaInfoResult(
          isSuccess: true,
          message: 'Media inspection successful!',
          mediaInfo: _parseMediaInfo(inputPath, properties),
        );
      }

      final returnCode = await session.getReturnCode();
      final output = await session.getOutput();
      final logSuffix = output == null || output.trim().isEmpty
          ? ''
          : ' | FFprobe log: $output';
      return MediaInfoResult(
        isSuccess: false,
        message:
            'Media inspection failed with return code '
            '$returnCode$logSuffix',
      );
    } catch (error) {
      return MediaInfoResult(
        isSuccess: false,
        message: 'Media inspection failed: $error',
      );
    }
  }

  /// Creates a video from a numbered PNG sequence in [imagesPath].
  ///
  /// NOTE: mp4 in this function can not play normal on web.

  Future<({bool isSuccess, String message})> convertImageDirectoryToVideo({
    required String imagesPath,
    required String outputVideoPath,
    int framerate = 24,
    int? fps,
    int? quality,
  }) async {
    _validatePath(imagesPath, 'imagesPath');
    _validatePath(outputVideoPath, 'outputVideoPath');
    _validatePositive(framerate, 'framerate');
    if (fps != null) _validatePositive(fps, 'fps');
    if (quality != null) {
      RangeError.checkValueInInterval(quality, 1, 51, 'quality');
    }

    // final command = '-framerate $framerate -i $imagesPath/%d.png '
    //     '-c:v libx264 -pix_fmt yuv420p -movflags +faststart $outputVideoPath';

    /*
    -vf "scale=trunc(iw/2)*2:trunc(ih/2)*2": This filter scales the width (iw) and height (ih) of the images to the nearest even number, ensuring they are divisible by 2. This adjustment is necessary for compatibility with the H.264 encoder.
     */
    final arguments = <String>[
      '-y',
      '-framerate',
      '$framerate',
      '-i',
      '${_withoutTrailingSeparator(imagesPath)}/%d.png',
      if (fps != null) ...['-r', '$fps'],
      if (quality != null) ...['-crf', '$quality', '-preset', 'slow'],
      '-vf',
      'scale=trunc(iw/2)*2:trunc(ih/2)*2',
      // '-vf', 'scale=3200:-1:flags=lanczos',
      '-c:v',
      'libx264',
      '-pix_fmt',
      'yuv420p',
      '-movflags',
      '+faststart',
      outputVideoPath,
    ];

    return _run(
      arguments,
      operation: 'Video conversion',
      successMessage: 'Video conversion successful!',
    );
  }

  /// Starts image-to-video conversion with progress and cancellation.
  Future<FfmpegJob> startConvertImageDirectoryToVideo({
    required String imagesPath,
    required String outputVideoPath,
    int framerate = 24,
    int? fps,
    int? quality,
    bool deletePartialOutput = true,
  }) async {
    _validatePath(imagesPath, 'imagesPath');
    _validatePath(outputVideoPath, 'outputVideoPath');
    _validatePositive(framerate, 'framerate');
    if (fps != null) _validatePositive(fps, 'fps');
    if (quality != null) {
      RangeError.checkValueInInterval(quality, 1, 51, 'quality');
    }

    final arguments = <String>[
      '-y',
      '-framerate',
      '$framerate',
      '-i',
      '${_withoutTrailingSeparator(imagesPath)}/%d.png',
      if (fps != null) ...['-r', '$fps'],
      if (quality != null) ...['-crf', '$quality', '-preset', 'slow'],
      '-vf',
      'scale=trunc(iw/2)*2:trunc(ih/2)*2',
      '-c:v',
      'libx264',
      '-pix_fmt',
      'yuv420p',
      '-movflags',
      '+faststart',
      outputVideoPath,
    ];

    return _startJob(
      arguments,
      operation: 'Video conversion',
      successMessage: 'Video conversion successful!',
      outputPath: outputVideoPath,
      protectedInputPaths: [imagesPath],
      totalDuration: await _imageSequenceDuration(imagesPath, framerate),
      deletePartialOutput: deletePartialOutput,
    );
  }

  /// Adds a watermark image/video to an existing video.
  Future<({bool isSuccess, String message})> addWatermarkToVideo({
    required String videoPath,
    required String watermarkPath,
    required String outputPath,
    required int x, // Vị trí watermark trên trục X
    required int y, // Vị trí watermark trên trục Y
    int? width, // Chiều rộng watermark (nếu muốn thay đổi kích thước)
    int? height, // Chiều cao watermark (nếu muốn thay đổi kích thước)
  }) async {
    _validatePath(videoPath, 'videoPath');
    _validatePath(watermarkPath, 'watermarkPath');
    _validatePath(outputPath, 'outputPath');
    if ((width == null) != (height == null)) {
      throw ArgumentError('width and height must be provided together.');
    }
    if (width != null) _validatePositive(width, 'width');
    if (height != null) _validatePositive(height, 'height');

    // Lệnh FFmpeg
    final scaleFilter = (width != null && height != null)
        ? "[1:v]scale=$width:$height[wm];[0:v][wm]overlay=$x:$y"
        : "overlay=$x:$y";
    final arguments = <String>[
      '-y',
      '-i',
      videoPath,
      '-i',
      watermarkPath,
      '-filter_complex',
      scaleFilter,
      '-codec:a',
      'copy',
      outputPath,
    ];

    return _run(
      arguments,
      operation: 'Add watermark',
      successMessage: 'Watermark added successfully!',
    );
  }

  /// Starts watermark processing with progress and cancellation.
  Future<FfmpegJob> startAddWatermarkToVideo({
    required String videoPath,
    required String watermarkPath,
    required String outputPath,
    required int x,
    required int y,
    int? width,
    int? height,
    bool deletePartialOutput = true,
  }) async {
    _validatePath(videoPath, 'videoPath');
    _validatePath(watermarkPath, 'watermarkPath');
    _validatePath(outputPath, 'outputPath');
    if ((width == null) != (height == null)) {
      throw ArgumentError('width and height must be provided together.');
    }
    if (width != null) _validatePositive(width, 'width');
    if (height != null) _validatePositive(height, 'height');

    final scaleFilter = (width != null && height != null)
        ? '[1:v]scale=$width:$height[wm];[0:v][wm]overlay=$x:$y'
        : 'overlay=$x:$y';
    final arguments = <String>[
      '-y',
      '-i',
      videoPath,
      '-i',
      watermarkPath,
      '-filter_complex',
      scaleFilter,
      '-codec:a',
      'copy',
      outputPath,
    ];

    return _startJob(
      arguments,
      operation: 'Add watermark',
      successMessage: 'Watermark added successfully!',
      outputPath: outputPath,
      protectedInputPaths: [videoPath, watermarkPath],
      totalDuration: await _tryInspectDuration(videoPath),
      deletePartialOutput: deletePartialOutput,
    );
  }

  /// Reduces video quality using a percentage mapped to CRF/bitrate.
  Future<({bool isSuccess, String message})> reduceVideoQualityByPercentage({
    required String inputPath,
    required String outputPath,
    required double qualityPercentage,
  }) async {
    _validatePath(inputPath, 'inputPath');
    _validatePath(outputPath, 'outputPath');
    if (!qualityPercentage.isFinite ||
        qualityPercentage < 0 ||
        qualityPercentage > 100) {
      throw RangeError.range(qualityPercentage, 0, 100, 'qualityPercentage');
    }

    // Map the quality percentage to a CRF value
    // Assuming 100% quality maps to CRF 18 (high quality) and 0% maps to CRF 51 (very low quality)
    final crfValue = (51 - 18) * (1 - qualityPercentage / 100) + 18;
    final preset = 'fast'; // Use a faster preset for quicker processing

    // Optionally, adjust the bitrate based on quality percentage
    // Assuming 100% quality maps to a high bitrate and 0% to a low bitrate
    final maxBitrate = 5000; // Example max bitrate in kbps
    final minBitrate = 500; // Example min bitrate in kbps
    final bitrate =
        ((maxBitrate - minBitrate) * (qualityPercentage / 100) + minBitrate)
            .toInt();

    final arguments = <String>[
      '-y',
      '-i',
      inputPath,
      '-crf',
      '${crfValue.toInt()}',
      '-preset',
      preset,
      '-b:v',
      '${bitrate}k',
      '-codec:a',
      'copy',
      outputPath,
    ];

    return _run(
      arguments,
      operation: 'Reduce video quality',
      successMessage: 'Video quality reduced successfully!',
    );
  }

  /// Starts quality reduction with progress and cancellation.
  Future<FfmpegJob> startReduceVideoQualityByPercentage({
    required String inputPath,
    required String outputPath,
    required double qualityPercentage,
    bool deletePartialOutput = true,
  }) async {
    _validatePath(inputPath, 'inputPath');
    _validatePath(outputPath, 'outputPath');
    if (!qualityPercentage.isFinite ||
        qualityPercentage < 0 ||
        qualityPercentage > 100) {
      throw RangeError.range(qualityPercentage, 0, 100, 'qualityPercentage');
    }

    final crfValue = (51 - 18) * (1 - qualityPercentage / 100) + 18;
    final maxBitrate = 5000;
    final minBitrate = 500;
    final bitrate =
        ((maxBitrate - minBitrate) * (qualityPercentage / 100) + minBitrate)
            .toInt();
    final arguments = <String>[
      '-y',
      '-i',
      inputPath,
      '-crf',
      '${crfValue.toInt()}',
      '-preset',
      'fast',
      '-b:v',
      '${bitrate}k',
      '-codec:a',
      'copy',
      outputPath,
    ];

    return _startJob(
      arguments,
      operation: 'Reduce video quality',
      successMessage: 'Video quality reduced successfully!',
      outputPath: outputPath,
      protectedInputPaths: [inputPath],
      totalDuration: await _tryInspectDuration(inputPath),
      deletePartialOutput: deletePartialOutput,
    );
  }

  /*
  Explanation
  -vf "fps=$fps,scale=320:-1:flags=lanczos": This sets the frame rate of the GIF and scales the video. The scale=320:-1 option resizes the video to a width of 320 pixels while maintaining the aspect ratio. You can adjust the width as needed.
  -q:v $quality: This sets the quality of the GIF. Lower values mean better quality. Adjust this value to control the quality of the output GIF.
  $outputPath: The path where the resulting GIF will be saved.
   */
  /// Creates a GIF from a video with the given FPS, quality, and scale.
  Future<({bool isSuccess, String message})> createGifFromVideo({
    required String inputPath,
    required String outputPath,
    required double fps,
    required int quality,
    int scale = 320,
  }) async {
    _validatePath(inputPath, 'inputPath');
    _validatePath(outputPath, 'outputPath');
    if (!fps.isFinite || fps <= 0) {
      throw RangeError.value(fps, 'fps', 'Must be a positive finite value.');
    }
    RangeError.checkValueInInterval(quality, 1, 31, 'quality');
    _validatePositive(scale, 'scale');

    // The quality parameter for GIFs is typically controlled by the `-q:v` option
    // Lower values mean better quality (e.g., 1 is high quality, 31 is low quality)
    final arguments = <String>[
      '-y',
      '-i',
      inputPath,
      '-vf',
      'fps=$fps,scale=$scale:-1:flags=lanczos',
      '-q:v',
      '$quality',
      outputPath,
    ];

    return _run(
      arguments,
      operation: 'Create GIF',
      successMessage: 'GIF created successfully!',
    );
  }

  /// Starts GIF creation with progress and cancellation.
  Future<FfmpegJob> startCreateGifFromVideo({
    required String inputPath,
    required String outputPath,
    required double fps,
    required int quality,
    int scale = 320,
    bool deletePartialOutput = true,
  }) async {
    _validatePath(inputPath, 'inputPath');
    _validatePath(outputPath, 'outputPath');
    if (!fps.isFinite || fps <= 0) {
      throw RangeError.value(fps, 'fps', 'Must be a positive finite value.');
    }
    RangeError.checkValueInInterval(quality, 1, 31, 'quality');
    _validatePositive(scale, 'scale');

    final arguments = <String>[
      '-y',
      '-i',
      inputPath,
      '-vf',
      'fps=$fps,scale=$scale:-1:flags=lanczos',
      '-q:v',
      '$quality',
      outputPath,
    ];

    return _startJob(
      arguments,
      operation: 'Create GIF',
      successMessage: 'GIF created successfully!',
      outputPath: outputPath,
      protectedInputPaths: [inputPath],
      totalDuration: await _tryInspectDuration(inputPath),
      deletePartialOutput: deletePartialOutput,
    );
  }

  /// Extracts one thumbnail image from [inputPath] at [position].
  Future<FfmpegResult> extractThumbnail({
    required String inputPath,
    required String outputPath,
    Duration position = Duration.zero,
    int? width,
    int? height,
  }) async {
    final arguments = _thumbnailArguments(
      inputPath: inputPath,
      outputPath: outputPath,
      position: position,
      width: width,
      height: height,
    );
    return _run(
      arguments,
      operation: 'Extract thumbnail',
      successMessage: 'Thumbnail extracted successfully!',
    );
  }

  /// Starts thumbnail extraction as a cancellable job.
  Future<FfmpegJob> startExtractThumbnail({
    required String inputPath,
    required String outputPath,
    Duration position = Duration.zero,
    int? width,
    int? height,
    bool deletePartialOutput = true,
  }) async {
    final arguments = _thumbnailArguments(
      inputPath: inputPath,
      outputPath: outputPath,
      position: position,
      width: width,
      height: height,
    );
    return _startJob(
      arguments,
      operation: 'Extract thumbnail',
      successMessage: 'Thumbnail extracted successfully!',
      outputPath: outputPath,
      protectedInputPaths: [inputPath],
      deletePartialOutput: deletePartialOutput,
    );
  }

  /// Trims a video between [start] and [end] or for [duration].
  ///
  /// Supply exactly one of [duration] and [end]. Accurate mode re-encodes for
  /// precise boundaries. Fast mode uses stream copy and can seek to a nearby
  /// keyframe.
  Future<FfmpegResult> trimVideo({
    required String inputPath,
    required String outputPath,
    required Duration start,
    Duration? duration,
    Duration? end,
    VideoTrimMode mode = VideoTrimMode.accurate,
    int quality = 23,
  }) async {
    final trim = _trimArguments(
      inputPath: inputPath,
      outputPath: outputPath,
      start: start,
      duration: duration,
      end: end,
      mode: mode,
      quality: quality,
    );
    return _run(
      trim.arguments,
      operation: 'Trim video',
      successMessage: 'Video trimmed successfully!',
    );
  }

  /// Starts a video trim with progress and cancellation.
  Future<FfmpegJob> startTrimVideo({
    required String inputPath,
    required String outputPath,
    required Duration start,
    Duration? duration,
    Duration? end,
    VideoTrimMode mode = VideoTrimMode.accurate,
    int quality = 23,
    bool deletePartialOutput = true,
  }) async {
    final trim = _trimArguments(
      inputPath: inputPath,
      outputPath: outputPath,
      start: start,
      duration: duration,
      end: end,
      mode: mode,
      quality: quality,
    );
    return _startJob(
      trim.arguments,
      operation: 'Trim video',
      successMessage: 'Video trimmed successfully!',
      outputPath: outputPath,
      protectedInputPaths: [inputPath],
      totalDuration: trim.duration,
      deletePartialOutput: deletePartialOutput,
    );
  }

  Future<FfmpegResult> _run(
    List<String> arguments, {
    required String operation,
    required String successMessage,
  }) async {
    final session = await _executor.executeWithArguments(arguments);
    return _resultFromSession(
      session,
      operation: operation,
      successMessage: successMessage,
    );
  }

  Future<FfmpegJob> _startJob(
    List<String> arguments, {
    required String operation,
    required String successMessage,
    required String outputPath,
    required List<String> protectedInputPaths,
    Duration? totalDuration,
    bool deletePartialOutput = true,
  }) async {
    final progressController = StreamController<FfmpegProgress>();
    final resultCompleter = Completer<FfmpegResult>();
    var completionStarted = false;

    Future<void> complete(FfmpegSession session) async {
      if (completionStarted) return;
      completionStarted = true;

      try {
        final result = await _resultFromSession(
          session,
          operation: operation,
          successMessage: successMessage,
        );
        if (!result.isSuccess && deletePartialOutput) {
          await _deletePartialOutput(outputPath, protectedInputPaths);
        }
        resultCompleter.complete(result);
      } catch (error, stackTrace) {
        resultCompleter.completeError(error, stackTrace);
      } finally {
        await progressController.close();
      }
    }

    try {
      late final FfmpegSession session;
      if (_executor case final AsyncFfmpegExecutor asyncExecutor) {
        session = await asyncExecutor.executeWithArgumentsAsync(
          arguments,
          onComplete: (session) => unawaited(complete(session)),
          onStatistics: (statistics) {
            if (progressController.isClosed) return;
            progressController.add(
              _progressFromStatistics(statistics, totalDuration),
            );
          },
        );
      } else {
        session = await _executor.executeWithArguments(arguments);
        unawaited(complete(session));
      }

      final CancellableFfmpegSession? cancellableSession =
          session is CancellableFfmpegSession
          ? session as CancellableFfmpegSession
          : null;

      return FfmpegJob._(
        sessionId: cancellableSession?.getSessionId(),
        progress: progressController.stream,
        result: resultCompleter.future,
        cancel: cancellableSession?.cancel ?? _unsupportedCancellation,
      );
    } catch (error) {
      await progressController.close();
      rethrow;
    }
  }

  Future<FfmpegResult> _resultFromSession(
    FfmpegSession session, {
    required String operation,
    required String successMessage,
  }) async {
    final returnCode = await session.getReturnCode();

    if (returnCode?.isValueSuccess() ?? false) {
      return (isSuccess: true, message: successMessage);
    }

    if (returnCode?.isValueCancel() ?? false) {
      return (isSuccess: false, message: '$operation cancelled!');
    }

    final output = await session.getOutput();
    final logSuffix = output == null || output.trim().isEmpty
        ? ''
        : ' | FFmpeg log: $output';
    return (
      isSuccess: false,
      message: '$operation failed with return code $returnCode$logSuffix',
    );
  }

  Future<Duration?> _tryInspectDuration(String inputPath) async {
    try {
      final session = await _probeExecutor.inspect(inputPath);
      final properties = session.getMediaProperties();
      if (properties == null) return null;
      return _parseMediaInfo(inputPath, properties).duration;
    } catch (_) {
      return null;
    }
  }
}

FfmpegProgress _progressFromStatistics(
  FfmpegStatistics statistics,
  Duration? totalDuration,
) {
  final milliseconds = statistics.timeInMilliseconds < 0
      ? 0
      : statistics.timeInMilliseconds;
  final processed = Duration(milliseconds: milliseconds);
  double? fraction;
  if (totalDuration != null && totalDuration.inMilliseconds > 0) {
    fraction = processed.inMilliseconds / totalDuration.inMilliseconds;
    fraction = fraction.clamp(0.0, 1.0).toDouble();
  }

  return FfmpegProgress(
    sessionId: statistics.sessionId,
    processedDuration: processed,
    totalDuration: totalDuration,
    fraction: fraction,
    videoFrameNumber: statistics.videoFrameNumber,
    videoFps: statistics.videoFps,
    sizeBytes: statistics.sizeBytes,
    bitrate: statistics.bitrate,
    speed: statistics.speed,
  );
}

Future<void> _deletePartialOutput(
  String outputPath,
  List<String> protectedInputPaths,
) async {
  if (protectedInputPaths.contains(outputPath)) return;
  try {
    final output = File(outputPath);
    if (await output.exists()) await output.delete();
  } on FileSystemException {
    // Cleanup must not hide the FFmpeg result from the caller.
  }
}

List<String> _thumbnailArguments({
  required String inputPath,
  required String outputPath,
  required Duration position,
  required int? width,
  required int? height,
}) {
  _validatePath(inputPath, 'inputPath');
  _validatePath(outputPath, 'outputPath');
  _validateDistinctOutput(inputPath, outputPath);
  if (position.isNegative) {
    throw ArgumentError.value(position, 'position', 'Must not be negative.');
  }
  if (width != null) _validatePositive(width, 'width');
  if (height != null) _validatePositive(height, 'height');

  String? scaleFilter;
  if (width != null && height != null) {
    scaleFilter = 'scale=$width:$height:force_original_aspect_ratio=decrease';
  } else if (width != null) {
    scaleFilter = 'scale=$width:-1';
  } else if (height != null) {
    scaleFilter = 'scale=-1:$height';
  }

  return <String>[
    '-y',
    '-i',
    inputPath,
    '-ss',
    _formatDuration(position),
    '-frames:v',
    '1',
    '-an',
    if (scaleFilter != null) ...['-vf', scaleFilter],
    outputPath,
  ];
}

({List<String> arguments, Duration duration}) _trimArguments({
  required String inputPath,
  required String outputPath,
  required Duration start,
  required Duration? duration,
  required Duration? end,
  required VideoTrimMode mode,
  required int quality,
}) {
  _validatePath(inputPath, 'inputPath');
  _validatePath(outputPath, 'outputPath');
  _validateDistinctOutput(inputPath, outputPath);
  if (start.isNegative) {
    throw ArgumentError.value(start, 'start', 'Must not be negative.');
  }
  if ((duration == null) == (end == null)) {
    throw ArgumentError('Provide exactly one of duration and end.');
  }
  RangeError.checkValueInInterval(quality, 1, 51, 'quality');

  final effectiveDuration = duration ?? end! - start;
  if (effectiveDuration <= Duration.zero) {
    throw ArgumentError.value(
      effectiveDuration,
      duration != null ? 'duration' : 'end',
      'The selected range must be greater than zero.',
    );
  }

  final timeArguments = <String>['-t', _formatDuration(effectiveDuration)];
  final arguments = switch (mode) {
    VideoTrimMode.fast => <String>[
      '-y',
      '-ss',
      _formatDuration(start),
      '-i',
      inputPath,
      ...timeArguments,
      '-map',
      '0:v:0',
      '-map',
      '0:a?',
      '-c',
      'copy',
      '-avoid_negative_ts',
      'make_zero',
      outputPath,
    ],
    VideoTrimMode.accurate => <String>[
      '-y',
      '-i',
      inputPath,
      '-ss',
      _formatDuration(start),
      ...timeArguments,
      '-map',
      '0:v:0',
      '-map',
      '0:a?',
      '-c:v',
      'libx264',
      '-preset',
      'medium',
      '-crf',
      '$quality',
      '-c:a',
      'aac',
      '-movflags',
      '+faststart',
      outputPath,
    ],
  };

  return (arguments: arguments, duration: effectiveDuration);
}

Future<Duration?> _imageSequenceDuration(
  String imagesPath,
  int framerate,
) async {
  var imageCount = 0;
  try {
    await for (final entity in Directory(imagesPath).list(followLinks: false)) {
      if (entity is File &&
          RegExp(
            r'(^|[/\\])\d+\.png$',
            caseSensitive: false,
          ).hasMatch(entity.path)) {
        imageCount++;
      }
    }
  } on FileSystemException {
    return null;
  }
  if (imageCount == 0) return null;
  return Duration(
    microseconds: imageCount * Duration.microsecondsPerSecond ~/ framerate,
  );
}

String _formatDuration(Duration duration) {
  var value = (duration.inMicroseconds / Duration.microsecondsPerSecond)
      .toStringAsFixed(6);
  value = value.replaceFirst(RegExp(r'0+$'), '');
  value = value.replaceFirst(RegExp(r'\.$'), '');
  return value.isEmpty ? '0' : value;
}

void _validateDistinctOutput(String inputPath, String outputPath) {
  if (inputPath == outputPath) {
    throw ArgumentError.value(
      outputPath,
      'outputPath',
      'Must be different from the input path.',
    );
  }
}

Future<void> _unsupportedCancellation() {
  return Future<void>.error(
    UnsupportedError('This custom FFmpeg executor does not support cancel().'),
  );
}

void _validatePath(String path, String name) {
  if (path.trim().isEmpty) {
    throw ArgumentError.value(path, name, 'Must not be empty.');
  }
}

void _validatePositive(int value, String name) {
  if (value <= 0) {
    throw RangeError.value(value, name, 'Must be greater than zero.');
  }
}

String _withoutTrailingSeparator(String path) {
  return path.endsWith('/') || path.endsWith('\\')
      ? path.substring(0, path.length - 1)
      : path;
}

String _commandFromArguments(List<String> arguments) {
  return arguments.map(_quoteCommandArgument).join(' ');
}

String _quoteCommandArgument(String argument) {
  if (argument.isEmpty) return "''";
  if (!argument.contains(RegExp(r'''[\s'\"]'''))) return argument;
  if (!argument.contains("'")) return "'$argument'";
  if (!argument.contains('"')) return '"$argument"';
  throw ArgumentError.value(
    argument,
    'arguments',
    'A legacy string executor cannot encode an argument containing both quote types.',
  );
}

/// Part 2: For handle data like: '42'.parseInt()
// *set name: my + mameFunction
// Learn more: https://dart.dev/language/extension-methods

// extension FfmpegKit on String {
//
// }

// Learn more: https://dart.dev/language/extension-methods#implementing-generic-extensions
// extension FfmpegKitForT<T> on <T> {
//
// }

/// Part 3: typedef
// typedef MySeoMetaTag = MetaTag;
