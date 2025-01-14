import 'dart:io';
import 'dart:math';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:async';

import 'package:my_maker_video/my_maker_video.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin my_maker_video example app'),
        ),
        body: Center(
          child: SingleChildScrollView(
            child: Column(
              children: [
                ImagesToVideo(),
                Watermark(),
                ReduceVideoQuality(),
                VideoToGif(),
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
        Text("PART I | Images to video", style: TextStyle(fontWeight: FontWeight.bold),),
        Text("STEP 1 | create folder input-image"),
        TextButton(onPressed: () async {
          final downloadPath = !kIsWeb && Platform.isAndroid ?  await createDirectory("/storage/emulated/0/Download/my_maker_video") : await getApplicationDocumentsDirectory();
          inputPath = "${downloadPath.path}/input-image";
          await createDirectory(inputPath!);
          setState(() {

          });
        },
            child: Text("Create")),
        Text("STEP 2 | input your images to folder $inputPath with name is number like image with type .png"),
        SizedBox(
            height: 400,
            child: Image.asset("assets/image.jpeg")),
        Text("STEP 3 | create folder output video ${outputPath}"),
        TextButton(onPressed: () async {
          final downloadPath = !kIsWeb && Platform.isAndroid ?  await createDirectory("/storage/emulated/0/Download/my_maker_video") : await getApplicationDocumentsDirectory();
          outputPath = "${downloadPath.path}/video";
          await createDirectory(outputPath!);
          setState(() {

          });
        },
            child: Text("Create")),
        Text("STEP 4 | allow permission save video"),
        TextButton(onPressed: () async {
          await Permission.storage.request().isGranted;
          await Permission.photos.request().isGranted;
        },
            child: Text("allow")),
        Text("STEP 5 | create video from list image $pathVideo"),
        Text("NOTE: out put file name has to be unique"),

        TextButton(onPressed: () async {

          if(outputPath != null && inputPath != null){
            final pathVideo = "$outputPath/image-to-video-${Random().nextInt(20)}.mp4";

            final result = MyMakerVideo.ffmpegKit.convertImageDirectoryToVideo(
              imagesPath: inputPath!,
              outputVideoPath: pathVideo,
              // fps: 2
            );
            setState(() {
              this.pathVideo = pathVideo;
            });
            print("Path | ${pathVideo}");
          }

          // }

        }, child: Text("Create video from image")),
        Text("STEP 6 | waiting"),
      ],
    );
  }
}

Future<Directory> createDirectory(String path) async {
  print("Path | ${path}");
  return await Directory(path).create(recursive: true);
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
        Text("PART II | Add Watermark To Video", style: TextStyle(fontWeight: FontWeight.bold),),
        Text("STEP 1 | pick video $videoPath"),
        TextButton(onPressed: () async {
          videoPath = await pickOneVideo();
          setState(() {

          });
        }, child: Text("Select video")),
        Text("STEP 2 | pick watermark (video or image) $watermarkPath"),
        TextButton(onPressed: () async {
          watermarkPath = await pickOneFile(allowedExtensions: ["mp4", "png"]);
          setState(() {

          });
        }, child: Text("Select video")),
        Text("STEP 3 | create folder output video ${outputPath}"),
        TextButton(onPressed: () async {
          final downloadPath = !kIsWeb && Platform.isAndroid ?  await createDirectory("/storage/emulated/0/Download/my_maker_video") : await getApplicationDocumentsDirectory();
          outputPath = "${downloadPath.path}/video";
          await createDirectory(outputPath!);
          setState(() {

          });
        },
            child: Text("Create")),
        Text("STEP 4 | allow permission save video"),
        TextButton(onPressed: () async {
          await Permission.storage.request().isGranted;
          await Permission.photos.request().isGranted;
        },
            child: Text("allow")),
        Text("STEP 5 | create video with watermark $pathVideo"),
        TextButton(onPressed: () async {

          if(outputPath != null && watermarkPath != null && videoPath != null){
            final pathVideo = "$outputPath/watermark-${Random().nextInt(20)}.mp4";

            final result = MyMakerVideo.ffmpegKit.addWatermarkToVideo(
                watermarkPath: watermarkPath!,
                videoPath: videoPath!,
                outputPath: pathVideo,
                x: 20,
                y: 30,
                width: 200,
                height: 200

              // fps: 2
            );
            setState(() {
              this.pathVideo = pathVideo;
            });
            print("Path | ${pathVideo}");
          }

          // }

        }, child: Text("Create video from image")),
        Text("STEP 6 | waiting"),
      ],
    );
  }
}

