
require 'fastlane/action'
require_relative '../helper/sunny_project_helper'
require 'semantic'

module Fastlane
  module Actions
    class GenerateIconsAction < Action
      def self.run(options)
        Dir.chdir("..") {
          self.download_icons
          self.build_icon_fonts(options)
        }
      end

      def self.build_icon_fonts(options)
        snake_name = options[:icon_set_name]
        camel_value = snake_name.split('_').downcase.collect(&:capitalize).join
        helper.exec_cmd("Generate flutter icons", "icon_font_generator",
                        "--from=#{options[:icon_source_folder]}", "--class-name=#{camel_value}",
                        "--out-font=lib/fonts/#{camel_value}.ttf", "--out-flutter=lib/#{snake_name}_font.dart",
                        "--normalize")

      end

      def self.download_icons
        Dir.chdir("..") {
          cmd("Download icons", "dart", "tools/iconsource/downloader.dart")
        }
      end

      def self.description
        "Generates a flutter icon set as a font"
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
            FastlaneCore::ConfigItem.new(key: :icon_source_folder,
                                         env_name: "SUNNY_PROJECT_ICON_SOURCE_FOLDER",
                                         description: "The folder to look in for svg icons",
                                         optional: false,
                                         type: String,
                                         default_value: "iconsource/svg"),
            FastlaneCore::ConfigItem.new(key: :icon_set_name,
                                         env_name: "SUNNY_PROJECT_ICON_SET_NAME",
                                         description: "The snake-case name of the icon set",
                                         optional: false,
                                         verify_block: proc do |value|
                                           UI.error!("This value cannot be blank") unless value
                                           UI.error!("This value must be snake case") unless Sunny.underscore(value) == value
                                         end,
                                         type: String),
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
