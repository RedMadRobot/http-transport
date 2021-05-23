Pod::Spec.new do |s|
  s.name         = "incetro-http-transport"
  s.module_name  = "HTTPTransport"
  s.version      = "5.1.1"
  s.summary      = "HTTP transport library"
  s.description  = "Based on Alamofire. Implements synchronous transport"
  s.homepage     = "https://github.com/Incetro/http-transport"
  s.license      = { :type => "MIT", :file => "LICENSE" }
  s.author       = { "Jeorge Taflanidi" => "et@redmadrobot.com" }
  s.platform     = :ios, "10.0"
  s.source       = { :git => "https://github.com/Incetro/http-transport.git", :tag => s.version, :branch => "master" }
  s.source_files = "Source/HTTPTransport/HTTPTransport/Classes/**/*"
  s.requires_arc = true
  s.dependency "Alamofire", '~> 5'
end
