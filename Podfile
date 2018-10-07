# Uncomment this line to define a global platform for your project
# platform :ios, '9.0'

target 'iOrder2’ do
# Comment this line if you're not using Swift and don't want to use dynamic frameworks
use_frameworks!

# Pods for iOrder2

# pod 'FontAwesomeKit', '~> 2.2.0'

pod 'FontAwesomeKit', :git => 'https://github.com/PrideChung/FontAwesomeKit.git'
pod 'FMDB'
pod 'MRProgress'
pod "MIBadgeButton-Swift", :git => 'https://github.com/mustafaibrahim989/MIBadgeButton-Swift.git', :branch => 'master'
# pod "MIBadgeButton-Swift"
pod 'NextGrowingTextView'
# pod 'Eureka', '~> 1.7'
pod 'SWTableViewCell'
# pod 'FXForms'
pod 'Toast-Swift', '~> 2.0.0'
# pod 'Alamofire', '~> 3.5.0'
pod 'Alamofire', '~> 4.0'
pod 'ReachabilitySwift', '~> 3'
pod 'LUKeychainAccess'

target 'iOrder2Tests' do
    inherit! :search_paths
    # Pods for testing
end

target 'iOrder2UITests' do
    inherit! :search_paths
    # Pods for testing
end

post_install do | installer |
    require 'fileutils'
    
    #Pods-acknowledgements.plist下記の場所に移動（2015/10/15）
    FileUtils.cp_r('Pods/Target Support Files/Pods-iOrder2/Pods-iOrder2-acknowledgements.plist', ‘iOrder/Settings.bundle/Acknowledgements.plist', :remove_destination => true)
    
    # エラー
    #FileUtils.cp_r('Pods/Pods-acknowledgements.plist', 'TESTSettings/Settings.bundle/Acknowledgements.plist', :remove_destination => true)
    
end

end
