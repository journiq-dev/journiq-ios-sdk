Pod::Spec.new do |s|
  s.name             = 'JourniqSDK'
  s.version          = '0.5.0'
  s.summary          = 'Journiq iOS SDK — deep linking, attribution, analytics, in-app notifications, and push.'
  s.homepage         = 'https://github.com/journiq-dev/journiq-ios-sdk'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Journiq' => 'ekeh.wisdom@gmail.com' }
  s.source           = { :git => 'https://github.com/journiq-dev/journiq-ios-sdk.git', :tag => s.version.to_s }
  s.source_files     = 'Sources/JourniqSDK/**/*.swift'
  s.platform         = :ios, '14.0'
  s.swift_version    = '5.0'
end
