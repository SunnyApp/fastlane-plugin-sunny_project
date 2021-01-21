require 'fastlane/action'
require_relative '../helper/sunny_project_helper'

module Fastlane
  module Actions
    class FinalizeVersionAction < Action
      def self.run(options)
        Sunny.finalize_version(options)
      end

      def self.description
        "Commit version tags"
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
          FastlaneCore::ConfigItem.new(key: :tag_group,
                                       env_name: "SUNNY_PROJECT_TAG_GROUP",
                                       description: "The name of the tag group",
                                       optional: false,
                                       type: String,
                                       default_value: "sunny/builds"),
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
