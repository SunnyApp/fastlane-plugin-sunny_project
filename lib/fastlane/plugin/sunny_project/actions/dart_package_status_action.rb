require 'fastlane/action'
# require 'ci'
require_relative '../helper/sunny_project_helper'
require 'semantic'
require_relative '../helper/plugin_options'

# def with_captured_stdout
#   original_stdout = FastlaneCore::UI.ui_object
#   str = ''
#   ci_output = FastlaneCI::FastlaneCIOutput.new(
#       each_line_block: proc do |raw_row|
#         str = str + raw_row
#       end
#   )
#
#   FastlaneCore::UI.ui_object = ci_output
#   yield
#   str
# ensure
#   FastlaneCore::UI.ui_object = original_stdout
# end

module Fastlane
  module Actions
    class DartPackageStatusAction < Action
      def self.run(options)
        params = FastlaneCore::Configuration.create(Fastlane::SunnyProject::Options.available_options, {})
        params.load_configuration_file("Sunnyfile")
        options.all_keys.each do |key|
          params.set(key, options[key])
        end
        plugins = params[:sunny_plugins]
        branches = params[:sunny_plugins]
        Dir.chdir(params[:sunny_plugin_folder]) do
          plugins.keys.each do |key|
            folder = plugins[key]
            folder_str = ''
            unless key.to_s.eql? folder.to_s
              folder_str = " (folder=#{folder})"
            end
            UI.command_output "############### #{key} #{folder_str}"
            if !File.exists? "./#{folder_str}"
              UI.important "  > folder is missing"
            else
              Dir.chdir("./#{folder}") do
                res = ''
                begin
                  Fastlane::Actions::EnsureGitStatusCleanAction.run({})
                rescue StandardError => e
                  UI.important "  >> failed to check git status << #{e.message}"
                  unless res == ''
                    UI.important "  >> #{res}"
                  end
                  if params[:sunny_verbose]
                    UI.user_error! "#{e.backtrace}"
                  end
                end
              end
            end
          end
        end
      end
    end


    def self.convert_options(options)
      o = options.__hash__.dup
      o.delete(:verbose)
      o
    end

    def self.description
      "Get or retrieve release notes from git"
    end

    def self.authors
      ["ericmartineau"]
    end

    def self.return_value
      # If your method provides a return value, you can describe here what it does
    end

    def self.details
      # Optional:
      ""
    end

    def self.available_options
      Fastlane::SunnyProject::Options.available_options
    end

    def self.is_supported?(platform)
      # Adjust this if your plugin only works for a particular platform (iOS vs. Android, for example)
      # See: https://docs.fastlane.tools/advanced/#control-configuration-by-lane-and-by-platform
      #
      # [:ios, :mac, :android].include?(platform)
      true
    end
  end
end

