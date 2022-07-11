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

desc 'reek'
task :reek do
  `reek --config .reek .`
end

private

# write menu.yml
#
desc 'update menu.yml'
task :update_menu_yml do
  menu_options = [

    ## priority options
    #
    {
      arg_name: 'NAME',
      compreply: false,
      description: 'Name of block',
      env_var: 'MDE_BLOCK_NAME',
      long_name: 'block-name',
      opt_name: 'block_name',
      short_name: 'b',
      proc1: 'val_as_str'
    },
    {
      arg_name: 'PATH',
      default: '.',
      description: 'Read configuration file',
      long_name: 'config',
      proc1: 'path'
    },
    {
      arg_name: 'BOOL',
      default: false,
      description: 'Debug output',
      env_var: MarkdownExec::TAP_DEBUG,
      long_name: 'debug',
      short_name: 'd',
      proc1: 'debug'
    },
    {
      arg_name: 'RELATIVE_PATH',
      compreply: '.',
      description: 'Name of document',
      env_var: 'MDE_FILENAME',
      long_name: 'filename',
      opt_name: 'filename',
      short_name: 'f',
      proc1: 'val_as_str'
    },
    {
      description: 'App help',
      long_name: 'help',
      short_name: 'h',
      proc1: 'help'
    },
    {
      arg_name: 'RELATIVE_PATH',
      default: '.',
      description: 'Path to documents',
      env_var: 'MDE_PATH',
      long_name: 'path',
      opt_name: 'path',
      short_name: 'p',
      proc1: 'val_as_str'
    },
    {
      arg_name: 'BOOL',
      default: true,
      description: 'Pause for user to approve script',
      env_var: 'MDE_USER_MUST_APPROVE',
      long_name: 'user-must-approve',
      opt_name: 'user_must_approve',
      short_name: 'q',
      proc1: 'val_as_bool'
    },
    {
      description: "Print the gem's version",
      long_name: 'version',
      short_name: 'v',
      proc1: 'version'
    },
    {
      description: 'Exit app',
      long_name: 'exit',
      short_name: 'x',
      proc1: 'exit' # ->(_) { exit }
    },
    {
      description: 'Show current configuration values',
      short_name: '0',
      proc1: 'show_config'
    },

    ## commands
    #
    {
      description: 'List blocks',
      long_name: 'list-blocks',
      opt_name: 'list_blocks',
      proc1: 'val_as_bool'
    },
    {
      description: 'List default configuration as environment variables',
      long_name: 'list-default-env',
      opt_name: 'list_default_env'
    },
    {
      description: 'List default configuration as YAML',
      long_name: 'list-default-yaml',
      opt_name: 'list_default_yaml'
    },
    {
      description: 'List docs in current folder',
      long_name: 'list-docs',
      opt_name: 'list_docs',
      proc1: 'val_as_bool'
    },
    {
      description: 'List recent saved output',
      long_name: 'list-recent-output',
      opt_name: 'list_recent_output',
      proc1: 'val_as_bool'
    },
    {
      description: 'List recent saved scripts',
      long_name: 'list-recent-scripts',
      opt_name: 'list_recent_scripts',
      proc1: 'val_as_bool'
    },
    {
      description: 'Select and execute a recently saved output',
      long_name: 'select-recent-output',
      opt_name: 'select_recent_output',
      proc1: 'val_as_bool'
    },
    {
      description: 'Select and execute a recently saved script',
      long_name: 'select-recent-script',
      opt_name: 'select_recent_script',
      proc1: 'val_as_bool'
    },
    {
      description: 'List tab completions',
      long_name: 'tab-completions',
      opt_name: 'tab_completions',
      proc1: 'val_as_bool'
    },
    {
      description: 'Run most recently saved script',
      long_name: 'run-last-script',
      opt_name: 'run_last_script',
      proc1: 'val_as_bool'
    },
    {
      description: 'Gem home folder',
      long_name: 'pwd',
      opt_name: 'pwd',
      proc1: 'val_as_bool'
    },

    ## secondary options
    #
    {
      arg_name: "INT.#{DISPLAY_LEVEL_BASE}-#{DISPLAY_LEVEL_MAX}",
      default: DISPLAY_LEVEL_DEFAULT,
      description: "Output display level (#{DISPLAY_LEVEL_BASE} to #{DISPLAY_LEVEL_MAX} [data, +context, +info])",
      env_var: 'MDE_DISPLAY_LEVEL',
      long_name: 'display-level',
      opt_name: 'display_level',
      proc1: 'val_as_int'
    },
    {
      arg_name: 'INT.1-',
      default: 32,
      description: 'Max. items to return in list',
      env_var: 'MDE_LIST_COUNT',
      long_name: 'list-count',
      opt_name: 'list_count',
      proc1: 'val_as_int'
    },
    {
      arg_name: 'PREFIX',
      default: MarkdownExec::BIN_NAME,
      description: 'Name prefix for stdout files',
      env_var: 'MDE_LOGGED_STDOUT_FILENAME_PREFIX',
      # long_name: 'logged-stdout-filename-prefix',
      opt_name: 'logged_stdout_filename_prefix',
      proc1: 'val_as_str'
    },
    {
      arg_name: 'BOOL',
      default: false,
      description: 'Display document name in block selection menu',
      env_var: 'MDE_MENU_BLOCKS_WITH_DOCNAME',
      # long_name: 'menu-blocks-with-docname',
      opt_name: 'menu_blocks_with_docname',
      proc1: 'val_as_bool'
    },
    {
      arg_name: 'BOOL',
      default: false,
      description: 'Display headings (levels 1,2,3) in block selection menu',
      env_var: 'MDE_MENU_BLOCKS_WITH_HEADINGS',
      # long_name: 'menu-blocks-with-headings',
      opt_name: 'menu_blocks_with_headings',
      proc1: 'val_as_bool'
    },
    {
      arg_name: 'BOOL',
      default: false,
      description: 'Display summary for execution',
      env_var: 'MDE_OUTPUT_EXECUTION_SUMMARY',
      long_name: 'output-execution-summary',
      opt_name: 'output_execution_summary',
      proc1: 'val_as_bool'
    },
    {
      arg_name: 'BOOL',
      default: false,
      description: 'Display script prior to execution',
      env_var: 'MDE_OUTPUT_SCRIPT',
      long_name: 'output-script',
      opt_name: 'output_script',
      proc1: 'val_as_bool'
    },
    {
      arg_name: 'BOOL',
      default: true,
      description: 'Display standard output from execution',
      env_var: 'MDE_OUTPUT_STDOUT',
      long_name: 'output-stdout',
      opt_name: 'output_stdout',
      proc1: 'val_as_bool'
    },
    {
      arg_name: 'BOOL',
      default: false,
      description: 'Save executed script',
      env_var: 'MDE_SAVE_EXECUTED_SCRIPT',
      long_name: 'save-executed-script',
      opt_name: 'save_executed_script',
      proc1: 'val_as_bool'
    },
    {
      arg_name: 'BOOL',
      default: false,
      description: 'Save standard output of the executed script',
      env_var: 'MDE_SAVE_EXECUTION_OUTPUT',
      long_name: 'save-execution-output',
      opt_name: 'save_execution_output',
      proc1: 'val_as_bool'
    },
    {
      arg_name: 'INT',
      default: 0o755,
      description: 'chmod for saved scripts',
      env_var: 'MDE_SAVED_SCRIPT_CHMOD',
      # long_name: 'saved-script-chmod',
      opt_name: 'saved_script_chmod',
      proc1: 'val_as_int'
    },
    {
      arg_name: 'PREFIX',
      default: MarkdownExec::BIN_NAME,
      description: 'Name prefix for saved scripts',
      env_var: 'MDE_SAVED_SCRIPT_FILENAME_PREFIX',
      # long_name: 'saved-script-filename-prefix',
      opt_name: 'saved_script_filename_prefix',
      proc1: 'val_as_str'
    },
    {
      arg_name: 'RELATIVE_PATH',
      default: 'logs',
      description: 'Saved script folder',
      env_var: 'MDE_SAVED_SCRIPT_FOLDER',
      long_name: 'saved-script-folder',
      opt_name: 'saved_script_folder',
      proc1: 'val_as_str'
    },
    {
      arg_name: 'GLOB',
      default: 'mde_*.sh',
      description: 'Glob matching saved scripts',
      env_var: 'MDE_SAVED_SCRIPT_GLOB',
      # long_name: 'saved-script-glob',
      opt_name: 'saved_script_glob',
      proc1: 'val_as_str'
    },
    {
      arg_name: 'RELATIVE_PATH',
      default: 'logs',
      description: 'Saved stdout folder',
      env_var: 'MDE_SAVED_STDOUT_FOLDER',
      long_name: 'saved-stdout-folder',
      opt_name: 'saved_stdout_folder',
      proc1: 'val_as_str'
    },
    {
      arg_name: 'GLOB',
      default: 'mde_*.out.txt',
      description: 'Glob matching saved outputs',
      env_var: 'MDE_SAVED_STDOUT_GLOB',
      # long_name: 'saved-stdout-glob',
      opt_name: 'saved_stdout_glob',
      proc1: 'val_as_str'
    },

    {
      default: '^[\(\[].*[\)\]]$',
      description: 'Pattern for blocks to hide from user-selection',
      env_var: 'MDE_BLOCK_NAME_EXCLUDED_MATCH',
      opt_name: 'block_name_excluded_match',
      proc1: 'val_as_str'
    },
    {
      default: ':(?<title>\S+)( |$)',
      env_var: 'MDE_BLOCK_NAME_MATCH',
      opt_name: 'block_name_match',
      proc1: 'val_as_str'
    },
    {
      default: '%\([^\)]+\)',
      env_var: 'MDE_BLOCK_CALLS_SCAN',
      opt_name: 'block_calls_scan',
      proc1: 'val_as_str'
    },
    {
      default: '\+\S+',
      env_var: 'MDE_BLOCK_REQUIRED_SCAN',
      opt_name: 'block_required_scan',
      proc1: 'val_as_str'
    },
    {
      default: '<(?<full>(?<type>\$)?(?<name>[A-Za-z]\S*))',
      env_var: 'MDE_BLOCK_STDIN_SCAN',
      opt_name: 'block_stdin_scan',
      proc1: 'val_as_str'
    },
    {
      default: '>(?<full>(?<type>\$)?(?<name>[A-Za-z]\S*))',
      env_var: 'MDE_BLOCK_STDOUT_SCAN',
      opt_name: 'block_stdout_scan',
      proc1: 'val_as_str'
    },
    {
      default: '> ',
      env_var: 'MDE_DISPLAY_LEVEL_XBASE_PREFIX',
      opt_name: 'display_level_xbase_prefix',
      proc1: 'val_as_str'
    },
    {
      default: '^`{3,}',
      env_var: 'MDE_FENCED_START_AND_END_MATCH',
      opt_name: 'fenced_start_and_end_match',
      proc1: 'val_as_str'
    },
    {
      default: '^`{3,}(?<shell>[^`\s]*) *(?<name>.*)$',
      env_var: 'MDE_FENCED_START_EX_MATCH',
      opt_name: 'fenced_start_ex_match',
      proc1: 'val_as_str'
    },
    {
      default: '^# *(?<name>[^#]*?) *$',
      env_var: 'MDE_HEADING1_MATCH',
      opt_name: 'heading1_match',
      proc1: 'val_as_str'
    },
    {
      default: '^## *(?<name>[^#]*?) *$',
      env_var: 'MDE_HEADING2_MATCH',
      opt_name: 'heading2_match',
      proc1: 'val_as_str'
    },
    {
      default: '^### *(?<name>.+?) *$',
      env_var: 'MDE_HEADING3_MATCH',
      opt_name: 'heading3_match',
      proc1: 'val_as_str'
    },
    {
      default: '*.[Mm][Dd]',
      env_var: 'MDE_MD_FILENAME_GLOB',
      opt_name: 'md_filename_glob',
      proc1: 'val_as_str'
    },
    {
      default: '.+\\.md',
      env_var: 'MDE_MD_FILENAME_MATCH',
      opt_name: 'md_filename_match',
      proc1: 'val_as_str'
    },
    {
      default: '^::: +(?<name>.+?)$',
      description: 'Pattern for topics/dividers in block selection menu',
      env_var: 'MDE_MENU_DIVIDER_MATCH',
      opt_name: 'menu_divider_match',
      proc1: 'val_as_str'
    },
    {
      description: 'Options for viewing saved output file',
      env_var: 'MDE_OUTPUT_VIEWER_OPTIONS',
      opt_name: 'output_viewer_options',
      proc1: 'val_as_str'
    },
    {
      default: 24,
      description: 'Maximum # of rows in select list',
      env_var: 'MDE_SELECT_PAGE_HEIGHT',
      opt_name: 'select_page_height',
      proc1: 'val_as_int'
    },
    {
      default: '#!/usr/bin/env',
      description: 'Shebang for saved scripts',
      env_var: 'MDE_SHEBANG',
      opt_name: 'shebang',
      proc1: 'val_as_str'
    },
    {
      default: 'bash',
      description: 'Shell for launched scripts',
      env_var: 'MDE_SHELL',
      opt_name: 'shell',
      proc1: 'val_as_str'
    },
    {
      default: '- - %s - -',
      env_var: 'MDE_MENU_DIVIDER_FORMAT',
      opt_name: 'menu_divider_format',
      proc1: 'val_as_str'
    }
  ]

  File.write(MENU_YML,
             "# #{MarkdownExec::APP_NAME} - #{MarkdownExec::APP_DESC} (#{MarkdownExec::VERSION})\n" +
              menu_options.to_yaml)
  puts `stat #{MENU_YML}`
end

# write tab_completion.sh with erb
#
def update_tab_completion(target)
  words = `#{File.join BF, MarkdownExec::BIN_NAME} --tab-completions`.split("\n")
  mde_tab_completions = "(#{words_list(words)})"
  mde_help = `#{File.join BF, MarkdownExec::BIN_NAME} --help`.split("\n")

  svhs = YAML.load File.open(MENU_YML)
  svhs.each do |svh|
    svh[:compreply] = value_for_cli(svh[:default]) if svh[:compreply].nil?
  end.tap_inspect name: :svhs, format: :yaml

  File.write target, ERB.new(File.read(filespec = File.join(BF, 'tab_completion.sh.erb'))).result(binding)
  puts `stat #{filespec}`
end

desc 'update tab_completion.sh'
task :update_tab_completion do
  update_tab_completion File.join(BF, 'tab_completion.sh')
end

desc 'update installed tab_completion.sh'
task :update_installed_tab_completion do
  update_tab_completion(fs = File.join(`mde --pwd`.chomp, BF, 'tab_completion.sh'))

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
