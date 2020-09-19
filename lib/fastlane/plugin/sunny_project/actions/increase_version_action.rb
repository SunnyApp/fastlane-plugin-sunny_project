require 'fastlane/action'
require_relative '../helper/sunny_project_helper'
require 'semantic'

module Fastlane
  module Actions
    class IncreaseVersionAction < Action
      ### Reads the latest version from pubspec.yaml
      def self.current_semver
        Semantic::Version.new current_version
      end

      ### Reads the latest version from pubspec.yaml (doesn't have to be in .. to run)
      def self.current_semver_path
        version = nil
        Dir.chdir("..") {
          version=current_semver
        }
        version
      end

      def self.build_number
        current_semver.build
      end

      def self.release_notes_file
        ".release-notes"
      end

      def self.run(options)
        UI.message("The increase_version plugin is working!")

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
