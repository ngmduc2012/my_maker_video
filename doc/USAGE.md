# MyMakerVideo Usage (Short)

## 1) Add dependency

```yaml
dependencies:
  my_maker_video: ^latest_version
```

## 2) Android configuration

Add/update in `android/app/build.gradle`:

```gradle
defaultConfig {
    minSdk = 24
    targetSdk = flutter.targetSdkVersion
    versionCode = flutter.versionCode
    versionName = flutter.versionName
}
```

Add permissions in `AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES"/>
<uses-permission android:name="android.permission.MANAGE_EXTERNAL_STORAGE"/>
```

## 3) iOS configuration

Add keys in `Info.plist`:

```xml
<key>NSPhotoLibraryUsageDescription</key>
<string>We need access to your photo library to pick files.</string>
<key>NSDocumentDirectoryUsageDescription</key>
<string>We need access to your documents to pick files.</string>
<key>UIFileSharingEnabled</key>
<true/>
<key>LSSupportsOpeningDocumentsInPlace</key>
<true/>
```

Ensure `ios/Podfile` has:

```ruby
platform :ios, '13.0'
```

## 4) Import

```dart
import 'package:my_maker_video/my_maker_video.dart';
```

## 5) Common tasks

Create video from images:

```dart
MyMakerVideo.ffmpegKit.convertImageDirectoryToVideo(
  imagesPath: 'path/to/images',
  outputVideoPath: 'path/to/videoOutput.mp4',
);
```

Add watermark:

```dart
MyMakerVideo.ffmpegKit.addWatermarkToVideo(
  watermarkPath: watermarkPath,
  videoPath: videoPath,
  outputPath: outputPath,
  x: 20,
  y: 30,
  width: 200,
  height: 200,
);
```

Reduce quality:

```dart
MyMakerVideo.ffmpegKit.reduceVideoQualityByPercentage(
  inputPath: videoPath,
  outputPath: outputPath,
  qualityPercentage: 30,
);
```

Create GIF:

```dart
MyMakerVideo.ffmpegKit.createGifFromVideo(
  inputPath: videoPath,
  outputPath: outputGif,
  quality: 100,
  scale: 3200,
  fps: 2,
);
```
