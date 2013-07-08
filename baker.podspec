Pod::Spec.new do |s|
  s.name      = 'baker'
  s.version   = '4.1'
  s.summary   = 'Baker for alpina ePubs'
  s.homepage  = 'https://github.com/Simbul/baker'
  s.source    = { :git => 'https://github.com/RedMadRobot/baker', :tag => 'v4.1' }
  s.license   = {
    :type => 'MIT',
    :file => 'LICENSE'
  }
  s.source_files = 'Sources/**/*.{h,m}'
  s.platform = :ios, '5.0'
  s.requires_arc = false
end