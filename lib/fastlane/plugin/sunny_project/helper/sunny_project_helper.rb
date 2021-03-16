require 'fastlane_core/ui/ui'
require 'fastlane/helper/sh_helper'
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

    def self.mmp(semver)
      "#{semver.major}.#{semver.minor}.#{semver.patch}"
    end

    def self.do_increase_version(options)
      curr = self.current_semver

      if curr.pre
        me = curr.pre
        pos = me.rindex(".")
        pre_id = me[0...pos]
        pre_num = me[pos + 1..-1]
        curr.pre = "#{pre_id}.#{Integer(pre_num) + 1}"
        self.exec_cmd("pubver set #{curr}", "pubver set #{curr}")
      else
        bump_type = options[:type]
        bump_type = "build" unless bump_type
        if bump_type.eql?('build')
        elsif bump_type.eql?('patch')
        elsif bump_type.eql?('minor')
        elsif bump_type.eql?('major')
        end

        command = "pubver bump #{bump_type}"
        unless bump_type.eql?('build')
          command += " -b"
        end
        self.exec_cmd(command.to_s, command)

        unless bump_type.eql?('build')
          self.exec_cmd("also bump build", "pubver bump build")
        end
      end
      self.current_semver
    end

    def self.update_ios_project_version(new_version)
      Dir.chdir("ios") {
        puts("Updating XCode Project files: version:#{mmp(new_version)}, build: #{new_version.build}")
        self.run_action(Fastlane::Actions::IncrementVersionNumberAction, version_number: mmp(new_version))
        self.run_action(Fastlane::Actions::IncrementBuildNumberAction, build_number: new_version.build)
      }
    end

    def self.config_to_hash(options)
      hash = Hash([])
      options.all_keys.each do |key|
        hash.store(key, options.fetch(key, ask: false))
      end
      return hash
    end

    def self.exec_cmd(name, *command, **args)
      if command.count > 1
        command = command.map { |item| Shellwords.escape(item) }
      end
      joined = command.join(" ")
      if args[:verbose]
        begin
          return Fastlane::Actions.sh(*command, log: true, error_callback: ->(str) { UI.user_error!(">> #{name} failed << \n #{str}") })
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

    def self.exec_cmd_options(name, command, options)
      return exec_cmd(name, command, **config_to_hash(options))
    end

    def self.release_notes_file
      ".release-notes"
    end

    ### Reads the latest version from pubspec.yaml
    def self.current_semver
      Semantic::Version.new(current_version_string)
    end

    def self.finalize_version(options)
      version = self.current_semver
      # If we got this far, let's commit the build number and update the git tags.  If the rest of the pro
      # process fails, we should revert this because it will mess up our commit logs
      self.run_action(Fastlane::Actions::GitAddAction, path: %w[./pubspec.yaml ./pubspec.lock ./CHANGELOG.md])
      self.run_action(Fastlane::Actions::GitCommitAction, path: %w[./pubspec.yaml ./pubspec.lock ./CHANGELOG.md],
                      allow_nothing_to_commit: false,

                      message: "Version bump to: #{version.major}.#{version.minor}.#{version.patch}#800#{version.build}")
      self.run_action(Fastlane::Actions::AddGitTagAction,
                      tag: "sunny/builds/v#{version.build}",
                      force: true,
                      sign: false,
      )
      self.run_action(Fastlane::Actions::PushGitTagsAction, force: true)
      if File.exist?(self.release_notes_file)
        File.delete(self.release_notes_file)
      end
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

    def self.build_runner(options)
      flutter = get_flutter(options[:flutter])
      opt_hash = config_to_hash(options)
      if options[:clean]
        exec_cmd("flutter clean", "#{flutter} clean", **opt_hash)
      end

      if options[:clean] || (!options[:skip_pub])
        exec_cmd("flutter pub get", "#{flutter} pub get", **opt_hash)
      end

      if options[:clean] || (!options[:skip_gen])
        dc = if options[:clean]
               " --delete-conflicting-outputs"
             else
               ""
             end
        vb = if options[:verbose]
               " -v"
             else
               ""
             end
        exec_cmd("flutter pub run build_runner build#{dc}#{vb}", "#{flutter} pub run build_runner build#{dc}#{vb}", **opt_hash)
      end
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

