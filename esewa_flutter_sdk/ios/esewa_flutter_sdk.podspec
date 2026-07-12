#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint esewa_flutter_sdk.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'esewa_flutter_sdk'
  s.version          = '0.0.1'
  s.summary          = 'eSewa Flutter SDK'
  s.description      = <<-DESC
eSewa Flutter SDK. Android uses the native eSewa SDK; iOS uses a compile-safe stub
because the vendored EsewaSDK.framework is incompatible with Xcode 16+.
                       DESC
  s.homepage         = 'http://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'email@example.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '12.0'

  # Do not vendor EsewaSDK.framework on iOS — Swift 5.10 binary module breaks under Swift 6.
  # The framework remains in ios/EsewaSDK.framework for reference / future SDK updates.

  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'
end
