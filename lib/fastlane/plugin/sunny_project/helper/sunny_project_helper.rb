require 'fastlane_core/ui/ui'
require "fastlane"

module Fastlane
  UI = FastlaneCore::UI unless Fastlane.const_defined?("UI")

  module Sunny
    def self.string(str)
      if str
        str.strip
      else
        nil
      end
    end

    def self.blank(str)
      if str
        str.strip.empty?
      else
        true
      end
    end

    def self.is_clean
      self.run_action(Fastlane::Actions::EnsureGitStatusCleanAction)
      true
    rescue
      false
    end

    def self.is_branch(branch_name)
      self.run_action(Fastlane::Actions::EnsureGitBranchAction, branch: branch_name)
      true
    rescue
      false
    end

    def self.config(available_options, options)
      FastlaneCore::Configuration.create(available_options, options)
    end

    def self.run_action(action, **options)
      action.run(self.config(action.available_options, options))
    end

    def self.do_increase_version(options)
      bump_type = options[:type]
      bump_type = "build" unless bump_type
      command = "pubver bump #{bump_type}"
      unless bump_type.eql?('build')
        command += " -b"
      end
      self.exec_cmd(command.to_s, command)

      unless bump_type.eql?('build')
        self.exec_cmd("also bump build", "pubver bump build")
      end

      self.current_semver
    end

    def self.exec_cmd(name, *command, **args)
      if (command.count > 1)
        command = command.map { |item| Shellwords.escape(item) }
      end
      joined = command.join(" ")
      if args[:verbose]
        begin
          return sh(command)
        rescue StandardError => e
          UI.user_error!(">> #{name} failed << \n  #{e}")
        end
      else
        if args[:cmd_out]
          UI.command_output(name)
        elsif args[:quiet]
        else
          UI.command name
        end

        stdout, err, status = Open3.capture3(joined)
        UI.user_error!(">> #{name} failed << \n  command: #{joined}\n  error: #{err}") unless status == 0
        stdout
      end
    end

    def self.release_notes_file
      ".release-notes"
    end

    ### Reads the latest version from pubspec.yaml
    def self.current_semver
      Semantic::Version.new(current_version_string)
    end

    def self.release_notes(options)
      changes = Sunny.string(options[:changelog])
      if Sunny.blank(changes)
        if File.file?(Sunny.release_notes_file)
          changes = Sunny.string(File.read(Sunny.release_notes_file))
          return changes
        end
        unless File.file?(Sunny.release_notes_file)
          changes = Sunny.string(Fastlane::Actions::ChangelogFromGitCommitsAction.run(
            path: "./",
            pretty: "%B",
            ancestry_path: false,
            match_lightweight_tag: true,
            quiet: false,
            merge_commit_filtering: ":exclude_merges"
          ))

          if Sunny.blank(changes)
            changes = Sunny.string(Fastlane::Actions::PromptAction.run(
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
        lines.each { |line| output.write(line) }
        output.close
      end
      changes
    end

    def self.get_flutter(provided = nil)
      provided || ".fvm/flutter_sdk/bin/flutter"
    end

    def self.override_version(**options)
      semver = options[:version]
      unless semver
        UI.user_error!("No version parameter found")
        return
      end
      self.exec_cmd("set_version", "pubver set #{semver}", quiet: true)
      self.sync_version_number(semver)
    end

    def self.sync_version_number(version)
      if version
        self.run_action(Fastlane::Actions::IncrementVersionNumberAction,
                        version_number: "#{version.major}.#{version.minor}.#{version.patch}",
                        xcodeproj: "ios/Runner.xcodeproj"
        )
      else
        Fastlane::Actions::
        UI.user_error!("No version found")
      end

    end

    def self.build_ios(build_ver, build_num, **options)
      flutter = get_flutter(options[:flutter])

      self.exec_cmd("build flutter ios release #{build_ver} #{build_num}", "#{flutter} build ios --release --no-tree-shake-icons --no-codesign")
    end

    ### Reads the latest version from pubspec.yaml
    def self.current_semver_path
      version = nil
      Dir.chdir("..") do
        version = self.current_semver
      end
      version
    end

    def self.build_number
      self.current_semver.build
    end

    ## Retrieves the current semver based on git tags
    def self.current_version_string
      self.exec_cmd("get version", "pubver get", quiet: true)
    end

    # lane :ximg do |options|
    #   Dir.chdir("..") {
    #     cmd("dart asset_renamer.dart", "dart tools/asset_renamer.dart")
    #   }
    # end
    #
    # lane :icons do
    #   download_icons
    #   build_icon_fonts
    # end
    #
    # lane :build_icon_fonts do
    #   Dir.chdir("..") {
    #     cmd("Generate flutter icons", "icon_font_generator", "--from=iconsource/svg", "--class-name=AuthIcons",
    #         "--out-font=lib/fonts/AuthIcons.ttf", "--out-flutter=lib/auth_icon_font.dart", "--normalize")
    #   }
    # end
    #
    # lane :download_icons do
    #   Dir.chdir("..") {
    #     cmd("Download icons", "dart", "tools/iconsource/downloader.dart")
    #   }
    # end

    def self.underscore(str)
      str.gsub(/::/, '/').
        gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2').
        gsub(/([a-z\d])([A-Z])/, '\1_\2').
        tr("-", "_").
        downcase
    end
  end
end

