require 'fastlane/action'
require_relative '../helper/sunny_project_helper'

module Fastlane
  module Actions
    class FinalizeVersionAction < Action
      def self.run(options)
        version = Sunny.current_semver
        # If we got this far, let's commit the build number and update the git tags.  If the rest of the pro
        # process fails, we should revert this because it will mess up our commit logs
        Fastlane::Actions::GitCommitAction.run(path: %w[./pubspec.yaml ./pubspec.lock ./CHANGELOG.md],
                                               allow_nothing_to_commit: true,
                   message: "Version bump to: #{version.major}.#{version.minor}.#{version.patch}#800#{version.build}")
        Fastlane::Actions::AddGitTagAction.run(
            tag: "sunny/builds/v#{version.build}",
            force: true,
            sign: false,
        )
        Fastlane::Actions::PushGitTagsAction.run(log:true)
        if File.exist?(Sunny.release_notes_file)
          File.delete(Sunny.release_notes_file)
        end
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
