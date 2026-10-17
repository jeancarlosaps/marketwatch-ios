source 'https://cdn.cocoapods.org/'

platform :ios, '16.0'

target 'MarketWatch' do
  use_frameworks!

  pod 'Alamofire', '~> 5.12'
  pod 'RxSwift', '6.9.0'
  pod 'RxCocoa', '6.9.0'
  pod 'Kingfisher', '8.13.0'
  pod 'SwiftLint', '0.65.1'

  target 'MarketWatchTests' do
    inherit! :search_paths
  end
end

# Pods declare iOS 9/10 deployment targets, below the iOS 12 minimum accepted by Xcode 26.
# Align every pod with the app target to remove those warnings.
post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '16.0'
    end
  end
end
