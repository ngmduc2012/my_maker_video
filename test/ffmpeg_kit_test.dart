import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:my_maker_video/my_maker_video.dart';

class FakeReturnCode {
  const FakeReturnCode({this.success = false, this.cancel = false});

  final bool success;
  final bool cancel;

  bool isValueSuccess() => success;
  bool isValueCancel() => cancel;

  @override
  String toString() => 'FakeReturnCode(success: $success, cancel: $cancel)';
}

class FakeSession implements FfmpegSession {
  const FakeSession({required this.returnCode, this.output});

  final FakeReturnCode returnCode;
  final String? output;

  @override
  Future<dynamic> getReturnCode() async => returnCode;

  @override
  Future<String?> getOutput() async => output;
}

class CapturingExecutor implements FfmpegExecutor {
  CapturingExecutor(this._session);

  final FfmpegSession _session;
  String? lastCommand;
  List<String>? lastArguments;

  @override
  Future<FfmpegSession> execute(String command) async {
    lastCommand = command;
    return _session;
  }

  @override
  Future<FfmpegSession> executeWithArguments(List<String> arguments) async {
    lastArguments = List<String>.unmodifiable(arguments);
    lastCommand = arguments.join(' ');
    return _session;
  }
}

class DummyExecutor extends FfmpegExecutor {
  const DummyExecutor();

  @override
  Future<FfmpegSession> execute(String command) async {
    return const FakeSession(returnCode: FakeReturnCode(success: true));
  }
}

class FakeNativeSession {
  FakeNativeSession({this.sessionId = 73});

  final int sessionId;
  bool cancelled = false;

  Future<dynamic> getReturnCode() async => const FakeReturnCode(success: true);
  Future<String?> getOutput() async => 'native output';
  int? getSessionId() => sessionId;
  Future<void> cancel() async => cancelled = true;
}

class CancellableFakeSession
    implements FfmpegSession, CancellableFfmpegSession {
  CancellableFakeSession({
    required this.returnCode,
    this.output,
    this.sessionId = 42,
  });

  final FakeReturnCode returnCode;
  final String? output;
  final int sessionId;
  bool cancelled = false;

  @override
  Future<dynamic> getReturnCode() async => returnCode;

  @override
  Future<String?> getOutput() async => output;

  @override
  int? getSessionId() => sessionId;

  @override
  Future<void> cancel() async => cancelled = true;
}

class FakeStatistics implements FfmpegStatistics {
  const FakeStatistics({
    this.sessionId = 42,
    this.videoFrameNumber = 30,
    this.videoFps = 30,
    this.sizeBytes = 1024,
    this.timeInMilliseconds = 1000,
    this.bitrate = 800,
    this.speed = 1.5,
  });

  @override
  final int sessionId;

  @override
  final int videoFrameNumber;

  @override
  final double videoFps;

  @override
  final int sizeBytes;

  @override
  final int timeInMilliseconds;

  @override
  final double bitrate;

  @override
  final double speed;
}

class FakeNativeStatistics {
  int getSessionId() => 73;
  int getVideoFrameNumber() => 30;
  double getVideoFps() => 30;
  int getSize() => 2048;
  int getTime() => 500;
  double getBitrate() => 900;
  double getSpeed() => 2;
}

class AsyncCapturingExecutor implements FfmpegExecutor, AsyncFfmpegExecutor {
  AsyncCapturingExecutor(this.session);

  final CancellableFakeSession session;
  List<String>? lastArguments;
  void Function(FfmpegSession session)? _onComplete;
  void Function(FfmpegStatistics statistics)? _onStatistics;

  @override
  Future<FfmpegSession> execute(String command) async => session;

  @override
  Future<FfmpegSession> executeWithArguments(List<String> arguments) async {
    lastArguments = List<String>.unmodifiable(arguments);
    return session;
  }

