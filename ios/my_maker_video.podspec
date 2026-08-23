#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint my_maker_video.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'my_maker_video'
  s.version          = '0.2.0'
  s.summary          = 'Flutter video processing helpers backed by FFmpeg.'
  s.description      = <<-DESC
Create videos from image sequences, add watermarks, reduce video quality,
and convert videos to GIFs from Flutter applications.
                       DESC
  s.homepage         = 'https://github.com/ngmduc2012/my_maker_video'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Duc Nguyen' => 'https://github.com/ngmduc2012' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '15.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'

  # This plugin itself does not collect data or access required-reason APIs.
  s.resource_bundles = {'my_maker_video_privacy' => ['Resources/PrivacyInfo.xcprivacy']}
end
