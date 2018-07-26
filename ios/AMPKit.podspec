#
# Be sure to run `pod lib lint AMPKit.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'AMPKit'
  s.version          = '0.1.1'
  s.authors          = "The AMP HTML authors."
  s.summary          = 'A library for displaying AMP results in a native viewer'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
An AMP viewer for iOS that supports prefetching articles and loading multiple AMP articles at the same time.
                       DESC

  s.homepage         = 'https://github.com/ampproject/amp-viewer/tree/master/ios'
  s.license          = { :type => 'Apache 2.0' }
  s.source           = { :git => 'https://github.com/ampproject/amp-viewer.git', :tag => "v#{s.version}-ios" }

  s.ios.deployment_target = '9.0'
  s.requires_arc = true

  s.source_files = 'AMPKit/**/*.m', 'AMPKit/**/*.h'

  s.resource_bundles = {
     'AMPKit' => ['AMPKit/Icons.xcassets', 'AMPKit/AMPKHeaderView.xib', 'AMPKit/Resources/amp_integration.js', 'AMPKit/vendor/ampkit-url-creator.js']
  }

  s.public_header_files = 'AMPKit/**/*.h'
  s.frameworks = 'UIKit', 'SafariServices', 'WebKit'
  s.dependency 'MaterialComponents/ActivityIndicator', '~> 29.0'
  s.dependency 'MaterialComponents/Buttons', '~> 29.0'
  s.dependency 'GoogleToolboxForMac/Defines', '~> 2.1'
end
