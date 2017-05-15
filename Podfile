platform :ios, '9.0'
source 'git@github.com:layerhq/cocoapods-specs.git'
source 'https://github.com/CocoaPods/Specs.git'

use_frameworks!

target 'Atlas Messenger' do
  pod 'Atlas', git: 'https://github.com/layerhq/Atlas-iOS', branch: 'feature/larry-integration'
  pod 'LayerKit'
  pod 'LayerKitDiagnostics'
  pod 'SVProgressHUD'
  pod 'ClusterPrePermissions', '~> 0.1'
  pod 'VoxeetSDK', '~> 1.0'
  pod 'SwiftyJSON'
  pod 'Alamofire', '~> 4.0.1'
  pod 'SwiftyHue', git: 'https://github.com/Spriter/SwiftyHue.git', branch: 'swift3'
  pod 'SwiftKeychainWrapper'
  pod 'ApiAI'
end

target 'Atlas MessengerTests' do
  pod 'OCMock'
  pod 'Expecta'
  pod 'KIF'
  pod 'KIFViewControllerActions'
  pod 'LYRCountDownLatch'
end

# If we are building LayerKit from source then we need a post install hook to handle non-modular SQLite imports
#unless ENV['LAYER_LAYERKIT_PATH'].blank?
  #post_install do |installer|
   # installer.pods_project.build_configuration_list.build_configurations.each do |configuration|
    #  configuration.build_settings['CLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES'] = 'YES'
    #end
  #end
#end