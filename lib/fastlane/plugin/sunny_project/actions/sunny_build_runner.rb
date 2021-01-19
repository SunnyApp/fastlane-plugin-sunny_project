require_relative '../helper/sunny_project_helper'
require 'semantic'
require 'yaml'

require_relative '../helper/plugin_options'

module Fastlane
  UI = FastlaneCore::UI unless Fastlane.const_defined?("UI")
  module Actions
    class SunnyBuildRunnerAction < Action
      def self.run(options)
        Sunny.build_runner(options)
      end

      def self.description
        "Cleans and runs flutter build_runner"
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

          FastlaneCore::ConfigItem.new(key: :verbose,
                                       env_name: "SUNNY_VERBOSE",
                                       description: "Verbose or not",
                                       optional: true, type: Object),

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

