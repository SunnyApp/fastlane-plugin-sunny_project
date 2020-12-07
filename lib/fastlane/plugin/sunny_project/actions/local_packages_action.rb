require 'fastlane/action'

# require 'ci'
require_relative '../helper/sunny_project_helper'
require 'yaml'

require_relative '../helper/plugin_options'

module Fastlane
  module Actions
    class LocalPackagesAction < Action
      def self.run(options)
        puts("Incoming: #{options.class}")

        unless options
          options = FastlaneCore::Configuration.create(self.available_options, {})
        end
        options.load_configuration_file("Sunnyfile")
        options.load_configuration_file(".Sunnyfile")

        params = options
        params.all_keys.each do |k|
          puts("#{k} => #{params[k]}")
        end

        plugins = params[:sunny_plugins]
        plugin_folder = params[:sunny_plugin_folder]
        # pubspec = YAML.load_file("pubspec.yaml")
        local_mode = params[:sunny_local_mode]
        is_local = "local".eql?(local_mode)
        UI.command_output("Local  #{local_mode} creates #{is_local}")

        unless is_local
          UI.user_error!("Not set to local development.  Not checking out")
          return
        end

        roots = []
        Dir.chdir(plugin_folder) do
          plugins.keys.each do |key|
            info = plugins[key] ? plugins[key] : "#{key}"
            folder = key
            root_folder = nil
            branch = nil
            path = nil
            repo = key
            if info.is_a?(String)
              repo = info
              root_folder = key
            else
              path = info[:path]
              branch = info[:branch] if info[:branch]
              repo = info[:repo] if info[:repo]
              folder = repo
              root_folder = if path
                              repo
                            else
                              key
                            end
            end
            UI.header("#{folder}")
            if roots.include?(root_folder)
              UI.message "Skipping root #{root_folder} - already processed"
            else
              git_repo = "git@github.com:SunnyApp/#{repo}.git"

              plugin_exists = Dir.exist?("./#{root_folder}")
              if !plugin_exists || options[:force]
                UI.important("Checking out plugin #{repo} to #{root_folder}")
                Sunny.exec_cmd("clone #{key}", "git clone #{git_repo} #{root_folder}", quiet: true)
              else
                UI.message("Plugin already cloned: #{root_folder}")
              end

              roots.push(root_folder)

              Dir.chdir("./#{folder}") do
                if branch
                  UI.important("Verifying branch #{branch}")
                  unless Sunny.is_branch(branch)
                    if Sunny.is_clean
                      Sunny.exec_cmd("checkout branch #{branch}", "git checkout #{branch}")
                    else
                      UI.user_error!("Needs to be on branch #{branch}, but repo is not clean.  You will need to manually fix this")
                    end
                  end
                end

                if params[:update]
                  begin
                    Sunny.run_action(GitPullAction, rebase: true)
                  rescue StandardError => e
                    UI.error("----------    Failed to update   ---------------")
                    UI.error("There are changes to the working tree.  Check ")
                    UI.error("the status of each repo below and make any fixes.")
                    UI.error("------------------------------------------------")

                    UI.command_output(cmd("myrepos status", "git status --porcelain", args = options))
                  end
                end
              end
            end
          end
        end

      end

      def self.description
        "Checks out local dart packages"
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
        opts = [
          FastlaneCore::ConfigItem.new(key: :update,
                                       env_name: "SUNNY_UPDATE",
                                       description: "Whether to update each plugin",
                                       type: Object,
                                       optional: true),
          FastlaneCore::ConfigItem.new(key: :force,
                                       env_name: "SUNNY_FORCE",
                                       description: "Whether to update each plugin",
                                       type: Object,
                                       optional: true),
        ]

        Fastlane::SunnyProject::Options.available_options.each do |option|
          opts.push(option)
        end
        opts
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
end

