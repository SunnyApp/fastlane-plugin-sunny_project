source('https://rubygems.org')

gemspec
require 'semantic'
require 'semantic/core_ext'
require 'fastlane'
require 'fileutils'
require 'open3'

plugins_path = File.join(File.dirname(__FILE__), 'fastlane', 'Pluginfile')
eval_gemfile(plugins_path) if File.exist?(plugins_path)
