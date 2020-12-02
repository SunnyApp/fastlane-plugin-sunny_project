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


    def self.do_increase_version(options)
      command = "pubver bump #{options[:type]} "
      if options[:type] == 'patch'
        command += "-b"
      end
      self.exec_cmd("bump patch", command)
      self.current_semver
    end

    def self.exec_cmd(name, *command, **args)
      if (command.count > 1)
        command = command.map { |item| Shellwords.escape item }
      end
      joined = command.join(" ")
      if args[:verbose]
        begin
          return sh(command)
        rescue StandardError => e
          UI.user_error! ">> #{name} failed << \n  #{e}"
        end
      else
        if args[:cmd_out]
          UI.command_output name
        else
          UI.command name
        end

        stdout, err, status = Open3.capture3(joined)
        UI.user_error! ">> #{name} failed << \n  command: #{joined}\n  error: #{err}" unless status == 0
        stdout
      end
    end

    def self.release_notes_file
      ".release-notes"
    end

    ### Reads the latest version from pubspec.yaml
    def self.current_semver
      Semantic::Version.new current_version_string
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
      self.exec_cmd("get version", "pubver get")
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

