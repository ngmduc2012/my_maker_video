part of '../my_maker_video.dart';

/// Part 1: For get data like: get image path.
class $FfmpegKit{
  const $FfmpegKit();
/*
   Learn more: https://pub.dev/packages/ffmpeg_kit_flutter_full_gpl

   Functions is supported at https://github.com/arthenica/ffmpeg-kit/wiki/Packages

   Thay thế cho thư viện gify https://pub.dev/packages/gify, gify sử dụng các tương tự nhưng khá chậm
*/

  /// NOTE | mp4 in this function can not play normal on web



  Future<({bool isSuccess, String message})> convertImageDirectoryToVideo({
    required String imagesPath,
    required String outputVideoPath,
    int framerate = 24,
    int? fps,
    int? quality,
  }) async {
    var isSuccess = false;
    var message = "";

    if(fps != null) assert(fps > 0);
    if(quality != null) assert(quality > 0);

    // final command = '-framerate $framerate -i $imagesPath/%d.png '
    //     '-c:v libx264 -pix_fmt yuv420p -movflags +faststart $outputVideoPath';

    /*
    -vf "scale=trunc(iw/2)*2:trunc(ih/2)*2": This filter scales the width (iw) and height (ih) of the images to the nearest even number, ensuring they are divisible by 2. This adjustment is necessary for compatibility with the H.264 encoder.
     */
    final command = '-framerate $framerate -i $imagesPath/%d.png '
        '${fps != null ? "-r $fps" : ""} '
        '${quality != null ? "-crf $quality -preset slow" : ""} '
        '-vf "scale=trunc(iw/2)*2:trunc(ih/2)*2" '
        // '-vf "scale=3200:-1:flags=lanczos" '
        '-c:v libx264 -pix_fmt yuv420p -movflags +faststart $outputVideoPath';

    await FFmpegKit.execute(command).then((session) async {
      final returnCode = await session.getReturnCode();

      if (returnCode?.isValueSuccess() ?? false) {
        message = 'Video conversion successful!';
        isSuccess = true;
      } else if (returnCode?.isValueCancel() ?? false) {
        message = 'Video conversion cancelled!';
      } else {
        final output = await session.getOutput();
        message = 'Video conversion failed with return code $returnCode | log in $output';
      }
    }).whenComplete(() {});

    return (isSuccess: isSuccess, message: message);
  }

  Future<({bool isSuccess, String message})> addWatermarkToVideo({
    required String videoPath,
    required String watermarkPath,
    required String outputPath,
    required int x, // Vị trí watermark trên trục X
    required int y, // Vị trí watermark trên trục Y
    int? width,     // Chiều rộng watermark (nếu muốn thay đổi kích thước)
    int? height,    // Chiều cao watermark (nếu muốn thay đổi kích thước)
  }) async {
    var isSuccess = false;
    var message = "";

    // Lệnh FFmpeg
    final scaleFilter = (width != null && height != null)
        ? "[1:v]scale=$width:$height[wm];[0:v][wm]overlay=$x:$y"
        : "overlay=$x:$y";
    final command = '-i $videoPath -i $watermarkPath -filter_complex "$scaleFilter" -codec:a copy $outputPath';

    await FFmpegKit.execute(command).then((session) async {
      final returnCode = await session.getReturnCode();
      if (returnCode?.isValueSuccess() ?? false) {
        message = "Watermark added successfully!";
        isSuccess = true;
      } else {
        message = "Failed to add watermark with return code $returnCode";
      }
    });

    return (isSuccess: isSuccess, message: message);
  }

  Future<({bool isSuccess, String message})> reduceVideoQualityByPercentage({
    required String inputPath,
    required String outputPath,
    required double qualityPercentage}) async {
    // Map the quality percentage to a CRF value
    // Assuming 100% quality maps to CRF 18 (high quality) and 0% maps to CRF 51 (very low quality)
    final crfValue = (51 - 18) * (1 - qualityPercentage / 100) + 18;
    final preset = 'fast'; // Use a faster preset for quicker processing

    // Optionally, adjust the bitrate based on quality percentage
    // Assuming 100% quality maps to a high bitrate and 0% to a low bitrate
    final maxBitrate = 5000; // Example max bitrate in kbps
    final minBitrate = 500;  // Example min bitrate in kbps
    final bitrate = ((maxBitrate - minBitrate) * (qualityPercentage / 100) + minBitrate).toInt();

    final command = '-i $inputPath -crf ${crfValue.toInt()} -preset $preset -b:v ${bitrate}k -codec:a copy $outputPath';

    var isSuccess = false;
    var message = "";
    await FFmpegKit.execute(command).then((session) async {
      final returnCode = await session.getReturnCode();
      if (returnCode?.isValueSuccess() ?? false) {
        message = "Watermark added successfully!";
        isSuccess = true;
      } else {
        message = "Failed to reduceVideoQualityByPercentage with return code $returnCode";
      }
    });

    return (isSuccess: isSuccess, message: message);
  }


  /*
  Explanation
  -vf "fps=$fps,scale=320:-1:flags=lanczos": This sets the frame rate of the GIF and scales the video. The scale=320:-1 option resizes the video to a width of 320 pixels while maintaining the aspect ratio. You can adjust the width as needed.
  -q:v $quality: This sets the quality of the GIF. Lower values mean better quality. Adjust this value to control the quality of the output GIF.
  $outputPath: The path where the resulting GIF will be saved.
   */
  Future<({bool isSuccess, String message})> createGifFromVideo({
    required String inputPath,
    required String outputPath,
    required double fps,
    required int quality,
    int scale = 320,
  }) async {
    // The quality parameter for GIFs is typically controlled by the `-q:v` option
    // Lower values mean better quality (e.g., 1 is high quality, 31 is low quality)
    final command = '-i $inputPath -vf "fps=$fps,scale=$scale:-1:flags=lanczos" -q:v $quality $outputPath';

    var isSuccess = false;
    var message = "";
    await FFmpegKit.execute(command).then((session) async {
      final returnCode = await session.getReturnCode();
      if (returnCode?.isValueSuccess() ?? false) {
        message = "Watermark added successfully!";
        isSuccess = true;
      } else {
        message =  "Failed to create GIF with return code $returnCode";
      }
    });
    return (isSuccess: isSuccess, message: message);
  }



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

