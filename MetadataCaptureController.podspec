Pod::Spec.new do |s|
  s.name             = 'MetadataCaptureController'
  s.version          = '0.1.0'
  s.summary          = 'A short description of MetadataCaptureController.'

  s.description      = <<-DESC
TODO: Add long description of the pod here.
                       DESC

  s.homepage         = 'https://github.com/CopyIsRight/MetadataCaptureController'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { "Pietro Caselani" => "pc1992@gmail.com", "Felipe Lobo" => "frlwolf@gmail.com" }
  s.source           = { :git => 'git@github.com:CopyIsRight/MetadataCaptureController.git', :tag => s.version.to_s }
  s.ios.deployment_target = '7.0'
  
  s.requires_arc     = true
  s.source_files     = 'MetadataCaptureController/Classes/**/*'
  s.frameworks       = 'AVFoundation'

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'
end