  @override
  Future<FfmpegSession> executeWithArgumentsAsync(
    List<String> arguments, {
    void Function(FfmpegSession session)? onComplete,
    void Function(FfmpegStatistics statistics)? onStatistics,
  }) async {
    lastArguments = List<String>.unmodifiable(arguments);
    _onComplete = onComplete;
    _onStatistics = onStatistics;
    return session;
  }

  void emit(FfmpegStatistics statistics) => _onStatistics?.call(statistics);

  void complete() => _onComplete?.call(session);
}

class FakeProbeSession implements FfmpegProbeSession {
  const FakeProbeSession({
    this.properties,
    this.returnCode = const FakeReturnCode(success: true),
    this.output,
  });

  final Map<dynamic, dynamic>? properties;
  final FakeReturnCode returnCode;
  final String? output;

  @override
  Future<dynamic> getReturnCode() async => returnCode;

  @override
  Future<String?> getOutput() async => output;

  @override
  Map<dynamic, dynamic>? getMediaProperties() => properties;
}

class FakeProbeExecutor implements FfmpegProbeExecutor {
  const FakeProbeExecutor(this.session);

  final FfmpegProbeSession session;

  @override
  Future<FfmpegProbeSession> inspect(String path) async => session;
}

void main() {
  test('MyMakerVideo exposes ffmpeg kit helper', () {
    expect(MyMakerVideo.ffmpegKit, isA<$FfmpegKit>());
  });

  test('FfmpegExecutor base constructor can be invoked', () async {
    const executor = DummyExecutor();
    final session = await executor.execute('cmd');

    expect(await session.getReturnCode(), isA<FakeReturnCode>());
  });

  test('FfmpegKitExecutor wraps native session', () async {
    final previous = FfmpegKitExecutor.executeImpl;
    try {
      FfmpegKitExecutor.executeImpl = (command) async => FakeNativeSession();

      const executor = FfmpegKitExecutor();
      final session = await executor.execute('cmd');

      expect(await session.getReturnCode(), isA<FakeReturnCode>());
      expect(await session.getOutput(), 'native output');
    } finally {
      FfmpegKitExecutor.executeImpl = previous;
    }
  });

  test(
    'FfmpegKitExecutor sends argument lists directly to FFmpegKit',
    () async {
      final previous = FfmpegKitExecutor.executeWithArgumentsImpl;
      List<String>? capturedArguments;
      try {
        FfmpegKitExecutor.executeWithArgumentsImpl = (arguments) async {
          capturedArguments = arguments;
          return FakeNativeSession();
        };

        const executor = FfmpegKitExecutor();
        final session = await executor.executeWithArguments(const [
          '-i',
          'folder with spaces/input.mp4',
        ]);

        expect(capturedArguments, ['-i', 'folder with spaces/input.mp4']);
        expect(await session.getOutput(), 'native output');
      } finally {
        FfmpegKitExecutor.executeWithArgumentsImpl = previous;
      }
    },
  );

  test('FfmpegKitExecutor adapts async sessions and statistics', () async {
    final previous = FfmpegKitExecutor.executeWithArgumentsAsyncImpl;
    final nativeSession = FakeNativeSession();
    FfmpegSession? completedSession;
    FfmpegStatistics? receivedStatistics;
    try {
      FfmpegKitExecutor.executeWithArgumentsAsyncImpl =
          (arguments, completeCallback, statisticsCallback) async {
            statisticsCallback?.call(FakeNativeStatistics());
            completeCallback?.call(nativeSession);
            return nativeSession;
          };

      const executor = FfmpegKitExecutor();
      final session = await executor.executeWithArgumentsAsync(
        const ['-i', 'input.mp4'],
        onComplete: (value) => completedSession = value,
        onStatistics: (value) => receivedStatistics = value,
      );

      expect(session, isA<CancellableFfmpegSession>());
      expect(completedSession, isA<FfmpegKitSession>());
      expect(receivedStatistics?.sessionId, 73);
      expect(receivedStatistics?.timeInMilliseconds, 500);
      await (session as CancellableFfmpegSession).cancel();
      expect(nativeSession.cancelled, isTrue);
    } finally {
      FfmpegKitExecutor.executeWithArgumentsAsyncImpl = previous;
    }
  });

  group('inspectMedia', () {
    test('parses container, video, audio, frame rate, and rotation', () async {
      const probe = FakeProbeSession(
        properties: {
          'format': {
            'filename': '/media/input.mp4',
            'format_name': 'mov,mp4',
            'format_long_name': 'QuickTime / MOV',
            'duration': '2.500000',
            'size': '4096',
            'bit_rate': '1200000',
            'tags': {'title': 'Demo'},
          },
          'streams': [
            {
              'index': 0,
              'codec_type': 'video',
              'codec_name': 'h264',
              'codec_long_name': 'H.264',
              'width': 1920,
              'height': 1080,
              'avg_frame_rate': '30000/1001',
              'side_data_list': [
                {'rotation': -90},
              ],
            },
            {
              'index': 1,
              'codec_type': 'audio',
              'codec_name': 'aac',
              'sample_rate': '44100',
              'channel_layout': 'stereo',
            },
          ],
        },
      );
      final kit = $FfmpegKit(probeExecutor: FakeProbeExecutor(probe));

      final result = await kit.inspectMedia(inputPath: 'input.mp4');

      expect(result.isSuccess, isTrue);
      expect(result.mediaInfo?.path, '/media/input.mp4');
      expect(result.mediaInfo?.duration, const Duration(milliseconds: 2500));
      expect(result.mediaInfo?.sizeBytes, 4096);
      expect(result.mediaInfo?.bitrate, 1200000);
      expect(result.mediaInfo?.tags, {'title': 'Demo'});
      expect(result.mediaInfo?.hasVideo, isTrue);
      expect(result.mediaInfo?.hasAudio, isTrue);
      expect(result.mediaInfo?.videoStream?.codec, 'h264');
      expect(result.mediaInfo?.videoStream?.width, 1920);
      expect(
        result.mediaInfo?.videoStream?.averageFrameRate,
        closeTo(29.970, 0.001),
      );
      expect(result.mediaInfo?.videoStream?.rotationDegrees, -90);
      expect(result.mediaInfo?.audioStream?.sampleRate, 44100);
    });

    test('returns FFprobe output when inspection fails', () async {
      const probe = FakeProbeSession(
        properties: null,
        returnCode: FakeReturnCode(),
        output: 'invalid media',
      );
      final kit = $FfmpegKit(probeExecutor: FakeProbeExecutor(probe));

      final result = await kit.inspectMedia(inputPath: 'broken.mp4');

      expect(result.isSuccess, isFalse);
      expect(result.mediaInfo, isNull);
      expect(result.message, contains('invalid media'));
    });
  });

  group('convertImageDirectoryToVideo', () {
    test('builds command and returns success', () async {
      final executor = CapturingExecutor(
        const FakeSession(returnCode: FakeReturnCode(success: true)),
      );
      final kit = $FfmpegKit(executor: executor);

      final result = await kit.convertImageDirectoryToVideo(
        imagesPath: 'images',
        outputVideoPath: 'out.mp4',
        framerate: 12,
        fps: 30,
        quality: 23,
      );

      const expectedCommand =
          '-y -framerate 12 -i images/%d.png '
          '-r 30 '
          '-crf 23 -preset slow '
          '-vf scale=trunc(iw/2)*2:trunc(ih/2)*2 '
          '-c:v libx264 -pix_fmt yuv420p -movflags +faststart out.mp4';

      expect(executor.lastCommand, expectedCommand);
      expect(result.isSuccess, isTrue);
      expect(result.message, 'Video conversion successful!');
    });

    test('builds command without fps or quality', () async {
      final executor = CapturingExecutor(
        const FakeSession(returnCode: FakeReturnCode(success: true)),
      );
      final kit = $FfmpegKit(executor: executor);

      await kit.convertImageDirectoryToVideo(
        imagesPath: 'images',
        outputVideoPath: 'out.mp4',
      );

      final command = executor.lastCommand!;
      expect(command, contains('-framerate 24 -i images/%d.png'));
      expect(command, contains('-vf scale=trunc(iw/2)*2:trunc(ih/2)*2'));
      expect(
        command,
        contains('-c:v libx264 -pix_fmt yuv420p -movflags +faststart out.mp4'),
      );
      expect(command.contains('-r '), isFalse);
      expect(command.contains('-crf '), isFalse);
    });

    test('returns cancelled message', () async {
      final executor = CapturingExecutor(
        const FakeSession(returnCode: FakeReturnCode(cancel: true)),
      );
      final kit = $FfmpegKit(executor: executor);

      final result = await kit.convertImageDirectoryToVideo(
        imagesPath: 'images',
        outputVideoPath: 'out.mp4',
      );

      expect(result.isSuccess, isFalse);
      expect(result.message, 'Video conversion cancelled!');
    });

    test('throws range error when fps is invalid', () async {
      final executor = CapturingExecutor(
        const FakeSession(returnCode: FakeReturnCode(success: true)),
      );
      final kit = $FfmpegKit(executor: executor);

      await expectLater(
        kit.convertImageDirectoryToVideo(
          imagesPath: 'images',
          outputVideoPath: 'out.mp4',
          fps: 0,
        ),
        throwsRangeError,
      );
    });

    test('throws range error when quality is invalid', () async {
      final executor = CapturingExecutor(
        const FakeSession(returnCode: FakeReturnCode(success: true)),
      );
      final kit = $FfmpegKit(executor: executor);

      await expectLater(
        kit.convertImageDirectoryToVideo(
          imagesPath: 'images',
          outputVideoPath: 'out.mp4',
          quality: 0,
        ),
        throwsRangeError,
      );
    });

    test('includes output on failure', () async {
      final executor = CapturingExecutor(
        const FakeSession(
          returnCode: FakeReturnCode(),
          output: 'ffmpeg output',
        ),
      );
      final kit = $FfmpegKit(executor: executor);

      final result = await kit.convertImageDirectoryToVideo(
        imagesPath: 'images',
        outputVideoPath: 'out.mp4',
      );

      expect(result.isSuccess, isFalse);
      expect(result.message, contains('ffmpeg output'));
    });

    test('keeps paths with spaces as single FFmpeg arguments', () async {
      final executor = CapturingExecutor(
        const FakeSession(returnCode: FakeReturnCode(success: true)),
      );
      final kit = $FfmpegKit(executor: executor);

      await kit.convertImageDirectoryToVideo(
        imagesPath: 'input images',
        outputVideoPath: 'output videos/out.mp4',
      );

      expect(executor.lastArguments, contains('input images/%d.png'));
      expect(executor.lastArguments, contains('output videos/out.mp4'));
    });
  });

  group('addWatermarkToVideo', () {
    test('uses scaled watermark filter when size provided', () async {
      final executor = CapturingExecutor(
        const FakeSession(returnCode: FakeReturnCode(success: true)),
      );
      final kit = $FfmpegKit(executor: executor);

      await kit.addWatermarkToVideo(
        videoPath: 'input.mp4',
        watermarkPath: 'mark.png',
        outputPath: 'out.mp4',
        x: 10,
        y: 20,
        width: 100,
        height: 200,
      );

      const expectedCommand =
          '-y -i input.mp4 -i mark.png -filter_complex '
          '[1:v]scale=100:200[wm];[0:v][wm]overlay=10:20 '
          '-codec:a copy out.mp4';

      expect(executor.lastCommand, expectedCommand);
    });

    test('requires watermark width and height together', () async {
      final executor = CapturingExecutor(
        const FakeSession(returnCode: FakeReturnCode(success: true)),
      );
      final kit = $FfmpegKit(executor: executor);

      await expectLater(
        kit.addWatermarkToVideo(
          videoPath: 'input.mp4',
          watermarkPath: 'mark.png',
          outputPath: 'out.mp4',
          x: 10,
          y: 20,
          width: 100,
        ),
        throwsArgumentError,
      );
    });

    test('uses overlay filter when size omitted', () async {
      final executor = CapturingExecutor(
        const FakeSession(returnCode: FakeReturnCode(success: true)),
      );
      final kit = $FfmpegKit(executor: executor);

      await kit.addWatermarkToVideo(
        videoPath: 'input.mp4',
        watermarkPath: 'mark.png',
        outputPath: 'out.mp4',
        x: 10,
        y: 20,
      );

      const expectedCommand =
          '-y -i input.mp4 -i mark.png -filter_complex overlay=10:20 '
          '-codec:a copy out.mp4';

      expect(executor.lastCommand, expectedCommand);
    });

    test('returns failure message when return code is not success', () async {
      final executor = CapturingExecutor(
        const FakeSession(returnCode: FakeReturnCode()),
      );
      final kit = $FfmpegKit(executor: executor);

      final result = await kit.addWatermarkToVideo(
        videoPath: 'input.mp4',
        watermarkPath: 'mark.png',
        outputPath: 'out.mp4',
        x: 10,
        y: 20,
      );

      expect(result.isSuccess, isFalse);
      expect(result.message, contains('Add watermark failed'));
    });
  });

  group('reduceVideoQualityByPercentage', () {
    test('builds command from quality percentage', () async {
      final executor = CapturingExecutor(
        const FakeSession(returnCode: FakeReturnCode(success: true)),
      );
      final kit = $FfmpegKit(executor: executor);

      final result = await kit.reduceVideoQualityByPercentage(
        inputPath: 'input.mp4',
        outputPath: 'out.mp4',
        qualityPercentage: 30,
      );

      const expectedCommand =
          '-y -i input.mp4 -crf 41 -preset fast -b:v 1850k -codec:a copy out.mp4';

      expect(executor.lastCommand, expectedCommand);
      expect(result.isSuccess, isTrue);
      expect(result.message, 'Video quality reduced successfully!');
    });

    test('returns failure when return code is not success', () async {
      final executor = CapturingExecutor(
        const FakeSession(returnCode: FakeReturnCode()),
      );
      final kit = $FfmpegKit(executor: executor);

      final result = await kit.reduceVideoQualityByPercentage(
        inputPath: 'input.mp4',
        outputPath: 'out.mp4',
        qualityPercentage: 30,
      );

      expect(result.isSuccess, isFalse);
      expect(result.message, contains('Reduce video quality failed'));
    });

    test('rejects a quality percentage outside 0 to 100', () async {
      final kit = $FfmpegKit(
        executor: CapturingExecutor(
          const FakeSession(returnCode: FakeReturnCode(success: true)),
        ),
      );

      await expectLater(
        kit.reduceVideoQualityByPercentage(
          inputPath: 'input.mp4',
          outputPath: 'out.mp4',
          qualityPercentage: 101,
        ),
        throwsRangeError,
      );
    });
  });

  group('createGifFromVideo', () {
    test('builds command with default scale and returns success', () async {
      final executor = CapturingExecutor(
        const FakeSession(returnCode: FakeReturnCode(success: true)),
      );
      final kit = $FfmpegKit(executor: executor);

      final result = await kit.createGifFromVideo(
        inputPath: 'input.mp4',
        outputPath: 'out.gif',
        fps: 1.5,
        quality: 10,
      );

      const expectedCommand =
          '-y -i input.mp4 -vf fps=1.5,scale=320:-1:flags=lanczos -q:v 10 out.gif';

      expect(executor.lastCommand, expectedCommand);
      expect(result.isSuccess, isTrue);
      expect(result.message, 'GIF created successfully!');
    });

    test('returns failure when return code is not success', () async {
      final executor = CapturingExecutor(
        const FakeSession(returnCode: FakeReturnCode()),
      );
      final kit = $FfmpegKit(executor: executor);

      final result = await kit.createGifFromVideo(
        inputPath: 'input.mp4',
        outputPath: 'out.gif',
        fps: 2.0,
        quality: 5,
        scale: 200,
      );

      const expectedCommand =
          '-y -i input.mp4 -vf fps=2.0,scale=200:-1:flags=lanczos -q:v 5 out.gif';

      expect(executor.lastCommand, expectedCommand);
      expect(result.isSuccess, isFalse);
      expect(result.message, contains('Create GIF failed'));
    });

    test('rejects invalid GIF settings', () async {
      final kit = $FfmpegKit(
        executor: CapturingExecutor(
          const FakeSession(returnCode: FakeReturnCode(success: true)),
        ),
      );

      await expectLater(
        kit.createGifFromVideo(
          inputPath: 'input.mp4',
          outputPath: 'out.gif',
          fps: 0,
          quality: 10,
        ),
        throwsRangeError,
      );
      await expectLater(
        kit.createGifFromVideo(
          inputPath: 'input.mp4',
          outputPath: 'out.gif',
          fps: 2,
          quality: 32,
        ),
        throwsRangeError,
      );
    });
  });

  group('FfmpegJob', () {
    test(
      'emits per-session progress, completes, and supports cancel',
      () async {
        final session = CancellableFakeSession(
          returnCode: const FakeReturnCode(success: true),
        );
        final executor = AsyncCapturingExecutor(session);
        const probe = FakeProbeSession(
          properties: {
            'format': {'duration': '2.0'},
            'streams': <dynamic>[],
          },
        );
        final kit = $FfmpegKit(
          executor: executor,
          probeExecutor: const FakeProbeExecutor(probe),
        );

        final job = await kit.startReduceVideoQualityByPercentage(
          inputPath: 'input.mp4',
          outputPath: 'out.mp4',
          qualityPercentage: 50,
        );
        final progressFuture = job.progress.toList();

        executor.emit(const FakeStatistics(timeInMilliseconds: 1000));
        await job.cancel();
        executor.complete();

        final progress = await progressFuture;
        final result = await job.result;
        expect(job.sessionId, 42);
        expect(session.cancelled, isTrue);
        expect(progress, hasLength(1));
        expect(progress.single.processedDuration, const Duration(seconds: 1));
        expect(progress.single.percentage, 50);
        expect(result.isSuccess, isTrue);
      },
    );

    test('deletes a partial output after FFmpeg failure', () async {
      final temporaryDirectory = await Directory.systemTemp.createTemp(
        'my_maker_video_test_',
      );
      addTearDown(() => temporaryDirectory.delete(recursive: true));
      final output = File('${temporaryDirectory.path}/thumbnail.jpg');
      await output.writeAsString('partial');
      final session = CancellableFakeSession(
        returnCode: const FakeReturnCode(),
        output: 'failed',
      );
      final executor = AsyncCapturingExecutor(session);
      final kit = $FfmpegKit(executor: executor);

      final job = await kit.startExtractThumbnail(
        inputPath: 'input.mp4',
        outputPath: output.path,
      );
      executor.complete();

      final result = await job.result;
      expect(result.isSuccess, isFalse);
      expect(await output.exists(), isFalse);
    });

    test('reports cancellation unsupported for a legacy executor', () async {
      final kit = $FfmpegKit(
        executor: CapturingExecutor(
          const FakeSession(returnCode: FakeReturnCode(success: true)),
        ),
      );

      final job = await kit.startExtractThumbnail(
        inputPath: 'input.mp4',
        outputPath: 'output.jpg',
      );

      await expectLater(job.cancel(), throwsUnsupportedError);
      expect((await job.result).isSuccess, isTrue);
    });
  });

  group('extractThumbnail', () {
    test(
      'builds an accurate thumbnail command with optional scaling',
      () async {
        final executor = CapturingExecutor(
          const FakeSession(returnCode: FakeReturnCode(success: true)),
        );
        final kit = $FfmpegKit(executor: executor);

        final result = await kit.extractThumbnail(
          inputPath: 'input video.mp4',
          outputPath: 'thumbnail image.jpg',
          position: const Duration(milliseconds: 1500),
          width: 320,
        );

        expect(executor.lastArguments, [
          '-y',
          '-i',
          'input video.mp4',
          '-ss',
          '1.5',
          '-frames:v',
          '1',
          '-an',
          '-vf',
          'scale=320:-1',
          'thumbnail image.jpg',
        ]);
        expect(result.isSuccess, isTrue);
      },
    );

    test('rejects a negative position and matching output path', () async {
      final kit = $FfmpegKit(
        executor: CapturingExecutor(
          const FakeSession(returnCode: FakeReturnCode(success: true)),
        ),
      );

      await expectLater(
        kit.extractThumbnail(
          inputPath: 'input.mp4',
          outputPath: 'output.jpg',
          position: const Duration(milliseconds: -1),
        ),
        throwsArgumentError,
      );
      await expectLater(
        kit.extractThumbnail(inputPath: 'input.mp4', outputPath: 'input.mp4'),
        throwsArgumentError,
      );
    });
  });

  group('trimVideo', () {
    test('builds an accurate re-encode command', () async {
      final executor = CapturingExecutor(
        const FakeSession(returnCode: FakeReturnCode(success: true)),
      );
      final kit = $FfmpegKit(executor: executor);

      final result = await kit.trimVideo(
        inputPath: 'input.mp4',
        outputPath: 'trimmed.mp4',
        start: const Duration(milliseconds: 500),
        end: const Duration(milliseconds: 2500),
        quality: 20,
      );

      expect(executor.lastArguments, [
        '-y',
        '-i',
        'input.mp4',
        '-ss',
        '0.5',
        '-t',
        '2',
        '-map',
        '0:v:0',
        '-map',
        '0:a?',
        '-c:v',
        'libx264',
        '-preset',
        'medium',
        '-crf',
        '20',
        '-c:a',
        'aac',
        '-movflags',
        '+faststart',
        'trimmed.mp4',
      ]);
      expect(result.isSuccess, isTrue);
    });

    test('builds a fast stream-copy command', () async {
      final executor = CapturingExecutor(
        const FakeSession(returnCode: FakeReturnCode(success: true)),
      );
      final kit = $FfmpegKit(executor: executor);

      await kit.trimVideo(
        inputPath: 'input.mp4',
        outputPath: 'trimmed.mp4',
        start: const Duration(seconds: 1),
        duration: const Duration(seconds: 3),
        mode: VideoTrimMode.fast,
      );

      expect(executor.lastArguments, [
        '-y',
        '-ss',
        '1',
        '-i',
        'input.mp4',
        '-t',
        '3',
        '-map',
        '0:v:0',
        '-map',
        '0:a?',
        '-c',
        'copy',
        '-avoid_negative_ts',
        'make_zero',
        'trimmed.mp4',
      ]);
    });

    test('requires exactly one valid end or duration', () async {
      final kit = $FfmpegKit(
        executor: CapturingExecutor(
          const FakeSession(returnCode: FakeReturnCode(success: true)),
        ),
      );

      await expectLater(
        kit.trimVideo(
          inputPath: 'input.mp4',
          outputPath: 'trimmed.mp4',
          start: Duration.zero,
        ),
        throwsArgumentError,
      );
      await expectLater(
        kit.trimVideo(
          inputPath: 'input.mp4',
          outputPath: 'trimmed.mp4',
          start: const Duration(seconds: 2),
          end: const Duration(seconds: 1),
        ),
        throwsArgumentError,
      );
    });
  });
}
