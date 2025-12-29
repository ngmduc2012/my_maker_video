import 'package:flutter_test/flutter_test.dart';
import 'package:my_maker_video/my_maker_video.dart';

class FakeReturnCode {
  const FakeReturnCode({this.success = false, this.cancel = false});

  final bool success;
  final bool cancel;

  bool isValueSuccess() => success;
  bool isValueCancel() => cancel;

  @override
  String toString() =>
      'FakeReturnCode(success: $success, cancel: $cancel)';
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

  @override
  Future<FfmpegSession> execute(String command) async {
    lastCommand = command;
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
  Future<dynamic> getReturnCode() async =>
      const FakeReturnCode(success: true);
  Future<String?> getOutput() async => 'native output';
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

      const expectedCommand = '-framerate 12 -i images/%d.png '
          '-r 30 '
          '-crf 23 -preset slow '
          '-vf "scale=trunc(iw/2)*2:trunc(ih/2)*2" '
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
      expect(
        command,
        contains('-vf "scale=trunc(iw/2)*2:trunc(ih/2)*2"'),
      );
      expect(
        command,
        contains(
          '-c:v libx264 -pix_fmt yuv420p -movflags +faststart out.mp4',
        ),
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

    test('throws assertion when fps is invalid', () async {
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
        throwsAssertionError,
      );
    });

    test('throws assertion when quality is invalid', () async {
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
        throwsAssertionError,
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
          '-i input.mp4 -i mark.png -filter_complex '
          '"[1:v]scale=100:200[wm];[0:v][wm]overlay=10:20" '
          '-codec:a copy out.mp4';

      expect(executor.lastCommand, expectedCommand);
    });

    test('uses overlay filter when only width is provided', () async {
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
      );

      const expectedCommand =
          '-i input.mp4 -i mark.png -filter_complex "overlay=10:20" '
          '-codec:a copy out.mp4';

      expect(executor.lastCommand, expectedCommand);
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
          '-i input.mp4 -i mark.png -filter_complex "overlay=10:20" '
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
      expect(result.message, contains('Failed to add watermark'));
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
          '-i input.mp4 -crf 41 -preset fast -b:v 1850k -codec:a copy out.mp4';

      expect(executor.lastCommand, expectedCommand);
      expect(result.isSuccess, isTrue);
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
      expect(result.message, contains('reduceVideoQualityByPercentage'));
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
          '-i input.mp4 -vf "fps=1.5,scale=320:-1:flags=lanczos" -q:v 10 out.gif';

      expect(executor.lastCommand, expectedCommand);
      expect(result.isSuccess, isTrue);
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
          '-i input.mp4 -vf "fps=2.0,scale=200:-1:flags=lanczos" -q:v 5 out.gif';

      expect(executor.lastCommand, expectedCommand);
      expect(result.isSuccess, isFalse);
      expect(result.message, contains('Failed to create GIF'));
    });
  });
}
