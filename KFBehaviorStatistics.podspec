Pod::Spec.new do |s|

  s.name          = "KFBehaviorStatistics"
  s.version       = "1.0.1"
  s.summary       = "埋点统计的简单实现"
  s.homepage      = "https://github.com/moliya/KFBehaviorStatistics"
  s.license       = "MIT"
  s.author        = {'Carefree' => '946715806@qq.com'}
  s.source        = { :git => "https://github.com/moliya/KFBehaviorStatistics.git", :tag => s.version}
  s.requires_arc  = true
  s.platform      = :ios, '9.0'

  s.source_files  = "Sources/*.{h,m}"
  
end
