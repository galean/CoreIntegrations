#
# Be sure to run `pod lib lint CoreIntegrations.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'CoreIntegrations'
  s.version          = '2.2.2c'
  s.summary          = 'CoreIntegrations framework'

  s.description      = 'Description'

  s.homepage         = 'https://github.com/galean/CoreIntegrations.git'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'u-texas' => 'kanarskyi.anatolii@gmail.com' }
  s.source           = { :git => 'https://github.com/galean/CoreIntegrations.git', :branch => 'feature/main_canalytics_fix' }

  s.ios.deployment_target = '15.0'
  
  s.static_framework = true

  s.source_files = 'Sources/**/*.swift'
  #'Sources/**/*'
 
  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'

  s.dependency 'FirebaseRemoteConfig'
  s.dependency 'FirebaseAnalytics'
  s.dependency 'FirebaseCore'
  s.dependency 'FBSDKCoreKit'
  s.dependency 'AppsFlyerFramework'
  s.dependency 'Amplitude'
  s.dependency 'AnalyticsConnector'
  s.dependency 'SwiftyStoreKit'
  s.dependency 'GrowthBook-IOS'
            #s.dependency ''
                #s.dependency ''
                    #s.dependency ''
  
end
