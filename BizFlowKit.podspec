Pod::Spec.new do |s|
  s.name             = 'BizFlowKit'
  s.version          = '0.1.0'
  s.summary          = 'A starter kit for orchestrating business flows inside your apps.'

  s.description      = <<-DESC
BizFlowKit 提供一个可扩展的业务流程编排框架示例，旨在帮助团队快速封装常用流程，
并通过 CocoaPods 分发给移动端项目使用。你可以在此基础上扩展节点、管道和监控能力。
  DESC

  s.homepage         = 'https://github.com/Immmmmmortal1/BizFlowKit'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Immmmmmortal1' => 'Immmmmmortal1@example.com' }
  s.source           = { :git => 'https://github.com/Immmmmmortal1/BizFlowKit.git', :tag => s.version.to_s }

  s.swift_versions   = ['5.7']
  s.platform     = :ios, '15.0'

  s.source_files = 'Sources/BizFlowKit/**/*.{swift}'

  s.dependency 'UMCommon'
  s.dependency 'UMDevice'
  s.dependency 'UMAPM'
  s.dependency 'UMABTest'
  s.dependency 'UMPush'
  s.dependency 'Adjust', '5.4.1'
  s.dependency 'Adjust/AdjustGoogleOdm'
  s.dependency 'GoogleAdsOnDeviceConversion'

  s.test_spec 'Tests' do |test_spec|
    test_spec.platform = :ios, '15.0'
    test_spec.source_files = 'Tests/BizFlowKitTests/**/*.{swift}'
  end
end
