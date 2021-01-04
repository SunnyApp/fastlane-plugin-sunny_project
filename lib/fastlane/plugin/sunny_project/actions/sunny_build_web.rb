require_relative '../helper/sunny_project_helper'
require 'semantic'
require 'yaml'

require_relative '../helper/plugin_options'

module Fastlane
  UI = FastlaneCore::UI unless Fastlane.const_defined?("UI")
  module Actions
    class SunnyBuildWeb < Action
      def self.run(options)
        flutter = Sunny.get_flutter(options)
        profile = if options[:profile]
                    " --profile"
                  else
                    ""
                  end
        Sunny.exec_cmd("flutter build web", "#{flutter} build web#{profile} --web-renderer #{options[:renderer]}")

        if options[:deploy]
          Sunny.exec_cmd("firebase deploy", "firebase deploy")
        end
      end

      def self.description
        "Builds a web project"
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
        [
          FastlaneCore::ConfigItem.new(key: :clean,
                                       env_name: "SUNNY_CLEAN",
                                       description: "Whether to clean",
                                       optional: true, type: Object),

          FastlaneCore::ConfigItem.new(key: :flutter,
                                       env_name: "SUNNY_FLUTTER",
                                       description: "Path to flutter sdk",
                                       optional: true, type: String),
          FastlaneCore::ConfigItem.new(key: :skip_pub,
                                       env_name: "SUNNY_SKIP_PUB",
                                       description: "Whether to skip pub get",
                                       optional: true, type: Object),

          FastlaneCore::ConfigItem.new(key: :skip_gen,
                                       env_name: "SUNNY_SKIP_GEN",
                                       description: "Whether to skip generation",
                                       optional: true, type: Object),

          FastlaneCore::ConfigItem.new(key: :renderer,
                                       env_name: "SUNNY_RENDERER",
                                       description: "The flutter web renderer to build with",
                                       optional: false,
                                       default_value: "auto", type: String),

          FastlaneCore::ConfigItem.new(key: :profile,
                                       env_name: "SUNNY_PROFILE",
                                       description: "Whether to run in profile mode",
                                       optional: true,
                                       type: Object),

          FastlaneCore::ConfigItem.new(key: :deploy,
                                       env_name: "SUNNY_DEPLOY",
                                       description: "Whether to deploy to firebase",
                                       optional: true,
                                       type: Object),

        ]
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

