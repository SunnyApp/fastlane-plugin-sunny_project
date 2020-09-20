require 'fastlane/action'
require_relative '../helper/sunny_project_helper'
require 'semantic'

module Fastlane
  module Actions
    class PubPublishAction < Action
      def self.run(options)
        Sunny.exec_cmd("pub publish", "pub publish -f")
      end

      def self.description
        "Executes pub publish command"
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