Future<String?> pickOneFile({List<String>? allowedExtensions}) async {
  final FilePickerResult? result = await FilePicker.platform.pickFiles(
    type: allowedExtensions == null ? FileType.any : FileType.custom,
    allowedExtensions: allowedExtensions,
  );
  return result?.files.single.path!;
}

Future<String?> pickOneVideo() async {
  final FilePickerResult? result = await FilePicker.platform.pickFiles(
    type:  FileType.video,
  );
  return result?.files.single.path!;
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
        Text("PART III | Reduce Video Quality", style: TextStyle(fontWeight: FontWeight.bold),),
        Text("STEP 1 | pick video $videoPath"),
        TextButton(onPressed: () async {
          videoPath = await pickOneVideo();
          setState(() {

          });
        }, child: Text("Select video")),
        Text("STEP 2 | create folder output video ${outputPath}"),
        TextButton(onPressed: () async {
          final downloadPath = !kIsWeb && Platform.isAndroid ?  await createDirectory("/storage/emulated/0/Download/my_maker_video") : await getApplicationDocumentsDirectory();
          outputPath = "${downloadPath.path}/video";
          await createDirectory(outputPath!);
          setState(() {

          });
        },
            child: Text("Create")),
        Text("STEP 3 | allow permission save video"),
        TextButton(onPressed: () async {
          await Permission.storage.request().isGranted;
          await Permission.photos.request().isGranted;
        },
            child: Text("allow")),
        Text("STEP 4 | reduce quality of video $pathVideo"),
        TextButton(onPressed: () async {

          if(outputPath != null  && videoPath != null){
            final pathVideo = "$outputPath/reduce-quality-${Random().nextInt(20)}.mp4";

            final result = MyMakerVideo.ffmpegKit.reduceVideoQualityByPercentage(
                inputPath: videoPath!,
                outputPath: pathVideo,
                qualityPercentage: 30);
            
            setState(() {
              this.pathVideo = pathVideo;
            });
            print("Path | ${pathVideo}");
          }

          // }

        }, child: Text("Create video from image")),
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
        Text("PART IV | Video to gif", style: TextStyle(fontWeight: FontWeight.bold),),
        Text("STEP 1 | pick video $videoPath"),
        TextButton(onPressed: () async {
          videoPath = await pickOneVideo();
          setState(() {

          });
        }, child: Text("Select video")),
        Text("STEP 2 | create folder output video ${outputPath}"),
        TextButton(onPressed: () async {
          final downloadPath = !kIsWeb && Platform.isAndroid ?  await createDirectory("/storage/emulated/0/Download/my_maker_video") : await getApplicationDocumentsDirectory();
          outputPath = "${downloadPath.path}/video";
          await createDirectory(outputPath!);
          setState(() {

          });
        },
            child: Text("Create")),
        Text("STEP 3 | allow permission save video"),
        TextButton(onPressed: () async {
          await Permission.storage.request().isGranted;
          await Permission.photos.request().isGranted;
        },
            child: Text("allow")),
        Text("STEP 4 | create gif from video $pathVideo"),
        TextButton(onPressed: () async {

          if(outputPath != null  && videoPath != null){
            final pathVideo = "$outputPath/gif-${Random().nextInt(20)}.gif";

            final result = MyMakerVideo.ffmpegKit.createGifFromVideo(
                inputPath: videoPath!,
                outputPath: pathVideo,
                quality: 100,
                scale : 3200,
                fps: 2,);

            setState(() {
              this.pathVideo = pathVideo;
            });
            print("Path | ${pathVideo}");
          }

          // }

        }, child: Text("Create video from image")),
        Text("STEP 5 | waiting"),
      ],
    );
  }
}


