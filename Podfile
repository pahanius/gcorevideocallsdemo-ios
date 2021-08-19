# Uncomment the next line to define a global platform for your project
 platform :ios, '12.1'

target 'GCoreVideoCallsDemo' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  pod 'Starscream', '~> 4.0.4'
  pod 'SwiftyJSON', '~> 4.0'
  pod "mediasoup_ios_client", '1.5.3'
  
  # UI
  pod 'PinLayout'
end

post_install do |installer|
  installer.generated_projects.each do |project|
    project.targets.each do |target|
      target.build_configurations.each do |config|
          config.build_settings["EXCLUDED_ARCHS[sdk=iphonesimulator*]"] = "arm64"
      end
    end
  end
end
