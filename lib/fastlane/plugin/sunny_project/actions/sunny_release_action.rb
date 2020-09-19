require 'fastlane/action'
require_relative '../helper/sunny_project_helper'

module Fastlane
  module Actions
    class SunnyReleaseAction < Action
      def self.run(params)
        UI.message("The sunny_release plugin is working!")
        lane :increase_version do |options|
          version=nil

          Dir.chdir("..") {
            if options[:patch]
              cmd("bump patch", "pubver bump patch -b")
              version=current_semver
            end
            if options[:build]
              cmd("bump build", "pubver bump build")
              version=current_semver
            end
            if version
              puts(version)
            else
              puts("No version changes occurred")
              next
            end
          }

          version
        end

      end

      def self.description
        "Sunny release plugin"
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
          # FastlaneCore::ConfigItem.new(key: :your_option,
          #                         env_name: "SUNNY_PROJECT_YOUR_OPTION",
          #                      description: "A description of your option",
          #                         optional: false,
          #                             type: String)
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
