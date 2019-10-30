Pod::Spec.new do |spec|
  spec.name         = "RXCDiffArray"
  spec.version      = "1.0"
  spec.summary      = "An array that returns difference when content changed"

  spec.homepage     = "https://github.com/ruixingchen/RXCDiffArray"
  spec.license      = "MIT"
  spec.author             = { "ruixingchen" => "dev@ruixingchen.com" }

  spec.platform     = :ios, "8.0"
  spec.source       = { :git => "https://github.com/ruixingchen/RXCDiffArray.git", :tag => "#{spec.version}" }
  spec.source_files  = "RXCDiffArray/**/*.swift"
  spec.framework  = "Foundation"
  spec.requires_arc = true
  spec.swift_version = '5.1'

end
