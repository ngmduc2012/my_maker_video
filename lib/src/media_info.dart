part of '../my_maker_video.dart';

/// Type of a stream reported by FFprobe.
enum MediaStreamType { video, audio, subtitle, data, attachment, unknown }

/// Information about one audio, video, subtitle, or data stream.
@immutable
class MediaStreamInfo {
  /// Creates immutable stream information.
  const MediaStreamInfo({
    required this.index,
    required this.type,
    required this.codec,
    required this.codecDescription,
    required this.width,
    required this.height,
    required this.bitrate,
    required this.sampleRate,
    required this.channelLayout,
    required this.averageFrameRate,
    required this.rotationDegrees,
    required this.tags,
  });

  /// Zero-based stream index inside the media container.
  final int? index;

  /// Kind of media stored in this stream.
  final MediaStreamType type;

  /// Short codec name, for example `h264` or `aac`.
  final String? codec;

  /// Human-readable codec description.
  final String? codecDescription;

  /// Video width in pixels.
  final int? width;

  /// Video height in pixels.
  final int? height;

  /// Stream bitrate in bits per second.
  final int? bitrate;

  /// Audio sample rate in hertz.
  final int? sampleRate;

  /// Audio channel layout, for example `stereo`.
  final String? channelLayout;

  /// Average video frame rate.
  final double? averageFrameRate;

  /// Display rotation in degrees when present in metadata.
  final int? rotationDegrees;

  /// Stream metadata tags converted to strings.
  final Map<String, String> tags;
}

/// Typed information about a media file.
@immutable
class MediaInfo {
  /// Creates immutable media information.
  const MediaInfo({
    required this.path,
    required this.format,
    required this.formatDescription,
    required this.duration,
    required this.sizeBytes,
    required this.bitrate,
    required this.tags,
    required this.streams,
  });

  /// Path reported by FFprobe, or the requested path as a fallback.
  final String path;

  /// Short container format name.
  final String? format;

  /// Human-readable container format description.
  final String? formatDescription;

  /// Media duration when it can be determined.
  final Duration? duration;

  /// Container size in bytes.
  final int? sizeBytes;

  /// Overall bitrate in bits per second.
  final int? bitrate;

  /// Container metadata tags converted to strings.
  final Map<String, String> tags;

  /// All streams reported by FFprobe.
  final List<MediaStreamInfo> streams;

  /// First video stream, if present.
  MediaStreamInfo? get videoStream => _firstStream(MediaStreamType.video);

  /// First audio stream, if present.
  MediaStreamInfo? get audioStream => _firstStream(MediaStreamType.audio);

  /// Whether the media contains at least one video stream.
  bool get hasVideo => videoStream != null;

  /// Whether the media contains at least one audio stream.
  bool get hasAudio => audioStream != null;

  MediaStreamInfo? _firstStream(MediaStreamType type) {
    for (final stream in streams) {
      if (stream.type == type) return stream;
    }
    return null;
  }
}

/// Result returned by [\$FfmpegKit.inspectMedia].
@immutable
class MediaInfoResult {
  /// Creates a media inspection result.
  const MediaInfoResult({
    required this.isSuccess,
    required this.message,
    this.mediaInfo,
  });

  /// Whether FFprobe returned usable media information.
  final bool isSuccess;

  /// Human-readable success or failure message.
  final String message;

  /// Parsed media information on success.
  final MediaInfo? mediaInfo;
}

/// Minimal FFprobe session interface used by MyMakerVideo.
abstract class FfmpegProbeSession {
  /// Returns the FFprobe return code.
  Future<dynamic> getReturnCode();

  /// Returns FFprobe output, if any.
  Future<String?> getOutput();

  /// Returns all parsed FFprobe properties.
  Map<dynamic, dynamic>? getMediaProperties();
}

/// Executes an FFprobe media inspection.
abstract class FfmpegProbeExecutor {
  /// Default probe executor constructor.
  const FfmpegProbeExecutor();

  /// Inspects [path] and returns a probe session.
  Future<FfmpegProbeSession> inspect(String path);
}

/// Wraps an FFprobeKit media information session.
class FfmpegKitProbeSession implements FfmpegProbeSession {
  /// Creates an adapter around the native session.
  FfmpegKitProbeSession(this._session);

  final dynamic _session;

  @override
  Future<dynamic> getReturnCode() => _session.getReturnCode();

  @override
  Future<String?> getOutput() => _session.getOutput();

