import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:my_maker_video/my_maker_video.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Plugin my_maker_video example app')),
        body: Center(
          child: SingleChildScrollView(
            child: Column(
              children: [
                ImagesToVideo(),
                Watermark(),
                ReduceVideoQuality(),
                VideoToGif(),
                MediaTools(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ImagesToVideo extends StatefulWidget {
  const ImagesToVideo({super.key});

  @override
  State<ImagesToVideo> createState() => _ImagesToVideoState();
}

class _ImagesToVideoState extends State<ImagesToVideo> {
  String? inputPath;
  String? outputPath;
  String? pathVideo;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          "PART I | Images to video",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        Text("STEP 1 | create folder input-image"),
        TextButton(
          onPressed: () async {
            final downloadPath = await getExampleOutputDirectory();
            inputPath = "${downloadPath.path}/input-image";
            await createDirectory(inputPath!);
            setState(() {});
          },
          child: Text("Create"),
        ),
        Text(
          "STEP 2 | input your images to folder $inputPath with name is number like image with type .png",
        ),
        SizedBox(height: 400, child: Image.asset("assets/image.jpeg")),
        Text("STEP 3 | create folder output video $outputPath"),
        TextButton(
          onPressed: () async {
            final downloadPath = await getExampleOutputDirectory();
            outputPath = "${downloadPath.path}/video";
            await createDirectory(outputPath!);
            setState(() {});
          },
          child: Text("Create"),
        ),
        Text("STEP 4 | app-scoped storage needs no broad storage permission"),
        Text("STEP 5 | create video from list image $pathVideo"),
        Text("NOTE: out put file name has to be unique"),
        TextButton(
          onPressed: () async {
            if (outputPath != null && inputPath != null) {
              final pathVideo =
                  "$outputPath/image-to-video-${Random().nextInt(20)}.mp4";

              final result = await MyMakerVideo.ffmpegKit
                  .convertImageDirectoryToVideo(
                    imagesPath: inputPath!,
                    outputVideoPath: pathVideo,
                    // fps: 2
                  );
              if (!mounted) return;
              setState(() {
                this.pathVideo = pathVideo;
              });
              debugPrint("Result | ${result.message}");
              debugPrint("Path | $pathVideo");
            }

            // }
          },
          child: Text("Create video from image"),
        ),
        Text("STEP 6 | waiting"),
      ],
    );
  }
}

Future<Directory> createDirectory(String path) async {
  debugPrint("Path | $path");
  return await Directory(path).create(recursive: true);
}

Future<Directory> getExampleOutputDirectory() async {
  final documentsDirectory = await getApplicationDocumentsDirectory();
  return createDirectory('${documentsDirectory.path}/my_maker_video');
}

class Watermark extends StatefulWidget {
  const Watermark({super.key});

  @override
  State<Watermark> createState() => _WatermarkState();
}

class _WatermarkState extends State<Watermark> {
  String? watermarkPath;
  String? videoPath;
  String? outputPath;
  String? pathVideo;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          "PART II | Add Watermark To Video",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        Text("STEP 1 | pick video $videoPath"),
        TextButton(
          onPressed: () async {
            videoPath = await pickOneVideo();
            setState(() {});
          },
          child: Text("Select video"),
        ),
        Text("STEP 2 | pick watermark (video or image) $watermarkPath"),
        TextButton(
          onPressed: () async {
            watermarkPath = await pickOneFile(
              allowedExtensions: ["mp4", "png"],
            );
            setState(() {});
          },
          child: Text("Select video"),
        ),
        Text("STEP 3 | create folder output video $outputPath"),
        TextButton(
          onPressed: () async {
            final downloadPath = await getExampleOutputDirectory();
            outputPath = "${downloadPath.path}/video";
            await createDirectory(outputPath!);
            setState(() {});
          },
          child: Text("Create"),
        ),
        Text("STEP 4 | app-scoped storage needs no broad storage permission"),
        Text("STEP 5 | create video with watermark $pathVideo"),
        TextButton(
          onPressed: () async {
            if (outputPath != null &&
                watermarkPath != null &&
                videoPath != null) {
              final pathVideo =
                  "$outputPath/watermark-${Random().nextInt(20)}.mp4";

              final result = await MyMakerVideo.ffmpegKit.addWatermarkToVideo(
                watermarkPath: watermarkPath!,
                videoPath: videoPath!,
                outputPath: pathVideo,
                x: 20,
                y: 30,
                width: 200,
                height: 200,

                // fps: 2
              );
              if (!mounted) return;
              setState(() {
                this.pathVideo = pathVideo;
              });
              debugPrint("Result | ${result.message}");
              debugPrint("Path | $pathVideo");
            }

            // }
          },
          child: Text("Create video from image"),
        ),
        Text("STEP 6 | waiting"),
      ],
    );
  }
}

