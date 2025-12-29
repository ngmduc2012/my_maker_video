import 'dart:io';
import 'dart:ui' as ui;

import 'package:ffmpeg_kit_flutter_full_gpl/ffmpeg_kit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:my_maker_video/my_maker_video.dart';
import 'package:path_provider/path_provider.dart';

Future<void> _writeSolidPng(String path, ui.Color color) async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder, const ui.Rect.fromLTWH(0, 0, 4, 4));
  final paint = ui.Paint()..color = color;
  canvas.drawRect(const ui.Rect.fromLTWH(0, 0, 4, 4), paint);
  final picture = recorder.endRecording();
  final image = await picture.toImage(4, 4);
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

  testWidgets(
    'ffmpeg flow works end-to-end',
    (tester) async {
      final workDir = await _createTempDir();
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
        '-f lavfi -i color=c=blue:s=64x64:d=1 '
        '-f lavfi -i anullsrc=channel_layout=stereo:sample_rate=44100 '
        '-shortest -c:v libx264 -pix_fmt yuv420p -c:a aac '
        '$audioVideoPath',
      );
      final returnCode = await session.getReturnCode();
      expect(returnCode?.isValueSuccess() ?? false, isTrue);

      final watermarkPath = '${outputDir.path}/watermark.png';
      await _writeSolidPng(
        watermarkPath,
        const ui.Color(0xFFFFFFFF),
      );

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
      final reduceResult =
          await MyMakerVideo.ffmpegKit.reduceVideoQualityByPercentage(
        inputPath: audioVideoPath,
        outputPath: reducedPath,
        qualityPercentage: 50,
      );

      expect(reduceResult.isSuccess, isTrue, reason: reduceResult.message);
      expect(await File(reducedPath).exists(), isTrue);
      expect(await File(reducedPath).length(), greaterThan(0));
    },
    timeout: const Timeout(Duration(minutes: 5)),
  );
}
