#
# Be sure to run `pod lib lint CoreIntegrations.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'CoreIntegrations'
  s.version          = '2.5.4amplstand'
  s.summary          = 'CoreIntegrations framework'

  s.description      = 'Description'

  s.homepage         = 'https://github.com/galean/CoreIntegrations.git'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'u-texas' => 'kanarskyi.anatolii@gmail.com' }
  s.source           = { :git => 'https://github.com/galean/CoreIntegrations.git', :branch => 'feature/AmplitudeStandalone' }

  s.ios.deployment_target = '15.0'
  
  s.static_framework = true

  s.source_files = 'Sources/**/*.swift'

  s.dependency 'FirebaseRemoteConfig'
  s.dependency 'FirebaseAnalytics'
  s.dependency 'FirebaseCore'
  s.dependency 'FBSDKCoreKit'
  s.dependency 'AppsFlyerFramework'
  s.dependency 'Amplitude'
  s.dependency 'AnalyticsConnector'
  s.dependency 'AmplitudeExperiment'
  s.dependency 'Sentry'
  s.dependency 'Sentry-Dynamic'
  s.dependency 'SentrySwiftUI'
  
end
