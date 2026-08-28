#
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint flutter_native_oss_licenses.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'flutter_native_oss_licenses'
  s.version          = '0.1.0'
  s.summary          = 'Collects Flutter, CocoaPods, and SwiftPM license notices.'
  s.description      = <<-DESC
Merges Flutter license notices with CocoaPods acknowledgements and remote Swift Package Manager dependency licenses.
                       DESC
  s.homepage         = 'https://github.com/BasalBit/flutter_native_oss_licenses'
  s.license          = { :file => '../LICENSE' }
  s.author           = 'BasalBit'
  s.source           = { :path => '.' }
  s.source_files = 'flutter_native_oss_licenses/Sources/flutter_native_oss_licenses/**/*'
  s.dependency 'FlutterMacOS'
  s.platform = :osx, '10.15'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
  s.swift_version = '5.0'
end
