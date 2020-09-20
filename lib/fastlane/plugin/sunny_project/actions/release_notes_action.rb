require 'fastlane/action'
require_relative '../helper/sunny_project_helper'
require 'semantic'


module Fastlane
  module Actions

    class ReleaseNotesAction < Action
      def self.run(options)
        changes = Sunny.string(options[:changes])
        if Sunny.blank(changes)
          if File.file?(Sunny.release_notes_file)
            changes = Sunny.string(File.read(Sunny.release_notes_file))

            UI.message "Found release notes: \n#####################################################\n\n#{changes}\n\n#####################################################\n"
            sleep(5)
            return changes
          end
          unless File.file?(Sunny.release_notes_file)
            changes =  Sunny.string(Fastlane::Actions::ChangelogFromGitCommitsAction.run(
                path: "./",
                pretty: "%B",
                ancestry_path: false,
                match_lightweight_tag: true,
                quiet: false,
                merge_commit_filtering: ":exclude_merges"
            ))

            if Sunny.blank(changes)
              changes = Sunny.string(prompt(
                  text: "Please Enter a description of what changed.\nWhen you are finished, type END\n Changelog: ",
                  multi_line_end_keyword: 'END'))
            end
          end
          unless Sunny.blank(changes)
            File.open(Sunny.release_notes_file, 'w') { |file|
              file.write(changes)
            }
          end
          if File.file?(Sunny.release_notes_file)
            changes = Sunny.string(File.read(Sunny.release_notes_file))
          end
        end

        if File.file?("CHANGELOG.md")
          f = File.open("CHANGELOG.md", "r+")
          lines = f.readlines
          f.close
          v = Sunny.current_semver
          lines = ["## [#{v}]\n", " * #{changes}\n", "\n"] + lines

          output = File.new("CHANGELOG.md", "w")
          lines.each { |line| output.write line }
          output.close
        end
        changes
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
