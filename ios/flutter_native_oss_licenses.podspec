#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint flutter_native_oss_licenses.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'flutter_native_oss_licenses'
  s.version          = '1.0.0'
  s.summary          = 'Collects Flutter, CocoaPods, and SwiftPM license notices.'
  s.description      = <<-DESC
Merges Flutter license notices with CocoaPods acknowledgements and remote Swift Package Manager dependency licenses.
                       DESC
  s.homepage         = 'https://github.com/BasalBit/flutter_native_oss_licenses'
  s.license          = { :file => '../LICENSE' }
  s.author           = 'BasalBit'
  s.source           = { :path => '.' }
  s.source_files = 'flutter_native_oss_licenses/Sources/flutter_native_oss_licenses/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '13.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'

  # If your plugin requires a privacy manifest, for example if it uses any
  # required reason APIs, update the PrivacyInfo.xcprivacy file to describe your
  # plugin's privacy impact, and then uncomment this line. For more information,
  # see https://developer.apple.com/documentation/bundleresources/privacy_manifest_files
  # s.resource_bundles = {'flutter_native_oss_licenses_privacy' => ['flutter_native_oss_licenses/Sources/flutter_native_oss_licenses/PrivacyInfo.xcprivacy']}
end
