Pod::Spec.new do |s|
  s.name         = "ContextObserver"
  s.version      = "3.0.1"
  s.summary      = "A small library to manage CoreData notifications in order to update the user interface"
  s.homepage     = "https://github.com/cbot/ContextObserver"
  s.license      = 'MIT'
  s.author       = { "Kai Straßmann" => "derkai@gmail.com" }
  s.source       = { :git => "https://github.com/cbot/ContextObserver.git", :tag => s.version.to_s }

	s.platforms    = { "ios" => "9.0", "osx" => "10.10"}
  s.requires_arc = true
  s.source_files = 'Classes/*.swift'
  s.frameworks = 'Foundation', 'CoreData'
end
