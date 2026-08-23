part of '../my_maker_video.dart';

/// Signature for executing an FFmpeg command.
typedef FfmpegExecuteFn = Future<dynamic> Function(String command);

/// Signature for executing an FFmpeg argument list without reparsing paths.
typedef FfmpegExecuteArgumentsFn = Future<dynamic> Function(
  List<String> arguments,
);

/// Minimal session interface for FFmpeg results.
abstract class FfmpegSession {
  /// Returns the underlying FFmpeg return code.
  Future<dynamic> getReturnCode();

  /// Returns the FFmpeg command output, if any.
  Future<String?> getOutput();
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

/// Wraps the native FFmpegKit session.
class FfmpegKitSession implements FfmpegSession {
  /// Creates an adapter around the native session.
  FfmpegKitSession(this._session);

  final dynamic _session;

  @override
  Future<dynamic> getReturnCode() => _session.getReturnCode();

  @override
  Future<String?> getOutput() => _session.getOutput();
}

/// Default executor that delegates to FFmpegKit.
class FfmpegKitExecutor implements FfmpegExecutor {
  /// Creates a default FFmpegKit executor.
  const FfmpegKitExecutor();

  /// Overridable entrypoint for tests.
  @visibleForTesting
  static FfmpegExecuteFn executeImpl = FFmpegKit.execute;

  /// Overridable argument-list entrypoint for tests.
  @visibleForTesting
  static FfmpegExecuteArgumentsFn executeWithArgumentsImpl =
      FFmpegKit.executeWithArguments;

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
}

/// High-level helpers built on top of FFmpegKit.
class $FfmpegKit {
  /// Creates a helper with an optional custom executor (for tests).
  const $FfmpegKit({FfmpegExecutor executor = const FfmpegKitExecutor()})
    : this._(executor);

  const $FfmpegKit._(this._executor);

  final FfmpegExecutor _executor;
  /*
   Learn more: https://pub.dev/packages/ffmpeg_kit_flutter_new

   The maintained package bundles the Full-GPL build because these helpers use
   libx264. Applications using this package must comply with the GPL terms.

   Thay thế cho thư viện gify https://pub.dev/packages/gify, gify sử dụng các tương tự nhưng khá chậm
*/

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

  Future<({bool isSuccess, String message})> _run(
    List<String> arguments, {
    required String operation,
    required String successMessage,
  }) async {
    final session = await _executor.executeWithArguments(arguments);
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
