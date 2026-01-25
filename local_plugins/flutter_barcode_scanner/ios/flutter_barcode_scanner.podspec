#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#
Pod::Spec.new do |s|
  s.name             = 'flutter_barcode_scanner'
  s.version          = '2.0.0'
  s.summary          = 'A Flutter plugin for scanning 2D barcodes and QR codes.'
  s.description      = <<-DESC
A Flutter plugin for scanning 2D barcodes and QR codes.
                       DESC
  s.homepage         = 'https://github.com/AmolGangadhare/flutter_barcode_scanner'
  s.license          = { :type => 'MIT', :file => '../LICENSE' }
  s.author           = { 'Custom Version' => 'noreply@example.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.public_header_files = 'Classes/**/*.h'
  s.dependency 'Flutter'
  s.platform = :ios, '11.0'
  s.swift_version = '5.0'
end