  @override
  Map<dynamic, dynamic>? getMediaProperties() {
    return _session.getMediaInformation()?.getAllProperties();
  }
}

/// Default FFprobe executor backed by FFprobeKit.
class FfmpegKitProbeExecutor implements FfmpegProbeExecutor {
  /// Creates the default probe executor.
  const FfmpegKitProbeExecutor();

  /// Overridable FFprobe entrypoint for tests.
  @visibleForTesting
  static Future<dynamic> Function(String path) inspectImpl =
      FFprobeKit.getMediaInformation;

  @override
  Future<FfmpegProbeSession> inspect(String path) async {
    final session = await inspectImpl(path);
    return FfmpegKitProbeSession(session);
  }
}

MediaInfo _parseMediaInfo(String requestedPath, Map<dynamic, dynamic> values) {
  final format = _asDynamicMap(values['format']);
  final streamValues = values['streams'];
  final streams = <MediaStreamInfo>[];

  if (streamValues is Iterable) {
    for (final value in streamValues) {
      final stream = _asDynamicMap(value);
      if (stream != null) streams.add(_parseMediaStream(stream));
    }
  }

  return MediaInfo(
    path: _asString(format?['filename']) ?? requestedPath,
    format: _asString(format?['format_name']),
    formatDescription: _asString(format?['format_long_name']),
    duration: _durationFromSeconds(format?['duration']),
    sizeBytes: _asInt(format?['size']),
    bitrate: _asInt(format?['bit_rate']),
    tags: Map<String, String>.unmodifiable(_stringMap(format?['tags'])),
    streams: List<MediaStreamInfo>.unmodifiable(streams),
  );
}

MediaStreamInfo _parseMediaStream(Map<dynamic, dynamic> values) {
  return MediaStreamInfo(
    index: _asInt(values['index']),
    type: _streamType(_asString(values['codec_type'])),
    codec: _asString(values['codec_name']),
    codecDescription: _asString(values['codec_long_name']),
    width: _asInt(values['width']),
    height: _asInt(values['height']),
    bitrate: _asInt(values['bit_rate']),
    sampleRate: _asInt(values['sample_rate']),
    channelLayout: _asString(values['channel_layout']),
    averageFrameRate: _parseFrameRate(values['avg_frame_rate']),
    rotationDegrees: _parseRotation(values),
    tags: Map<String, String>.unmodifiable(_stringMap(values['tags'])),
  );
}

MediaStreamType _streamType(String? value) {
  return switch (value) {
    'video' => MediaStreamType.video,
    'audio' => MediaStreamType.audio,
    'subtitle' => MediaStreamType.subtitle,
    'data' => MediaStreamType.data,
    'attachment' => MediaStreamType.attachment,
    _ => MediaStreamType.unknown,
  };
}

int? _parseRotation(Map<dynamic, dynamic> values) {
  final tags = _asDynamicMap(values['tags']);
  final tagRotation = _asInt(tags?['rotate']);
  if (tagRotation != null) return tagRotation;

  final sideData = values['side_data_list'];
  if (sideData is Iterable) {
    for (final item in sideData) {
      final rotation = _asInt(_asDynamicMap(item)?['rotation']);
      if (rotation != null) return rotation;
    }
  }
  return null;
}

double? _parseFrameRate(dynamic value) {
  final text = _asString(value);
  if (text == null || text.isEmpty) return null;
  final parts = text.split('/');
  if (parts.length == 2) {
    final numerator = double.tryParse(parts[0]);
    final denominator = double.tryParse(parts[1]);
    if (numerator == null || denominator == null || denominator == 0) {
      return null;
    }
    return numerator / denominator;
  }
  return double.tryParse(text);
}

Duration? _durationFromSeconds(dynamic value) {
  final seconds = value is num
      ? value.toDouble()
      : double.tryParse(value?.toString() ?? '');
  if (seconds == null || !seconds.isFinite || seconds < 0) return null;
  return Duration(
    microseconds: (seconds * Duration.microsecondsPerSecond).round(),
  );
}

Map<dynamic, dynamic>? _asDynamicMap(dynamic value) {
  return value is Map ? Map<dynamic, dynamic>.from(value) : null;
}

Map<String, String> _stringMap(dynamic value) {
  final map = _asDynamicMap(value);
  if (map == null) return const {};
  return {
    for (final entry in map.entries)
      if (entry.key != null && entry.value != null)
        entry.key.toString(): entry.value.toString(),
  };
}

String? _asString(dynamic value) => value?.toString();

int? _asInt(dynamic value) {
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '');
}
