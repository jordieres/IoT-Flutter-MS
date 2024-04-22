#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint veepoo_sdk.podspec' to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'veepoo_sdk'
  s.version          = '0.0.1'
  s.summary          = 'Veepoo SDK for flutter'
  s.description      = <<-DESC
Veepoo SDK for flutter
                       DESC
  s.homepage         = 'http://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'email@example.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.dependency 'iOSDFULibrary', '4.15.3'
  s.dependency 'FMDB'
  s.dependency 'AFNetworking', '4.0.1'
  s.vendored_frameworks = 'VeepooBleSDK.framework'
  s.platform = :ios, '12.0'

  # Flutter.framework does not contain a i386 slice. Only x86_64 simulators are supported.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'VALID_ARCHS[sdk=iphonesimulator*]' => 'x86_64' }
  s.swift_version = '5.0'
end
