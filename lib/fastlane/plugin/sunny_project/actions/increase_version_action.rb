require 'fastlane/action'
require_relative '../helper/sunny_project_helper'
require 'semantic'

module Fastlane
  module Actions
    class IncreaseVersionAction < Action
      def self.run(options)
        Sunny.do_increase_version options
      end

      def self.description
        "Increment version number in pubspec.yaml file"
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
        verify_type = lambda do |value|
          UI.error "Invalid option: #{value} Must be 'build' or 'patch'" unless value == "build" or value == "patch"
        end
        [
          FastlaneCore::ConfigItem.new(key: :type,
                                       env_name: "SUNNY_PROJECT_TYPE",
                                       description: "Whether to make a patch or build version change",
                                       optional: true,
                                       verify_block: verify_type,
                                       default_value: 'build',
                                       type: String)
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
