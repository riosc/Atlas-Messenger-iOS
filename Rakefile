require 'rake'
require 'json'
require 'byebug'

def set(key, value) 
  file = File.open("LayerConfiguration.json", "rb")
  json_string = file.read
  json = JSON.parse(json_string)
  if value == nil
    json.delete(key)
  else
    json[key] = value
  end
  json_string = JSON.pretty_generate(json)
  File.open('LayerConfiguration.json', 'w') { |file| file.write(json_string) }
  puts(json_string)
end

desc "Initialize the project for the first time"
task :init do
  pod_update = "rbenv exec pod update"
  puts green(pod_update)
  system pod_update
 
  puts green("Configure your App ID") 
  puts "To set your app ID please run:"
  puts
  puts "\trake configure:set_app_id[\"{YOUR_APP_ID}\"]"
  puts
  puts "by replacing {YOUR_APP_ID} with your Layer App ID."
  puts
  puts grey("Done Initializing your project")
end

desc "Layer configuration"
namespace :configure do
  desc "Set a LayerConfiguration.json Key"
  task :set, [:key, :value] do |t, args|
    key = args[:key] 
    value = args[:value]
    set(key, value)  
  end  

  desc "Set the Layer app_id"
  task :set_app_id, [:app_id] do |t, args|
    set("app_id", args[:app_id])
  end

  desc "Set the Layer Idenity"
    task :set_identity_provider_url, [:identity_provider_url] do |t, args|
    set("identity_provider_url", args[:identity_provider_url])
  end

  desc "Clear the LayerConfiguration.json"
  task :clear do
    File.open('LayerConfiguration.json', 'w') { |file| file.write("{\n}") }
    puts("Done")
  end
end

def green(string)
 "\033[1;32m* #{string}\033[0m"
end

def yellow(string)
 "\033[1;33m>> #{string}\033[0m"
end

def grey(string)
 "\033[0;37m#{string}\033[0m"
end