Future<String?> pickOneFile({List<String>? allowedExtensions}) async {
  final file = await FilePicker.pickFile(
    type: allowedExtensions == null ? FileType.any : FileType.custom,
    allowedExtensions: allowedExtensions,
  );
  return file?.path;
}

Future<String?> pickOneVideo() async {
  final file = await FilePicker.pickFile(type: FileType.video);
  return file?.path;
}

class ReduceVideoQuality extends StatefulWidget {
  const ReduceVideoQuality({super.key});

  @override
  State<ReduceVideoQuality> createState() => _ReduceVideoQualityState();
}

class _ReduceVideoQualityState extends State<ReduceVideoQuality> {
  String? videoPath;
  String? outputPath;
  String? pathVideo;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          "PART III | Reduce Video Quality",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        Text("STEP 1 | pick video $videoPath"),
        TextButton(
          onPressed: () async {
            videoPath = await pickOneVideo();
            setState(() {});
          },
          child: Text("Select video"),
        ),
        Text("STEP 2 | create folder output video $outputPath"),
        TextButton(
          onPressed: () async {
            final downloadPath = await getExampleOutputDirectory();
            outputPath = "${downloadPath.path}/video";
            await createDirectory(outputPath!);
            setState(() {});
          },
          child: Text("Create"),
        ),
        Text("STEP 3 | app-scoped storage needs no broad storage permission"),
        Text("STEP 4 | reduce quality of video $pathVideo"),
        TextButton(
          onPressed: () async {
            if (outputPath != null && videoPath != null) {
              final pathVideo =
                  "$outputPath/reduce-quality-${Random().nextInt(20)}.mp4";

              final result = await MyMakerVideo.ffmpegKit
                  .reduceVideoQualityByPercentage(
                    inputPath: videoPath!,
                    outputPath: pathVideo,
                    qualityPercentage: 30,
                  );

              if (!mounted) return;
              setState(() {
                this.pathVideo = pathVideo;
              });
              debugPrint("Result | ${result.message}");
              debugPrint("Path | $pathVideo");
            }

            // }
          },
          child: Text("Create video from image"),
        ),
        Text("STEP 5 | waiting"),
      ],
    );
  }
}

class VideoToGif extends StatefulWidget {
  const VideoToGif({super.key});

  @override
  State<VideoToGif> createState() => _VideoToGifState();
}

class _VideoToGifState extends State<VideoToGif> {
  String? videoPath;
  String? outputPath;
  String? pathVideo;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          "PART IV | Video to gif",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        Text("STEP 1 | pick video $videoPath"),
        TextButton(
          onPressed: () async {
            videoPath = await pickOneVideo();
            setState(() {});
          },
          child: Text("Select video"),
        ),
        Text("STEP 2 | create folder output video $outputPath"),
        TextButton(
          onPressed: () async {
            final downloadPath = await getExampleOutputDirectory();
            outputPath = "${downloadPath.path}/video";
            await createDirectory(outputPath!);
            setState(() {});
          },
          child: Text("Create"),
        ),
        Text("STEP 3 | app-scoped storage needs no broad storage permission"),
        Text("STEP 4 | create gif from video $pathVideo"),
        TextButton(
          onPressed: () async {
            if (outputPath != null && videoPath != null) {
              final pathGif = "$outputPath/gif-${Random().nextInt(20)}.gif";

              final result = await MyMakerVideo.ffmpegKit.createGifFromVideo(
                inputPath: videoPath!,
                outputPath: pathGif,
                quality: 10,
                scale: 320,
                fps: 2,
              );

              if (!mounted) return;
              setState(() {
                pathVideo = pathGif;
              });
              debugPrint("Result | ${result.message}");
              debugPrint("Path | $pathGif");
            }

            // }
          },
          child: Text("Create video from image"),
        ),
        Text("STEP 5 | waiting"),
      ],
    );
  }
}

