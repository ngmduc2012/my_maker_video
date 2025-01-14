# my_maker_video

A new Flutter project.

## Getting Started

    defaultConfig {
        applicationId = "com.wongcoupon.my_maker_video.my_maker_video_example"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 24
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>
    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
    <uses-permission android:name="android.permission.READ_MEDIA_IMAGES"/>
    <uses-permission android:name="android.permission.MANAGE_EXTERNAL_STORAGE"/>


ios
<key>NSPhotoLibraryUsageDescription</key>
<string>We need access to your photo library to pick files.</string>
<key>NSDocumentDirectoryUsageDescription</key>
<string>We need access to your documents to pick files.</string>
<key>UIFileSharingEnabled</key>
<true/>
<key>LSSupportsOpeningDocumentsInPlace</key>
<true/>

platform :ios, '13.0'