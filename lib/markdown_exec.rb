#!/usr/bin/env ruby
# frozen_string_literal: true

# encoding=utf-8

require 'English'
require 'clipboard'
require 'fileutils'
require 'open3'
require 'optparse'
require 'shellwords'
require 'tmpdir'
require 'tty-prompt'
require 'yaml'

require_relative 'ansi_formatter'
require_relative 'block_label'
require_relative 'cached_nested_file_reader'
require_relative 'cli'
require_relative 'colorize'
require_relative 'directory_searcher'
require_relative 'env'
require_relative 'exceptions'
require_relative 'fcb'
require_relative 'filter'
require_relative 'fout'
require_relative 'hash_delegator'
require_relative 'input_sequencer'
require_relative 'markdown_exec/version'
require_relative 'mdoc'
require_relative 'option_value'
require_relative 'saved_assets'
require_relative 'saved_files_matcher'
require_relative 'shared'
require_relative 'tap'

include CLI
include Tap

tap_config envvar: MarkdownExec::TAP_DEBUG

$stderr.sync = true
$stdout.sync = true

ARGV_SEP = '--'

# custom error: file specified is missing
#
class FileMissingError < StandardError; end

def dp(str)
  lout " => #{str}", level: DISPLAY_LEVEL_DEBUG
end

def rbi
  pp(caller.take(4).map.with_index { |line, ind| "   - #{ind}: #{line}" })
  binding.irb
end

def rbp
  rpry
  pp(caller.take(4).map.with_index { |line, ind| "   - #{ind}: #{line}" })
  binding.pry
end

def bpp(*args)
  pp '+ bpp()'
  pp(*args.map.with_index { |line, ind| "  - #{ind}: #{line}" })
  rbi
end

def rpry
  require 'pry-nav'
  require 'pry-stack_explorer'
end

public

# convert regex match groups to a hash with symbol keys
#
# :reek:UtilityFunction
def extract_named_captures_from_option(str, option)
  str.match(Regexp.new(option))&.named_captures&.sym_keys
end

# :reek:UtilityFunction
def list_recent_output(saved_stdout_folder, saved_stdout_glob,
                       list_count)
  SavedFilesMatcher.most_recent_list(saved_stdout_folder,
                                     saved_stdout_glob, list_count)
end

# :reek:UtilityFunction
def list_recent_scripts(saved_script_folder, saved_script_glob,
                        list_count)
  SavedFilesMatcher.most_recent_list(saved_script_folder,
                                     saved_script_glob, list_count)
end

