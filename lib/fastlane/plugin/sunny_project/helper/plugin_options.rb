require 'fastlane_core/configuration/config_item'
require 'fastlane/helper/lane_helper'

module Fastlane
  module SunnyProject
    class Options
      # This is match specific, as users can append storage specific options
      def self.append_option(option)
        self.available_options # to ensure we created the initial `@available_options` array
        self.available_options.merge(option)
      end

      def self.available_options
        [
            FastlaneCore::ConfigItem.new(key: :sunny_plugins,
                                         env_name: "SUNNY_PLUGINS",
                                         description: "The plugins",
                                         type: Hash,
                                         optional: true,),
            FastlaneCore::ConfigItem.new(key: :sunny_plugin_folder,
                                         env_name: "SUNNY_PLUGIN_FOLDER",
                                         description: "Folder that contains the packages",
                                         type: String,
                                         optional: false,
                                         default_value: '../plugin'),
            FastlaneCore::ConfigItem.new(key: :sunny_plugins_branches,
                                         env_name: "SUNNY_PLUGINS_BRANCHES",
                                         description: "Specific branches to use",
                                         type: Hash,
                                         optional: true,),
            FastlaneCore::ConfigItem.new(key: :sunny_local_mode,
                                         env_name: "SUNNY_LOCAL_MODE",
                                         description: "Whether the project uses local checked out packages",
                                         type: String,
                                         optional: true,
                                         default_value: "git"),

        ]
      end
    end
  end
end