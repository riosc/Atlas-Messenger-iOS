require 'rake'
require 'json'
require 'byebug'

namespace :init do

  desc "Initialize the project for development including Layer and/or LayerUI as development pods from their submodules. Examples:" +
  "\n\n\tuse the Atlas submodule as a development pod:" +
  "\n\n\t\trake init:submodules ui=1" +
  "\n\n\tuse both Layer and LayerUI submodules as development pods, by providing a location for LayerKit:" +
  "\n\n\t\trake init:submodules ui=1 core=/path/to/.../LayerKit"
  task :submodules do
    layer_core_location = ENV['core']
    core_submodule_flag = ''

    layer_ui_submodule = ENV['ui'] == '1'
    ui_submodule_flag = ''

    if File.directory?(layer_core_location) then
      puts green("Using LayerKit repository at #{layer_core_location} as a development pod.")
      core_submodule_flag = "LAYER_USE_CORE_SDK_LOCATION=#{layer_core_location} "
    else
      puts green('Using public LayerKit CocoaPod release.')
    end

    if layer_ui_submodule then
      puts green('Using Atlas submodule as a development pod.')
      system 'git submodule update --init Libraries/Atlas'
      ui_submodule_flag = 'LAYER_USE_UI_SDK_SUBMODULE=1 '
    else
      puts green('Using public Atlas CocoaPod release.')
    end

    pod_update = "#{core_submodule_flag}#{ui_submodule_flag}rbenv exec pod update"
    puts green(pod_update)
    system pod_update

    show_config_instructions
  end
  
end

desc "Initialize the project for the first time"
task :init do
  pod_update = "rbenv exec pod update"
  puts green(pod_update)
  system pod_update
end

desc "Create an archived build for deploying via e.g. Hockeyapp. To export the .ipa, provide a path to a .plist with the desired options as plist=/path/to/.../plist (shared via Google Drive). The path must be absolute, not relative or canonical. Requires that a signing key (shared via 1Password) exists on the local machine, findable by codesign."
task :archive do
  date = Time.now.to_s.gsub(':','_')
  archive_name = "Atlas Messenger archive #{date}"
  archive_cmd = "xcodebuild -workspace \"Atlas Messenger.xcworkspace\" -scheme \"Atlas Messenger\" -configuration Release -archivePath \"#{archive_name}.xcarchive\" archive | xcpretty"
  puts green(archive_cmd)
  system archive_cmd
  
  plist_path = ENV['plist']
  export_cmd = "xcodebuild -exportArchive -archivePath \"#{archive_name}.xcarchive\" -exportOptionsPlist \"#{plist_path}\" -exportPath \"#{archive_name}\""
  puts green(export_cmd)
  system export_cmd
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
