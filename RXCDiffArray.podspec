Pod::Spec.new do |spec|

  spec.name         = "RXCDiffArray"
  spec.version      = "1.2"

  spec.author       = { "ruixingchen" => "rxc@ruixingchen.com" }

  spec.summary      = "an array that can notify its changes"
  spec.description  = "an array that can notify its changes to multi delegates"
  spec.homepage     = "https://github.com/ruixingchen/RXCDiffArray"
  spec.license      = "MIT"

  spec.source       = { :git => "https://github.com/ruixingchen/RXCDiffArray.git", :tag => spec.version.to_s }
  #spec.source_files  = "Source/*.swift"

  spec.requires_arc = true
  spec.swift_versions = "5.1"
  spec.ios.deployment_target = '9.0'

  spec.default_subspecs = 'Core', 'UIKitExtension'
  
  spec.subspec 'Core' do |subspec|
    subspec.ios.source_files = 'Source/*.swift'
    subspec.ios.frameworks = 'Foundation'
  end

  spec.subspec 'DifferenceKit' do |subspec|
    subspec.dependency 'DifferenceKit', '~> 1.1'
    subspec.dependency 'RXCDiffArray/Core'

    subspec.ios.source_files = 'Source/DifferenceKit/*.swift'
    subspec.ios.frameworks = 'Foundation'
  end

  spec.subspec 'UIKitExtension' do |subspec|
    subspec.dependency 'RXCDiffArray/Core'

    subspec.ios.source_files = 'Source/Extension/UIKit/*.swift'
    subspec.ios.frameworks = 'UIKit'
  end

  spec.subspec 'ASDKExtension' do |subspec|
    subspec.dependency 'Texture', '~> 2.8'
    subspec.dependency 'RXCDiffArray/Core'

    subspec.ios.source_files = 'Source/Extension/ASDK/*.swift'
    subspec.ios.frameworks = 'UIKit'
  end

end
