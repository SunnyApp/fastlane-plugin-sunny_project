require_relative '../helper/sunny_project_helper'
require 'semantic'
require 'yaml'

require_relative '../helper/plugin_options'

def resort_keys(input)
  resort = {}
  keys = []
  input.each_key do |key|
    puts("Key #{key} #{key.class}")
    keys.push(key.to_s)
  end

  keys = keys.sort
  puts("Sorted keys: #{keys}")
  keys.each do |k|
    resort[k] = input[k]
  end
  resort
end

module Fastlane
  UI = FastlaneCore::UI unless Fastlane.const_defined?("UI")
  module Actions
    class SunnyReleaseAction < Action
      def self.run(options)
        unless options[:skip_dirty_check]
          Sunny.run_action(EnsureGitStatusCleanAction)
        end

        sunny_file = Sunny.config(SunnyProject::Options.available_options, {})
        sunny_file.load_configuration_file("Sunnyfile", skip_printing_values = true)

        app_file = CredentialsManager::AppfileConfig
        firebase_app_id = sunny_file[:firebase_app_id]
        unless firebase_app_id
          UI.user_error!("Missing firebase_app_id.  Set this in Sunnyfile")
        end

        old_version = Sunny.current_semver
        old_version_no_build = "#{old_version.major}.#{old_version.minor}.#{old_version.patch}"

        new_version = ''

        ## If we're not going to build, we don't need to update
        # version numbers.

        if (not options[:skip_build]) && (not options[:no_bump])
          if options[:patch]
            new_version = Sunny.do_increase_version(type: "patch")
            Sunny.update_ios_project_version(new_version)
          elsif options[:minor]
            new_version = Sunny.do_increase_version(type: "minor")
            Sunny.update_ios_project_version(new_version)
          elsif options[:build]
            new_version = Sunny.do_increase_version(type: "build")
            Sunny.update_ios_project_version(new_version)
          else
            UI.user_error!("You must provide the type of version change.  options are minor, patch, build.
You can also provide no_bump:true to keep the same build number")
          end

          unless new_version
            UI.user_error!("Version incrementing failed")
            return
          end
        end



        # Whatever happened with the incrementing, this is the build number we're
        # going with
        version = new_version
        version_no_build = "#{version.major}.#{version.minor}.#{version.patch}"
        is_version_changed = old_version_no_build.eql?(version_no_build) != true
        build_number = version.build
        changes = Sunny.release_notes(options)
        app_name = options[:app_name]
        release_target = options[:release_target]

        puts("")
        build_summary = [
          ["App name", (app_file.try_fetch_value(:app_identifier)).to_s],
          ["Target", app_name],
          ["Major version", is_version_changed ? "#{old_version_no_build} -> #{version_no_build}" : "#{version_no_build} (no change)"],
          ["Build number", "#{old_version.build} -> #{build_number}"],
          ["Releasing to", release_target,],
          %W[Changelog #{changes}],
        ]
        UI.important("\n\n#{Terminal::Table.new(rows: FastlaneCore::PrintTable.transform_output(build_summary),
                                                title: 'Build Summary')}")
        puts("")
        # TRY to execute a build.  if it fails, revert the version number changes
        begin
          unless options[:skip_build]
            if options[:skip_flutter_build]
              UI.important("Skipping Flutter Build")
            else
              UI.header("Run Flutter Build")
              Sunny.build_ios(version_no_build, build_number)
            end
            require 'match'
            build_opts = options[:build_options]

            # Load match parameters.  The paths get hosed somehow
            match_opts = Sunny.config(Match::Options.available_options, {
              type: build_opts[0]
            })

            match_opts.load_configuration_file("Matchfile")

            UI.header("Read Appfile info")
            # Read the app identifier from Appfile
            app_identifier = app_file.try_fetch_value(:app_identifier)
            UI.command_output("App: #{app_identifier}")
            unless app_identifier
              UI.user_error!("No app_identifier could be found")
            end

            MatchAction.run(match_opts)
            UI.header("Run Xcode Build")
            Sunny.run_action(BuildAppAction, workspace: "ios/Runner.xcworkspace",
                             scheme: "Runner",
                             export_method: build_opts[1],
                             silent: options[:verbose] != true,
                             suppress_xcode_output: options[:verbose] != true,
                             clean: options[:clean],
                             export_options: {
                               provisioningProfiles: {
                                 app_identifier.to_s => "match #{build_opts[2]} #{app_identifier}",
                               }
                             },
                             output_directory: "build/ios")

          end
        rescue StandardError => e
          # Put the version back like it was
          UI.important("Restoring old version: #{old_version}")
          Sunny.override_version(version: old_version)
          UI.user_error!(">> build ios failed #{e} << \n  #{e.backtrace.join("\n")}")
          return
        end

        # Commits the version number, deletes changelog file
        if (not options[:skip_build]) || options[:post_build]
          unless options[:skip_symbols]
            UI.header("Upload Symbols to Crashlytics")
            Sunny.run_action(UploadSymbolsToCrashlyticsAction, dsym_path: "./build/ios/#{app_name}.app.dSYM.zip",
                             binary_path: "./ios/Pods/FirebaseCrashlytics/upload-symbols")
          end

          UI.header("Commit pubspec.yaml, Info.plist for version updates")
          # If we got this far, let's commit the build number and update the git tags.  If the rest of the pro
          # process fails, we should revert this because it will mess up our commit logs
          Sunny.run_action(GitCommitAction,
                           allow_nothing_to_commit: true,
                           path: %w[./pubspec.yaml ./pubspec.lock ./ios/Podfile.lock ./Gemfile.lock ./ios/Runner/Info.plist],
                           message: "\"Version bump to: #{version_no_build}##{build_number}\"")
          UI.header("Tagging repo v#{version.build}")
          Sunny.run_action(AddGitTagAction,
                           grouping: "sunny-builds",
                           prefix: "v",
                           force: true,
                           build_number: build_number
          )
          Sunny.run_action(PushGitTagsAction, force: false)
        end

        unless options[:no_upload]

          # platform :ios do

          if release_target == "firebase"
            UI.header("Firebase: uploading build/ios/#{app_name}.ipa")

            Sunny.run_action(FirebaseAppDistributionAction,
                             app: firebase_app_id,
                             ipa_path: "build/ios/#{app_name}.ipa",
                             release_notes: changes,
                             debug: true
            )
          elsif release_target == "testflight"
            UI.header("Testflight: uploading build/ios/#{app_name}.ipa")
            Sunny.run_action(UploadToTestflightAction,
                             ipa: "build/ios/#{app_name}.ipa",
                             localized_build_info: {
                               default: {
                                 whats_new: changes
                               }
                             }
            )
          else
            UI.user_error!("No release target specified.  Must be 'testflight' or 'firebase'")
            return
          end
          # end

        end
        UI.command_output("Removing release notes file")
        File.delete(Sunny.release_notes_file) if File.exist?(Sunny.release_notes_file)
      end

      def self.description
        "Perform ios or firebase release"
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
          FastlaneCore::ConfigItem.new(key: :no_bump,
                                       env_name: "SUNNY_NO_BUMP",
                                       description: "Whether to skip a bump",
                                       optional: true, type: Object),
          FastlaneCore::ConfigItem.new(key: :skip_build,
                                       env_name: "SUNNY_SKIP_BUILD",
                                       description: "Whether to skip the building of the project",
                                       optional: true, type: Object),
          FastlaneCore::ConfigItem.new(key: :post_build,
                                       env_name: "SUNNY_POST_BUILD",
                                       description: "Whether to execute actions after building. Can be used in conjunction with skip_build to avoid building the entire project, but still applying tags",
                                       optional: true, type: Object),
          FastlaneCore::ConfigItem.new(key: :skip_dirty_check,
                                       env_name: "SUNNY_SKIP_DIRTY_CHECK",
                                       description: "Whether to skip dirty repo check",
                                       optional: true, type: Object),

          FastlaneCore::ConfigItem.new(key: :clean,
                                       env_name: "SUNNY_CLEAN",
                                       description: "Whether to do a clean build",
                                       optional: true, type: Object),
          FastlaneCore::ConfigItem.new(key: :minor,
                                       env_name: "SUNNY_MINOR",
                                       description: "Whether to make a minor release",
                                       optional: true, type: Object),
          FastlaneCore::ConfigItem.new(key: :patch,
                                       env_name: "SUNNY_PATCH",
                                       description: "Whether to make a patch release",
                                       optional: true, type: Object),
          FastlaneCore::ConfigItem.new(key: :build,
                                       env_name: "SUNNY_BUILD",
                                       description: "Whether to increment only the build number for the release",
                                       optional: true, type: Object),
          FastlaneCore::ConfigItem.new(key: :changelog,
                                       env_name: "SUNNY_CHANGELOG",
                                       description: "Changelog",
                                       optional: true),

          FastlaneCore::ConfigItem.new(key: :no_upload,
                                       env_name: "SUNNY_NO_UPLOAD",
                                       description: "Whether to skip uploading the build",
                                       optional: true, type: Object),

          FastlaneCore::ConfigItem.new(key: :flutter,
                                       env_name: "SUNNY_FLUTTER",
                                       description: "Override path to flutter",
                                       optional: true),

          FastlaneCore::ConfigItem.new(key: :release_target,
                                       env_name: "SUNNY_RELEASE_TARGET",
                                       description: "Where we're releasing to, must be either fastlane or testflight",
                                       optional: false,
                                       type: String),

          FastlaneCore::ConfigItem.new(key: :skip_flutter_build,
                                       env_name: "SKIP FLUTTER BUILD",
                                       description: "Skip the initial flutter build",
                                       optional: true,
                                       type: Object),
          FastlaneCore::ConfigItem.new(key: :verbose,
                                       env_name: "SUNNY_VERBOSE",
                                       description: "Verbose",
                                       optional: true,
                                       type: Object),

          FastlaneCore::ConfigItem.new(key: :app_name,
                                       env_name: "SUNNY_APP_NAME",
                                       description: "The name of the ios release target",
                                       optional: false,
                                       type: String),

          FastlaneCore::ConfigItem.new(key: :skip_symbols,
                                       env_name: "SUNNY_SKIP_SYMBOLS",
                                       description: "Skip uploading symbols to firebase",
                                       optional: true, type: Object),
          FastlaneCore::ConfigItem.new(key: :build_options,
                                       env_name: "SUNNY_BUILD_OPTIONS",
                                       description: "A Hash of build options",
                                       optional: false,
                                       type: Array),

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

    class CustomVisitor < Psych::Visitors::Emitter
      def initialize(io)
        super(io)
      end

      def visit_Psych_Nodes_Scalar(o)
        if o.value.is_a?(String)
          str = (o.value).to_s
          if str.start_with?('^') || str.start_with?('..')
            @handler.scalar(o.value, o.anchor, o.tag, o.plain, o.quoted, 1)
          elsif str.start_with?('https://') || str.start_with?('git@')
            @handler.scalar(o.value, o.anchor, o.tag, o.plain, o.quoted, 3)
          else
            @handler.scalar(o.value, o.anchor, o.tag, o.plain, o.quoted, o.style)
          end
          return
        end
        @handler.scalar(o.value, o.anchor, o.tag, o.plain, o.quoted, o.style)
      end
    end

  end
end

