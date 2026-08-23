part of '../my_maker_video.dart';

/// Result shared by synchronous helpers and [FfmpegJob.result].
typedef FfmpegResult = ({bool isSuccess, String message});

/// Selects how a video trim is performed.
enum VideoTrimMode {
  /// Re-encode the selected range for frame-accurate output.
  accurate,

  /// Copy streams without re-encoding for speed and no generation loss.
  ///
  /// The start position can move to a nearby keyframe.
  fast,
}

/// Minimal statistics interface for an FFmpeg execution.
abstract class FfmpegStatistics {
  /// FFmpeg session identifier.
  int get sessionId;

  /// Number of processed video frames.
  int get videoFrameNumber;

  /// Current processing frame rate.
  double get videoFps;

  /// Number of output bytes written so far.
  int get sizeBytes;

  /// Processed media time in milliseconds.
  int get timeInMilliseconds;

  /// Current output bitrate.
  double get bitrate;

  /// Processing speed relative to real time.
  double get speed;
}

/// Wraps an FFmpegKit statistics callback value.
class FfmpegKitStatistics implements FfmpegStatistics {
  /// Creates an adapter around native statistics.
  FfmpegKitStatistics(this._statistics);

  final dynamic _statistics;

  @override
  int get sessionId => _statistics.getSessionId();

  @override
  int get videoFrameNumber => _statistics.getVideoFrameNumber();

  @override
  double get videoFps => _statistics.getVideoFps();

  @override
  int get sizeBytes => _statistics.getSize();

  @override
  int get timeInMilliseconds => _statistics.getTime();

  @override
  double get bitrate => _statistics.getBitrate();

  @override
  double get speed => _statistics.getSpeed();
}

/// Progress emitted by a running [FfmpegJob].
@immutable
class FfmpegProgress {
  /// Creates an immutable progress value.
  const FfmpegProgress({
    required this.sessionId,
    required this.processedDuration,
    required this.totalDuration,
    required this.fraction,
    required this.videoFrameNumber,
    required this.videoFps,
    required this.sizeBytes,
    required this.bitrate,
    required this.speed,
  });

  /// FFmpeg session identifier.
  final int sessionId;

  /// Media duration processed so far.
  final Duration processedDuration;

  /// Expected media duration when known.
  final Duration? totalDuration;

  /// Progress from 0 to 1, or `null` when total duration is unknown.
  final double? fraction;

  /// Progress from 0 to 100, or `null` when total duration is unknown.
  double? get percentage => fraction == null ? null : fraction! * 100;

  /// Number of processed video frames.
  final int videoFrameNumber;

  /// Current processing frame rate.
  final double videoFps;

  /// Number of output bytes written so far.
  final int sizeBytes;

  /// Current output bitrate.
  final double bitrate;

  /// Processing speed relative to real time.
  final double speed;
}

/// Handle for one independently cancellable FFmpeg execution.
class FfmpegJob {
  FfmpegJob._({
    required this.sessionId,
    required this.progress,
    required this.result,
    required this._cancel,
  });

  /// Native FFmpeg session identifier, if provided by the executor.
  final int? sessionId;

  /// Single-subscription progress stream for this session.
  final Stream<FfmpegProgress> progress;

  /// Completes when FFmpeg succeeds, is cancelled, or fails.
  final Future<FfmpegResult> result;

  final Future<void> Function() _cancel;

  /// Requests cancellation of this job only.
  Future<void> cancel() => _cancel();
}
