Pod::Spec.new do |s|
  s.name             = 'MetadataCaptureController'
  s.version          = '0.1.0'
  s.summary          = 'A simple controller to capture metadata.'
  s.description      = "An overlap API to wrap the capture of an AVMetadataObject's from an UIViewController"

  s.homepage         = 'https://github.com/CopyIsRight/MetadataCaptureController'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { "Pietro Caselani" => "pc1992@gmail.com", "Felipe Lobo" => "frlwolf@gmail.com" }
  s.source           = { :git => 'https://github.com/CopyIsRight/MetadataCaptureController.git', :tag => s.version.to_s }
  s.ios.deployment_target = '7.0'

  s.source_files = 'MetadataCaptureController/Classes/**/*'
  
  # s.resource_bundles = {
  #  'MetadataCaptureController' => ['MetadataCaptureController/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  #s.dependency 'MTBBarcodeScanner', '~> 2.0'
end
