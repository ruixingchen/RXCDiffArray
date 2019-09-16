Pod::Spec.new do |spec|

  spec.name         = "RXCDiffArray"
  spec.version      = "1.0"
  spec.summary      = "an array that can notify its changes"
  spec.description  = "an array that can notify its changes to multi delegates"
  spec.homepage     = "https://github.com/ruixingchen/RXCDiffArray"
  spec.license      = "MIT"

  spec.author       = { "ruixingchen" => "rxc@ruixingchen.com" }
  spec.platform     = :ios, "8.0"

  spec.source       = { :git => "https://github.com/ruixingchen/RXCDiffArray.git", :tag => spec.version.to_s }
  spec.source_files  = "Source", "Source/**/*.{swift}"
  spec.framework = "Foundation"

  spec.requires_arc = true
  spec.swift_versions = "5.0"

end