# frozen_string_literal: true

require 'bundler/gem_tasks'
require 'rake/testtask'
require 'erb'
require 'yaml'

Rake::TestTask.new(:test) do |task|
  task.libs << 'test'
  task.libs << 'lib'
  task.test_files = FileList['test/**/*_test.rb']
end

require 'rubocop/rake_task'

require_relative 'lib/markdown_exec/version'
require_relative 'lib/shared'
require_relative 'lib/tap'

include Tap
tap_config envvar: MarkdownExec::TAP_DEBUG

RuboCop::RakeTask.new do |task|
  task.requires << 'rubocop-minitest'
end

desc 'named task because minitest not included in rubocop tests'
task :rubocopminitest do
  `rubocop --require rubocop-minitest`
end

task default: %i[test reek rubocop rubocopminitest]

# task :default => :build

desc 'gem build'
task :build do
  Rake::Task['update_tab_completion'].execute
  system "gem build #{MarkdownExec::GEM_NAME}.gemspec"
end

desc 'gem install'
task install: :build do
  system "gem install #{MarkdownExec::GEM_NAME}-#{MarkdownExec::VERSION}.gem"
end

desc 'gem publish'
task publish: :build do
  system "gem push #{MarkdownExec::GEM_NAME}-#{MarkdownExec::VERSION}.gem"
end

desc 'gem uninstall'
task uninstall: :build do
  system "gem uninstall #{MarkdownExec::GEM_NAME}"
end

desc 'gem build clean'
task :clean do
  system 'rm *.gem'
end

desc 'reek'
task :reek do
  `reek --config .reek .`
end

private

BF = 'bin'

# format for use in array in bash script
# `opts=<%= mde_tab_completions %>`
#
def words_list(words)
  words.map do |word|
    %("#{word}")
  end.join ' '
end

# write tab_completion.sh with erb
#
def update_tab_completion(target)
  words = `#{File.join BF, MarkdownExec::BIN_NAME} --tab-completions`.split("\n")
  mde_tab_completions = "(#{words_list(words)})"
  mde_help = `#{File.join BF, MarkdownExec::BIN_NAME} --help`.split("\n")
  menu_export_yaml = `#{File.join BF, MarkdownExec::BIN_NAME} --menu-export`

  svhs = YAML.load menu_export_yaml # rubocop:disable Security/YAMLLoad
  svhs.each do |svh|
    svh[:compreply] = value_for_cli(svh[:default]) if svh[:compreply].nil?
  end.tap_inspect name: :svhs, format: :yaml

  File.write target, ERB.new(File.read(File.join(BF, 'tab_completion.sh.erb'))).result(binding)
end

desc 'update tab_completion.sh'
task :update_tab_completion do
  update_tab_completion File.join(BF, 'tab_completion.sh')
end

desc 'update tab_completion.sh'
task :update_installed_tab_completion do
  update_tab_completion(fs = File.join(`mde --pwd`.chomp, BF, 'tab_completion.sh'))

  puts `cat #{fs}` ###
end
