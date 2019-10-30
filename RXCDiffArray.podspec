Pod::Spec.new do |spec|

  spec.name         = "RXCDiffArray"
  spec.version      = "1.0"

  spec.author       = { "ruixingchen" => "rxc@ruixingchen.com" }

  spec.summary      = "an array that can notify its changes"
  spec.description  = "an array that can notify its changes to multi delegates"
  spec.homepage     = "https://github.com/ruixingchen/RXCDiffArray"
  spec.license      = "MIT"

  spec.source       = { :git => "https://github.com/ruixingchen/RXCDiffArray.git", :tag => spec.version.to_s }
  spec.source_files  = "Source/*.swift"

  spec.requires_arc = true
  spec.swift_versions = "5.0"
  spec.ios.deployment_target = '9.0'

  spec.default_subspecs = 'Core', 'UIKitExtension'
  
  spec.subspec 'Core' do |subspec|
    subspec.source_files = 'Source/*.swift'
  end

  spec.subspec 'UIKitExtension' do |subspec|
    source_files = 'Source/Extension/UIKit/*.swift'
    frameworks = 'Foundation', 'UIKit'

    subspec.ios.source_files = source_files
    subspec.ios.frameworks = frameworks
  end

  spec.subspec 'ASDKExtension' do |subspec|
    subspec.dependency 'Texture', '> 2.8'

    source_files = 'Source/Extension/ASDK/*.swift'
    frameworks = 'Foundation', 'UIKit', 'AsyncDisplayKit'

    subspec.ios.source_files = source_files
    subspec.ios.frameworks = frameworks
  end

  spec.subspec 'DifferenceKit' do |subspec|
    subspec.dependency 'DifferenceKit', '~> 1.1'

    source_files = 'Source/DifferenceKit/**/*.swift'
    frameworks = 'Foundation'

    subspec.ios.source_files = source_files
    subspec.ios.frameworks = frameworks
  end

end