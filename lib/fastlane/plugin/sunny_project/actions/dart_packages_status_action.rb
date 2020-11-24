require 'fastlane/action'
require 'fastlane_core'
require 'fastlane_core/ui/ui'

require_relative '../helper/sunny_project_helper'
require_relative '../options/plugin_options'
require 'semantic'

module Fastlane
  UI = FastlaneCore::UI unless Fastlane.const_defined?("UI")
  module Actions
    class DartPackagesStatus < Fastlane::Action
      def self.run(options)
        params = FastlaneCore::Configuration.create(SunnyPlugin::Options.available_options, options.__hash__)
        params.load_configuration_file("Sunnyfile")
        "Hello #{params.pretty_print}"
      end

      def self.description
        "Checks status of plugins modules"
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
        SunnyPluginOptions.available_options
      end

      def self.is_supported?(platform)
        true
      end
    end
  end
end
