import 'dart:io';
import 'dart:ui' as ui;

import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:my_maker_video/my_maker_video.dart';
import 'package:path_provider/path_provider.dart';

Future<void> _writeSolidPng(
  String path,
  ui.Color color, {
  int width = 4,
  int height = 4,
}) async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(
    recorder,
    ui.Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
  );
  final paint = ui.Paint()..color = color;
  canvas.drawRect(
    ui.Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
    paint,
  );
  final picture = recorder.endRecording();
  final image = await picture.toImage(width, height);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();

  if (data == null) {
    throw StateError('Failed to encode PNG bytes.');
  }

  await File(path).writeAsBytes(data.buffer.asUint8List(), flush: true);
}

Future<Directory> _createTempDir() async {
  final base = await getTemporaryDirectory();
  final dir = Directory(
    '${base.path}/my_maker_video_it_${DateTime.now().millisecondsSinceEpoch}',
  );
  return dir.create(recursive: true);
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('ffmpeg flow works end-to-end', (tester) async {
    final workDir = await _createTempDir();
    addTearDown(() async {
      if (await workDir.exists()) await workDir.delete(recursive: true);
    });
    final imagesDir = Directory('${workDir.path}/images');
    final outputDir = Directory('${workDir.path}/output');
    await imagesDir.create(recursive: true);
    await outputDir.create(recursive: true);

    await _writeSolidPng('${imagesDir.path}/1.png', const ui.Color(0xFFFF0000));
    await _writeSolidPng('${imagesDir.path}/2.png', const ui.Color(0xFF00FF00));

    final videoPath = '${outputDir.path}/images.mp4';
    final convertResult = await MyMakerVideo.ffmpegKit
        .convertImageDirectoryToVideo(
          imagesPath: imagesDir.path,
          outputVideoPath: videoPath,
          framerate: 1,
        );

    expect(convertResult.isSuccess, isTrue, reason: convertResult.message);
    expect(await File(videoPath).exists(), isTrue);
    expect(await File(videoPath).length(), greaterThan(0));

    final gifPath = '${outputDir.path}/out.gif';
    final gifResult = await MyMakerVideo.ffmpegKit.createGifFromVideo(
      inputPath: videoPath,
      outputPath: gifPath,
      fps: 2,
      quality: 10,
    );

    expect(gifResult.isSuccess, isTrue, reason: gifResult.message);
    expect(await File(gifPath).exists(), isTrue);
    expect(await File(gifPath).length(), greaterThan(0));

    final audioVideoPath = '${outputDir.path}/audio.mp4';
    final session = await FFmpegKit.execute(
      '-f lavfi -i color=c=blue:s=64x64:d=2 '
      '-f lavfi -i anullsrc=channel_layout=stereo:sample_rate=44100 '
      '-shortest -c:v libx264 -pix_fmt yuv420p -c:a aac '
      '$audioVideoPath',
    );
    final returnCode = await session.getReturnCode();
    expect(returnCode?.isValueSuccess() ?? false, isTrue);

    final mediaResult = await MyMakerVideo.ffmpegKit.inspectMedia(
      inputPath: audioVideoPath,
    );
    expect(mediaResult.isSuccess, isTrue, reason: mediaResult.message);
    expect(mediaResult.mediaInfo?.hasVideo, isTrue);
    expect(mediaResult.mediaInfo?.hasAudio, isTrue);
    expect(mediaResult.mediaInfo?.videoStream?.width, 64);
    expect(
      mediaResult.mediaInfo?.duration?.inMilliseconds,
      inInclusiveRange(1900, 2100),
    );

    final thumbnailPath = '${outputDir.path}/thumbnail.jpg';
    final thumbnailResult = await MyMakerVideo.ffmpegKit.extractThumbnail(
      inputPath: audioVideoPath,
      outputPath: thumbnailPath,
      position: const Duration(milliseconds: 500),
      width: 32,
    );
    expect(thumbnailResult.isSuccess, isTrue, reason: thumbnailResult.message);
    expect(await File(thumbnailPath).exists(), isTrue);
    expect(await File(thumbnailPath).length(), greaterThan(0));
    final thumbnailInfo = await MyMakerVideo.ffmpegKit.inspectMedia(
      inputPath: thumbnailPath,
    );
    expect(thumbnailInfo.isSuccess, isTrue, reason: thumbnailInfo.message);
    expect(thumbnailInfo.mediaInfo?.videoStream?.width, 32);
    expect(thumbnailInfo.mediaInfo?.videoStream?.height, 32);

    final accurateTrimPath = '${outputDir.path}/trim-accurate.mp4';
    final accurateTrimResult = await MyMakerVideo.ffmpegKit.trimVideo(
      inputPath: audioVideoPath,
      outputPath: accurateTrimPath,
      start: const Duration(milliseconds: 250),
      duration: const Duration(milliseconds: 750),
    );
    expect(
      accurateTrimResult.isSuccess,
      isTrue,
      reason: accurateTrimResult.message,
    );
    expect(await File(accurateTrimPath).exists(), isTrue);
    expect(await File(accurateTrimPath).length(), greaterThan(0));
    final accurateTrimInfo = await MyMakerVideo.ffmpegKit.inspectMedia(
      inputPath: accurateTrimPath,
    );
    expect(
      accurateTrimInfo.mediaInfo?.duration?.inMilliseconds,
      inInclusiveRange(700, 850),
    );

    final fastTrimPath = '${outputDir.path}/trim-fast.mp4';
    final fastTrimResult = await MyMakerVideo.ffmpegKit.trimVideo(
      inputPath: audioVideoPath,
      outputPath: fastTrimPath,
      start: Duration.zero,
      duration: const Duration(seconds: 1),
      mode: VideoTrimMode.fast,
    );
    expect(fastTrimResult.isSuccess, isTrue, reason: fastTrimResult.message);
    expect(await File(fastTrimPath).exists(), isTrue);
    expect(await File(fastTrimPath).length(), greaterThan(0));
    final fastTrimInfo = await MyMakerVideo.ffmpegKit.inspectMedia(
      inputPath: fastTrimPath,
    );
    expect(
      fastTrimInfo.mediaInfo?.duration?.inMilliseconds,
      inInclusiveRange(850, 1250),
    );

    final watermarkPath = '${outputDir.path}/watermark.png';
    await _writeSolidPng(watermarkPath, const ui.Color(0xFFFFFFFF));

    final watermarkOut = '${outputDir.path}/watermark.mp4';
    final watermarkResult = await MyMakerVideo.ffmpegKit.addWatermarkToVideo(
      videoPath: audioVideoPath,
      watermarkPath: watermarkPath,
      outputPath: watermarkOut,
      x: 8,
      y: 8,
      width: 16,
      height: 16,
    );

    expect(watermarkResult.isSuccess, isTrue, reason: watermarkResult.message);
    expect(await File(watermarkOut).exists(), isTrue);
    expect(await File(watermarkOut).length(), greaterThan(0));

    final reducedPath = '${outputDir.path}/reduced.mp4';
    final reduceJob = await MyMakerVideo.ffmpegKit
        .startReduceVideoQualityByPercentage(
          inputPath: audioVideoPath,
          outputPath: reducedPath,
          qualityPercentage: 50,
        );
    final progressFuture = reduceJob.progress.toList();
    final reduceResult = await reduceJob.result;
    final progress = await progressFuture;

    expect(reduceResult.isSuccess, isTrue, reason: reduceResult.message);
    expect(await File(reducedPath).exists(), isTrue);
    expect(await File(reducedPath).length(), greaterThan(0));
    expect(progress, isNotEmpty);
    expect(progress.last.percentage, isNotNull);
    expect(progress.last.percentage, inInclusiveRange(0, 100));

    final cancelImagesDir = Directory('${workDir.path}/cancel-images');
    await cancelImagesDir.create(recursive: true);
    final seedImage = File('${cancelImagesDir.path}/1.png');
    await _writeSolidPng(
      seedImage.path,
      const ui.Color(0xFF336699),
      width: 640,
      height: 360,
    );
    final seedBytes = await seedImage.readAsBytes();
    for (var index = 2; index <= 240; index++) {
      await File('${cancelImagesDir.path}/$index.png').writeAsBytes(seedBytes);
    }

    final cancelledOutput = '${outputDir.path}/cancelled.mp4';
    final cancellableJob = await MyMakerVideo.ffmpegKit
        .startConvertImageDirectoryToVideo(
          imagesPath: cancelImagesDir.path,
          outputVideoPath: cancelledOutput,
          framerate: 30,
          quality: 23,
        );
    await cancellableJob.cancel();
    final cancelledResult = await cancellableJob.result;
    expect(cancelledResult.isSuccess, isFalse);
    expect(cancelledResult.message, contains('cancelled'));
    expect(await File(cancelledOutput).exists(), isFalse);
  }, timeout: const Timeout(Duration(minutes: 5)));
}
