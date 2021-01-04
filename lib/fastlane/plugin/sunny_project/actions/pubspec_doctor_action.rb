require 'fastlane/action'

# require 'ci'
require_relative '../helper/sunny_project_helper'
require 'semantic'
require 'yaml'

require_relative '../helper/plugin_options'

def resort_keys(input)
  resort = {}
  keys = []
  input.each_key do |key|
    puts("Key #{key} #{key.class}")
    keys.push("#{key}")
  end

  keys = keys.sort
  puts("Sorted keys: #{keys}")
  keys.each do |k|
    resort[k] = input[k]
  end
  resort
end

module Fastlane
  module Actions
    class PubspecDoctorAction < Action
      def self.run(params)

        unless params
          params = FastlaneCore::Configuration.create(self.available_options, {})
        end
        params.load_configuration_file("Sunnyfile")
        params.load_configuration_file(".Sunnyfile")

        plugins = params[:sunny_plugins]
        plugin_folder = params[:sunny_plugin_folder]
        pubspec = YAML.load_file("pubspec.yaml")
        local_mode = params[:sunny_local_mode]
        is_local = "local".eql?(local_mode)
        puts("Local  #{local_mode} creates #{is_local}")
        dependency_overrides = pubspec["dependency_overrides"]

        plugins.keys.each do |key|

          info = plugins[key] ? plugins[key] : "#{key}"

          folder = key
          branch = nil
          path = nil
          repo = key
          if info.is_a? String
            repo = info
          else
            path = info[:path]
            branch = info[:branch] if info[:branch]
            repo = info[:repo] if info[:repo]
            folder = repo
          end

          if is_local
            dependency_overrides[key.to_s] = {
              'path' => "#{plugin_folder}/#{folder}#{path ? "/#{path}" : ''}"
            }
          else
            settings = {
              'git' => {
                'url' => "git@github.com:SunnyApp/#{repo}.git",
              }
            }
            if branch
              settings['git']['ref'] = branch
            end
            if path
              settings['git']['path'] = "#{path}"
            end
            dependency_overrides[key.to_s] = settings
          end
        end

        pubspec["dependencies"] = resort_keys pubspec["dependencies"]
        pubspec["dev_dependencies"] = resort_keys pubspec["dev_dependencies"]
        pubspec["dependency_overrides"] = resort_keys pubspec["dependency_overrides"]

        pyaml = Psych::Visitors::YAMLTree.create
        pyaml << pubspec
        n = StringIO.new
        emitter = CustomVisitor.new(n)
        emitter.accept(pyaml.tree)
        final_pubspec = n.string.gsub("---", "")
        File.write('pubspec.yaml', final_pubspec)
        print(final_pubspec)
      end

      def self.description
        "Modify pubspec for local or git development"
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

        ]

        Fastlane::SunnyProject::Options.available_options.each do |option|
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

    class CustomVisitor < Psych::Visitors::Emitter
      def initialize(io)
        super(io)
      end

      def visit_Psych_Nodes_Scalar(o)
        if o.value.is_a? String
          str = "#{o.value}"
          if str.start_with?('^') || str.start_with?('..')
            @handler.scalar o.value, o.anchor, o.tag, o.plain, o.quoted, 1
          elsif str.start_with?('https://') || str.start_with?('git@')
            @handler.scalar o.value, o.anchor, o.tag, o.plain, o.quoted, 3
          else
            @handler.scalar o.value, o.anchor, o.tag, o.plain, o.quoted, o.style
          end
          return
        end
        @handler.scalar o.value, o.anchor, o.tag, o.plain, o.quoted, o.style
      end
    end

  end
end

