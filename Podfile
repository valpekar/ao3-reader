# Uncomment this line to define a global platform for your project
platform :ios, '14.0'
source 'https://github.com/CocoaPods/Specs.git'

target 'ArchiveOfOurOwnReader' do
  # Comment this line if you're not using Swift and don't want to use dynamic frameworks
  use_frameworks!

  # Pods for ArchiveOfOurOwnReader

pod 'Firebase'
pod 'FirebaseCore'
pod 'FirebaseAnalytics'
pod 'FirebaseCrashlytics'
pod 'Alamofire', '~> 4.0'
pod 'AlamofireImage'
pod 'Spring', :git => 'https://github.com/MengTo/Spring.git'
pod 'KRProgressHUD'
pod 'ExpandableLabel'
pod 'PopupDialog'
pod 'SwiftMessages'
pod 'RxSwift'

  target 'ArchiveOfOurOwnReaderTests' do
    inherit! :search_paths
    # Pods for testing
  end

end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '14.0'
      
    end
  end
end

