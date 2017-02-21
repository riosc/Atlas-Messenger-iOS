platform :ios, '8.0'
source 'https://github.com/CocoaPods/Specs.git'

use_frameworks!
target 'Atlas Messenger' do
  pod 'Atlas'
  pod 'SVProgressHUD'
  pod 'ClusterPrePermissions', '~> 0.1'
  
  target 'Atlas MessengerTests' do
      inherit! :search_paths
      pod 'Expecta'
      pod 'OCMock'
      pod 'KIF'
      pod 'KIFViewControllerActions', git: 'https://github.com/blakewatters/KIFViewControllerActions.git'
      pod 'LYRCountDownLatch'
  end
end

