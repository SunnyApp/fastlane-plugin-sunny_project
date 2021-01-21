require 'fastlane/action'
require_relative '../helper/sunny_project_helper'
require 'semantic'

module Fastlane
  module Actions
    class PubReleaseAction < Action
      def self.run(options)
        unless options[:skip_dirty_check]
          Sunny.run_action(EnsureGitStatusCleanAction)
        end

        Sunny.do_increase_version(options)
        # Whatever happened with the incrementing, this is the build number we're
        # going with
        changes = Sunny.release_notes(options)
        puts(changes)

        Sunny.exec_cmd("pub publish", "pub publish -f")
        Sunny.finalize_version(options)
      end

      def self.description
        "Releases a dart package"
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
          FastlaneCore::ConfigItem.new(key: :skip_dirty_check,
                                       description: "Whether to skip dirty repo check",
                                       optional: true, type: Object),

        ]
        Fastlane::Actions::FinalizeVersionAction.available_options.each do |option|
          opts.push(option)
        end
        Fastlane::Actions::IncreaseVersionAction.available_options.each do |option|
          opts.push(option)
        end
        Fastlane::Actions::ReleaseNotesAction.available_options.each do |option|
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
