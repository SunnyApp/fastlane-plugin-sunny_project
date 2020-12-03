require 'fastlane/action'
require_relative '../helper/sunny_project_helper'
require 'semantic'


module Fastlane
  module Actions

    class ReleaseNotesAction < Action
      def self.run(options)

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
        [
            FastlaneCore::ConfigItem.new(key: :changes,
                                         env_name: "SUNNY_PROJECT_CHANGES",
                                         description: "Change log text",
                                         optional: true,
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
