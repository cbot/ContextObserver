Pod::Spec.new do |s|
  s.name         = "KSCoreDataObserver"
  s.version      = "1.0.0"
  s.summary      = "A small library to manage CoreData notifications in order to update the user interface"
  s.homepage     = "https://github.com/cbot/KSCoreDataObserver"
  s.license      = 'MIT'
  s.author       = { "Kai Straßmann" => "derkai@gmail.com" }
  s.source       = { :git => "https://github.com/cbot/KSCoreDataObserver.git", :tag => s.version.to_s }

  s.platform     = :ios, '7.0'
  s.ios.deployment_target = '7.0'
  s.requires_arc = true
  s.public_header_files = 'Classes/ios/*.h'
  s.source_files = 'Classes/ios/*'
  s.frameworks = 'Foundation', 'CoreData'
end