class MediaTools extends StatefulWidget {
  const MediaTools({super.key});

  @override
  State<MediaTools> createState() => _MediaToolsState();
}

class _MediaToolsState extends State<MediaTools> {
  String? videoPath;
  String status = 'Select a video to inspect or edit.';
  double? progress;
  FfmpegJob? activeJob;
  StreamSubscription<FfmpegProgress>? progressSubscription;

  @override
  void dispose() {
    unawaited(progressSubscription?.cancel());
    unawaited(activeJob?.cancel());
    super.dispose();
  }

  Future<String> _newOutputPath(String filename) async {
    final directory = await getExampleOutputDirectory();
    return '${directory.path}/$filename';
  }

  Future<void> _inspect() async {
    final input = videoPath;
    if (input == null) return;
    final result = await MyMakerVideo.ffmpegKit.inspectMedia(inputPath: input);
    if (!mounted) return;
    final info = result.mediaInfo;
    setState(() {
      status = result.isSuccess
          ? '${info?.duration?.inMilliseconds} ms | '
                '${info?.videoStream?.width}x${info?.videoStream?.height} | '
                'video=${info?.videoStream?.codec} | '
                'audio=${info?.audioStream?.codec}'
          : result.message;
    });
  }

  Future<void> _extractThumbnail() async {
    final input = videoPath;
    if (input == null) return;
    final output = await _newOutputPath(
      'thumbnail-${DateTime.now().millisecondsSinceEpoch}.jpg',
    );
    final result = await MyMakerVideo.ffmpegKit.extractThumbnail(
      inputPath: input,
      outputPath: output,
      position: const Duration(milliseconds: 500),
      width: 320,
    );
    if (!mounted) return;
    setState(() => status = result.isSuccess ? output : result.message);
  }

  Future<void> _trim() async {
    final input = videoPath;
    if (input == null) return;
    final output = await _newOutputPath(
      'trim-${DateTime.now().millisecondsSinceEpoch}.mp4',
    );
    final result = await MyMakerVideo.ffmpegKit.trimVideo(
      inputPath: input,
      outputPath: output,
      start: Duration.zero,
      duration: const Duration(seconds: 1),
    );
    if (!mounted) return;
    setState(() => status = result.isSuccess ? output : result.message);
  }

  Future<void> _startCompression() async {
    final input = videoPath;
    if (input == null) return;
    await progressSubscription?.cancel();
    final output = await _newOutputPath(
      'job-${DateTime.now().millisecondsSinceEpoch}.mp4',
    );
    final job = await MyMakerVideo.ffmpegKit
        .startReduceVideoQualityByPercentage(
          inputPath: input,
          outputPath: output,
          qualityPercentage: 50,
        );
    if (!mounted) {
      await job.cancel();
      return;
    }
    setState(() {
      activeJob = job;
      progress = 0;
    });
    progressSubscription = job.progress.listen((value) {
      if (!mounted) return;
      setState(() => progress = value.percentage);
    });
    final result = await job.result;
    if (!mounted) return;
    setState(() {
      activeJob = null;
      status = result.isSuccess ? output : result.message;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'PART V | Media info, thumbnail, trim, and progress',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        TextButton(
          onPressed: () async {
            final selected = await pickOneVideo();
            if (!mounted) return;
            setState(() => videoPath = selected);
          },
          child: Text('Select video'),
        ),
        Text(videoPath ?? 'No video selected'),
        Wrap(
          alignment: WrapAlignment.center,
          children: [
            TextButton(onPressed: _inspect, child: Text('Inspect media')),
            TextButton(
              onPressed: _extractThumbnail,
              child: Text('Extract thumbnail'),
            ),
            TextButton(onPressed: _trim, child: Text('Trim first second')),
            TextButton(
              onPressed: activeJob == null ? _startCompression : null,
              child: Text('Start job'),
            ),
            TextButton(onPressed: activeJob?.cancel, child: Text('Cancel job')),
          ],
        ),
        if (progress != null) LinearProgressIndicator(value: progress! / 100),
        Text(status),
      ],
    );
  }
}