# execute markdown documents
#
module MarkdownExec
  include Exceptions

  ##
  #
  # :reek:DuplicateMethodCall { allow_calls: ['block', 'item', 'lm', 'opts', 'option', '@options', 'required_blocks'] }
  # rubocop:enable Layout/LineLength
  # :reek:MissingSafeMethod { exclude: [ read_configuration_file! ] }
  # :reek:TooManyInstanceVariables ### temp
  # :reek:TooManyMethods ### temp
  class MarkParse
    attr_reader :options, :prompt, :run_state

    include ArrayUtil
    include StringUtil

    def initialize(options = {})
      @option_parser = nil

      @options = HashDelegator.new(options)
      @fout = FOut.new(@delegate_object)
    end

    private

    def error_handler(name = '', opts = {})
      Exceptions.error_handler(
        "CachedNestedFileReader.#{name} -- #{$!}",
        opts
      )
    end

    def warn_format(name, message, opts = {})
      Exceptions.warn_format(
        "CachedNestedFileReader.#{name} -- #{message}",
        opts
      )
    end

    # return arguments before ARGV_SEP
    # arguments after ARGV_SEP are passed to the generatede script
    #
    def arguments_for_mde(argv = ARGV)
      case ind = argv.find_index(ARGV_SEP)
      when nil
        argv
      when 0
        []
      else
        argv[0..ind - 1]
      end
    end

    ##
    # options necessary to start, parse input, defaults for cli options
    #
    def base_options
      menu_iter do |item|
        next unless item[:opt_name].present?

        item_default = item[:default]
        value = if item_default.nil?
                  item_default
                else
                  env_str(item[:env_var],
                          default: OptionValue.for_hash(item_default))
                end
        [item[:opt_name],
         item[:proccode] ? item[:proccode].call(value) : value]
      end.compact.to_h
    end

    def calculated_options
      {
        bash: true, # bash block parsing in get_block_summary()
        saved_script_filename: nil # calculated
      }
    end

    public

    ## Determines the correct filename to use for searching files
    #
    def determine_filename(specified_filename: nil, specified_folder: nil, default_filename: nil,
                           default_folder: nil, filetree: nil)
      if specified_filename&.present?
        return specified_filename if specified_filename.start_with?('/')

        File.join(specified_folder || default_folder, specified_filename)
      elsif specified_folder&.present?
        File.join(specified_folder,
                  filetree ? @options[:md_filename_match] : @options[:md_filename_glob])
      else
        File.join(default_folder, default_filename)
      end
    end

    private

    # def error_handler(name = '', event = nil, backtrace = nil)
    #   warn(error = "\n * ERROR * #{name}; #{$!.inspect}")
    #   warn($@.take(4).map.with_index { |line, ind| " *   #{ind}: #{line}" })
    #   binding.pry if $tap_enable
    #   raise ArgumentError, error
    # end

    # Reports and executes block logic
    def execute_block_logic(files)
      @options[:filename] = select_document_if_multiple(files)
      @options.document_menu_loop
    end

    ## Executes the block specified in the options
    #
    def execute_block_with_error_handling
      finalize_cli_argument_processing
      execute_code_block_based_on_options(@options)
    rescue FileMissingError
      warn "File missing: #{$!}"
    rescue StandardError
      error_handler('execute_block_with_error_handling')
    end

    # Main method to execute a block based on options and block_name
    def execute_code_block_based_on_options(options)
      options = calculated_options.merge(options)
      update_options(options, over: false)

      simple_commands = {
        doc_glob: -> { @fout.fout options[:md_filename_glob] },
        # list_blocks: -> { list_blocks },
        list_default_env: -> { @fout.fout_list list_default_env },
        list_default_yaml: -> { @fout.fout_list list_default_yaml },
        list_docs: -> { @fout.fout_list files },
        list_recent_output: -> {
                              @fout.fout_list list_recent_output(
                                @options[:saved_stdout_folder],
                                @options[:saved_stdout_glob], @options[:list_count]
                              )
                            },
        list_recent_scripts: -> {
                               @fout.fout_list list_recent_scripts(
                                 options[:saved_script_folder],
                                 options[:saved_script_glob], options[:list_count]
                               )
                             },
        pwd: -> { @fout.fout File.expand_path('..', __dir__) },
        run_last_script: -> { run_last_script },
        select_recent_output: -> { select_recent_output },
        select_recent_script: -> { select_recent_script },
        tab_completions: -> { @fout.fout tab_completions },
        menu_export: -> { @fout.fout menu_export }
      }

      return if execute_simple_commands(simple_commands)

      files = opts_prepare_file_list(options)
      execute_block_logic(files)
      return unless @options[:output_saved_script_filename]

      @fout.fout "script_block_name: #{@options.run_state.script_block_name}"
      @fout.fout "s_save_filespec: #{@options.run_state.saved_filespec}"
    rescue StandardError
      error_handler('execute_code_block_based_on_options')
    end

    # Executes command based on the provided option keys
    def execute_simple_commands(simple_commands)
      simple_commands.each_key do |key|
        if @options[key]
          simple_commands[key].call
          return true
        end
      end
      false
    end

    ## post-parse options configuration
    #
    def finalize_cli_argument_processing(rest = @rest)
      ## position 0: file or folder (optional)
      #
      if (pos = rest.shift)&.present?
        if Dir.exist?(pos)
          @options[:path] = pos
        elsif File.exist?(pos)
          @options[:filename] = pos
        else
          raise FileMissingError, pos, caller
        end
      end

      ## position 1: block name (optional)
      #
      @options[:block_name] = nil
      @options[:input_cli_rest] = @rest
    rescue FileMissingError
      warn_format('finalize_cli_argument_processing',
                  "File missing -- #{$!}", { abort: true })
      exit 1
    rescue StandardError
      error_handler('finalize_cli_argument_processing')
    end

    ## Sets up the options and returns the parsed arguments
    #
    def initialize_and_parse_cli_options
      # @options = base_options
      @options = HashDelegator.new(base_options)

      read_configuration_file!(@options,
                               ".#{MarkdownExec::APP_NAME.downcase}.yml")

      @option_parser = OptionParser.new do |opts|
        executable_name = File.basename($PROGRAM_NAME)
        opts.banner = [
          "#{MarkdownExec::APP_NAME}" \
          " - #{MarkdownExec::APP_DESC} (#{MarkdownExec::VERSION})",
          "Usage: #{executable_name} [(path | filename [block_name])] [options]"
        ].join("\n")

        menu_iter do |item|
          opts_menu_option_append opts, @options, item
        end
      end
      @option_parser.load
      @option_parser.environment
      @rest = rest = @option_parser.parse!(arguments_for_mde)
      @options.pass_args = ARGV[rest.count + 1..]
      @options.merge(@options.run_state.to_h)

      rest
    end

    ##
    # Returns a lambda expression based on the given procname.
    # @param procname [String] The name of the process to generate a lambda for.
    # @param options [Hash] The options hash, necessary for some lambdas to access.
    # @return [Lambda] The corresponding lambda expression.
    def lambda_for_procname(procname, options)
      case procname
      when 'debug'
        ->(value) { tap_config value: value }
      when 'exit'
        ->(_) { exit }
      when 'find'
        ->(value) {
          find_path = @options[:find_path].present? ? @options[:find_path] : @options[:path]
          @fout.fout 'Searching in: ' \
                     "#{HashDelegator.new(@options).string_send_color(find_path,
                                                                      :menu_chrome_color)}"
          searcher = DirectorySearcher.new(value, [find_path])

          @fout.fout 'In file contents'
          hash = searcher.search_in_file_contents
          hash.each.with_index do |(key, v2), i1|
            @fout.fout format('- %3.d: %s', i1 + 1, key)
            @fout.fout AnsiFormatter.new(options).format_and_highlight_array(
              v2.map { |nl| format('=%4.d: %s', nl.index, nl.line) },
              highlight: [value]
            )
          end

          @fout.fout 'In directory names'
          @fout.fout AnsiFormatter.new(options).format_and_highlight_array(
            searcher.search_in_directory_names, highlight: [value]
          )

          @fout.fout 'In file names'
          @fout.fout AnsiFormatter.new(options).format_and_highlight_array(
            searcher.search_in_file_names, highlight: [value]
          ).join("\n")

          exit
        }
      when 'help'
        ->(_) {
          @fout.fout menu_help
          exit
        }
      when 'how'
        ->(value) {
          @fout.fout(list_default_yaml.select { |line| line.include? value })
          exit
        }
      when 'path'
        ->(value) {
          read_configuration_file!(options, value)
        }
      when 'show_config'
        ->(_) {
          finalize_cli_argument_processing(options)
          @fout.fout options.sort_by_key.to_yaml
        }
      when 'val_as_bool'
        ->(value) {
          value.instance_of?(::String) ? (value.chomp != '0') : value
        }
      when 'val_as_int'
        ->(value) { value.to_i }
      when 'val_as_str'
        ->(value) { value.to_s }
      when 'version'
        lambda { |_|
          @fout.fout MarkdownExec::VERSION
          exit
        }
      else
        procname
      end
    end

    # def list_blocks; end

    def list_default_env
      menu_iter do |item|
        next unless item[:env_var].present?

        [
          "#{item[:env_var]}=#{value_for_cli item[:default]}",
          item[:description].present? ? item[:description] : nil
        ].compact.join('      # ')
      end.compact.sort
    end

    def list_default_yaml
      menu_iter do |item|
        next unless item[:opt_name].present? && item[:default].present?

        [
          "#{item[:opt_name]}: #{OptionValue.for_yaml(item[:default])}",
          item[:description].present? ? item[:description] : nil
        ].compact.join('      # ')
      end.compact.sort
    end

    public

    ## Searches for files based on the specified or default filenames and folders
    #
    def list_files_specified(fn, filetree = nil)
      return Dir.glob(fn) unless filetree

      filetree.select do |filename|
        filename == fn || filename.match(/^#{fn}$/) || filename.match(%r{^#{fn}/.+$})
      end
    end

    def list_markdown_files_in_path
      Dir.glob(File.join(@options[:path],
                         @options[:md_filename_glob]))
    end

    private

    ##
    # Generates a menu suitable for OptionParser from the menu items defined in YAML format.
    # @return [Array<Hash>] The array of option hashes for OptionParser.
    def menu_for_optparse
      menu_from_yaml.map do |menu_item|
        menu_item.merge(
          opt_name: menu_item[:opt_name]&.to_sym,
          proccode: lambda_for_procname(menu_item[:procname], options)
        )
      end
    end

    def menu_help
      @option_parser.help
    end

    def menu_iter(data = menu_for_optparse, &block)
      data.map(&block)
    end

    def menu_export(data = menu_for_optparse)
      data.map do |item|
        item.delete(:procname)
        item
      end.to_yaml
    end

    def opts_menu_option_append(opts, options, item)
      return unless item[:long_name].present? || item[:short_name].present?

      opts.on(*[
        # - long name
        if item[:long_name].present?
          "--#{item[:long_name]}#{item[:arg_name].present? ? " #{item[:arg_name]}" : ''}"
        end,

        # - short name
        item[:short_name].present? ? "-#{item[:short_name]}" : nil,

        # - description and default
        [item[:description],
         ("[#{value_for_cli item[:default]}]" if item[:default].present?)].compact.join('  '),

        # apply proccode, if present, to value
        # save value to options hash if option is named
        #
        lambda { |value|
          (item[:proccode] ? item[:proccode].call(value) : value).tap do |converted|
            options[item[:opt_name]] = converted if item[:opt_name]
          end
        }
      ].compact)
    end

    def opts_prepare_file_list(options)
      list_files_specified(
        determine_filename(
          specified_filename: options[:filename]&.present? ? options[:filename] : nil,
          specified_folder: options[:path],
          default_filename: 'README.md',
          default_folder: '.'
        )
      )
    end

    # :reek:UtilityFunction ### temp
    def read_configuration_file!(options, configuration_path)
      return unless File.exist?(configuration_path)

      options.merge!((YAML.load(File.open(configuration_path)) || {})
        .transform_keys(&:to_sym))
    end

    public

    def run
      initialize_and_parse_cli_options
      execute_block_with_error_handling
    rescue StandardError
      error_handler('run')
    ensure
      yield if block_given?
    end

    private

    def run_last_script
      filename = SavedFilesMatcher.most_recent(@options[:saved_script_folder],
                                               @options[:saved_script_glob])
      return unless filename

      saved_name_split filename
      @options[:save_executed_script] = false
      @options.document_menu_loop
    rescue StandardError
      error_handler('run_last_script')
    end

    def saved_name_split(name)
      # rubocop:disable Layout/LineLength
      mf = /#{@options[:saved_script_filename_prefix]}_(?<time>[0-9\-]+)_(?<file>.+)_,_(?<block>.+)\.sh/.match(name)
      # rubocop:enable Layout/LineLength
      return unless mf

      @options[:block_name] = mf[:block]
      @options[:filename] = mf[:file].gsub(@options[:saved_filename_pattern],
                                           @options[:saved_filename_replacement])
    end

    def select_document_if_multiple(files = list_markdown_files_in_path)
      return files[0] if (count = files.count) == 1

      return unless count >= 2

      opts = options.dup
      select_option_or_exit(HashDelegator.new(@options).string_send_color(opts[:prompt_select_md].to_s, :prompt_color_after_script_execution),
                            files,
                            opts.merge(per_page: opts[:select_page_height]))
    end

    # Presents a TTY prompt to select an option or exit, returns selected option or nil
    def select_option_or_exit(prompt_text, strings, opts = {})
      result = @options.select_option_with_metadata(prompt_text, strings,
                                                    opts)
      return unless result.fetch(:option, nil)

      result[:selected]
    end

    def select_recent_output
      filename = select_option_or_exit(
        HashDelegator.new(@options).string_send_color(@options[:prompt_select_output].to_s,
                                                      :prompt_color_after_script_execution),
        list_recent_output(
          @options[:saved_stdout_folder],
          @options[:saved_stdout_glob],
          @options[:list_count]
        ),
        @options.merge({ per_page: @options[:select_page_height] })
      )
      return unless filename.present?

      `open #{filename} #{options[:output_viewer_options]}`
    end

    def select_recent_script
      filename = select_option_or_exit(
        HashDelegator.new(@options).string_send_color(@options[:prompt_select_md].to_s,
                                                      :prompt_color_after_script_execution),
        list_recent_scripts(
          @options[:saved_script_folder],
          @options[:saved_script_glob],
          @options[:list_count]
        ),
        @options.merge({ per_page: @options[:select_page_height] })
      )
      return if filename.nil?

      saved_name_split(filename)

      @options.document_menu_loop ### ({ save_executed_script: false })
    end

    public

    def tab_completions(data = menu_for_optparse)
      data.map do |item|
        "--#{item[:long_name]}" if item[:long_name]
      end.compact
    end

    # :reek:BooleanParameter
    # :reek:ControlParameter
    def update_options(opts = {}, over: true)
      if over
        @options = @options.merge opts
      else
        @options.merge! opts
      end
      @options
    end
  end # class MarkParse
end # module MarkdownExec

if $PROGRAM_NAME == __FILE__
  require 'bundler/setup'
  Bundler.require(:default)

  require 'minitest/autorun'

  module MarkdownExec
    def test_select_block
      blocks = [block1, block2]
      menu = [m1, m2]

      block, state = obj.select_block(blocks, menu, nil, {})

      assert_equal block1, block
      assert_equal MenuState::CONTINUE, state
    end
  end # module MarkdownExec
end  # if
