require 'fastlane_core/configuration/config_item'
require 'fastlane/helper/lane_helper'

module Fastlane
  module SunnyProject
    class SunnyPluginOptions
      # This is match specific, as users can append storage specific options
      def self.append_option(option)
        self.available_options # to ensure we created the initial `@available_options` array
        @available_options << option
      end

      def self.default_platform
        case Fastlane::Helper::LaneHelper.current_platform.to_s
        when "mac"
          "macos"
        else
          "ios"
        end
      end

      def self.available_options
        [
            FastlaneCore::ConfigItem.new(key: :sunny_plugins,
                                         env_name: "SUNNY_PLUGINS",
                                         description: "The plugins",
                                         type: Hash,
                                         optional: false,)
        ]
      end
    end
  end
end