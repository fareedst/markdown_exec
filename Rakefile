# frozen_string_literal: true

require 'bundler/gem_tasks'
require 'rake/testtask'
require 'erb'
require 'pry'
# require 'rspec'
require 'rubocop'
require 'yaml'

# begin
#   require 'rspec/core/rake_task'
#   RSpec::Core::RakeTask.new(:spec)
# rescue LoadError
#   puts 'RSpec is required to run some tests.'
# end

Rake::TestTask.new(:test) do |task|
  task.libs << 'test'
  task.libs << 'lib'
  task.test_files = FileList['test/**/*_test.rb']
end

require 'rubocop/rake_task'

require_relative 'lib/cli'
require_relative 'lib/markdown_exec/version'
require_relative 'lib/shared'
require_relative 'lib/tap'

include CLI

include Tap

RuboCop::RakeTask.new do |task|
  task.requires << 'rubocop-minitest'
  task.requires << 'rubocop-rspec'
end

desc 'named task because minitest not included in rubocop tests'
task :rubocopminitest do
  `rubocop --require rubocop-minitest`
end

task default: %i[test reek rubocop rubocopminitest]
# task default: %i[rspec test reek rubocop rubocopminitest]

# task :default => :build

desc 'gem build'
task :build do
  Rake::Task['update_menu_yml'].execute
  Rake::Task['update_tab_completion'].execute # after updated menu is readable
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

desc 'bats'
task :bats do
  FileList['bats/**/*.bats'].each do |file|
    next if %w[bats/bats.bats bats/fail.bats].include?(file)

    system "bats #{file}"
  end
end

desc 'minitest'
task :minitest do
  commands = [
    './lib/argument_processor.rb',
    './lib/block_label.rb',
    './lib/cached_nested_file_reader.rb',
    './lib/dev/process_template.rb --test',
    './lib/directory_searcher.rb',
    './lib/fcb.rb',
    './lib/filter.rb',
    './lib/find_files.rb',
    './lib/format_table.rb',
    './lib/hash_delegator.rb',
    './lib/hierarchy_string.rb',
    './lib/link_history.rb',
    './lib/markdown_exec.rb',
    './lib/mdoc.rb',
    './lib/object_present.rb',
    './lib/option_value.rb',
    './lib/regexp.rb',
    './lib/resize_terminal.rb',
    './lib/saved_assets.rb',
    './lib/saved_files_matcher.rb',
    './lib/table_extractor.rb',
    './lib/text_analyzer.rb'
  ]

  commands.each do |command|
    result = system("bundle exec ruby #{command}")
    error_level = $?.exitstatus

    if error_level != 0
      puts "Error: Command '#{command}' failed with exit status #{error_level}."
      exit error_level
    end
  end
end
task mini: %i[minitest]

desc 'reek'
task :reek do
  `reek --config .reek .`
end

desc 'test'
task :test do
  system 'bundle exec rspec'
  Rake::Task['minitest'].invoke
  Rake::Task['bats'].invoke
end

private

# write menu.yml
#
desc 'update menu.yml'
task :update_menu_yml do
  menu_options = YAML.load_file('lib/menu.src.yml')
  menu_options.push(
    {
      arg_name: "INT.#{DISPLAY_LEVEL_BASE}-#{DISPLAY_LEVEL_MAX}",
      default: DISPLAY_LEVEL_DEFAULT,
      description: 'Output display level ' \
                   "(#{DISPLAY_LEVEL_BASE} to #{DISPLAY_LEVEL_MAX} " \
                   '[data, +context, +info])',
      env_var: 'MDE_DISPLAY_LEVEL',
      long_name: 'display-level',
      opt_name: 'display_level',
      procname: 'val_as_int'
    }
  )

  File.write(MENU_YML, menu_options.to_yaml)
  puts `stat #{MENU_YML}`
end
task :menu => 'update_menu_yml'

# write tab_completion.sh with erb
#
def update_tab_completion(target)
  words = `#{File.join BF,
                       MarkdownExec::BIN_NAME} --tab-completions`.split("\n")
  mde_tab_completions = "(#{words_list(words)})"
  mde_help = `#{File.join BF, MarkdownExec::BIN_NAME} --help`.split("\n")

  svhs = YAML.load File.open(MENU_YML)
  svhs.each do |svh|
    svh[:compreply] = CLI.value_for_cli(svh[:default]) if svh[:compreply].nil?
  end

  File.write target,
             ERB.new(File.read(filespec = File.join(BF,
                                                    'tab_completion.sh.erb')))
                .result(binding)
  puts `stat #{filespec}`
end

desc 'update tab_completion.sh'
task :update_tab_completion do
  update_tab_completion File.join(BF, 'tab_completion.sh')
end

desc 'update installed tab_completion.sh'
task :update_installed_tab_completion do
  update_tab_completion(fs = File.join(`mde --pwd`.chomp, BF,
                                       'tab_completion.sh'))

  puts `cat #{fs}` ###
end

# format for use in array in bash script
# `opts=<%= mde_tab_completions %>`
#
def words_list(words)
  words.map do |word|
    %("#{word}")
  end.join ' '
end
