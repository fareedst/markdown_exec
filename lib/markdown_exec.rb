#!/usr/bin/env ruby
# frozen_string_literal: true

# encoding=utf-8

require 'English'
require 'clipboard'
require 'fileutils'
require 'open3'
require 'optparse'
require 'shellwords'
require 'time'
require 'tmpdir'
require 'tty-prompt'
require 'yaml'

require_relative 'ansi_formatter'
require_relative 'block_label'
require_relative 'cached_nested_file_reader'
require_relative 'cli'
require_relative 'color_scheme'
require_relative 'colorize'
require_relative 'directory_searcher'
require_relative 'env'
require_relative 'exceptions'
require_relative 'fcb'
require_relative 'filter'
require_relative 'find_files'
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

$pd = false unless defined?($pd)

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

# execute markdown documents
#
module MarkdownExec
  include Exceptions

  class FileInMenu
    # Prepends the age of the file in days to the file name for display in a menu.
    # @param filename [String] the name of the file
    # @return [String] modified file name with age prepended
    def self.for_menu(filename)
      file_age = (Time.now - File.mtime(filename)) / (60 * 60 * 24 * 30)
      filename = ColorScheme.colorize_path(filename)

      "  #{Histogram.display(file_age, 0, 11, 12, inverse: false)}: #{filename}"
    end

    # Removes the age from the string to retrieve the original file name.
    # @param filename_with_age [String] the modified file name with age
    # @return [String] the original file name
    def self.from_menu(dname)
      filename_with_age = dname.gsub(/\033\[[\d;]+m|\033\[0m/, '')
      filename_with_age.split(': ', 2).last
    end
  end

  # A class that generates a histogram bar in terminal using xterm-256 color codes.
  class Histogram
    # Generates and prints a histogram bar for a given value within a specified range and width, with an option for inverse display.
    # @param integer_value [Integer] the value to represent in the histogram
    # @param min [Integer] the minimum value of the range
    # @param max [Integer] the maximum value of the range
    # @param width [Integer] the total width of the histogram in characters
    # @param inverse [Boolean] whether the histogram is displayed in inverse order (right to left)
    def self.display(integer_value, min, max, width, inverse: false)
      return if max <= min # Ensure the range is valid

      # Normalize the value within the range 0 to 1
      normalized_value = [
        0,
        [(integer_value - min).to_f / (max - min), 1].min
      ].max

      # Calculate how many characters should be filled
      filled_length = (normalized_value * width).round

      # # Generate the histogram bar using xterm-256 colors (color code 42 is green)
      # filled_bar = "\e[48;5;42m" + ' ' * filled_length + "\e[0m"
      filled_bar = ('¤' * filled_length).fg_rgbh_AF_AF_00
      empty_bar = ' ' * (width - filled_length)

      # Determine the order of filled and empty parts based on the inverse flag
      inverse ? (empty_bar + filled_bar) : (filled_bar + empty_bar)
    end
  end

  class MenuBuilder
    def initialize
      @chrome_color = :cyan
      @o_color = :red
    end

    def build_menu(file_names, directory_names, found_in_block_names,
                   files_in_directories, vbn)
      choices = []

      # Adding section title and data for file names
      choices << { disabled: '',
                   name: "in #{file_names[:section_title]}".send(@chrome_color) }
      choices += file_names[:data].map { |str| FileInMenu.for_menu(str) }

      # Conditionally add directory names if data is present
      unless directory_names[:data].count.zero?
        choices << { disabled: '',
                     name: "in #{directory_names[:section_title]}".send(@chrome_color) }
        choices += files_in_directories
      end

      # Adding found in block names
      choices << { disabled: '',
                   name: "in #{found_in_block_names[:section_title]}".send(@chrome_color) }

      choices += vbn

      choices
    end
  end

  class SearchResultsReport < DirectorySearcher
    def directory_names(search_options, highlight_value)
      matched_directories = find_directory_names
      {
        section_title: 'directory names',
        data: matched_directories,
        formatted_text: [{ content: AnsiFormatter.new(search_options).format_and_highlight_array(
          matched_directories, highlight: [highlight_value]
        ) }]
      }
    end

    def found_in_block_names(search_options, highlight_value,
                             formspec: '=%<index>4.d: %<line>s')
      matched_contents = (find_file_contents do |line|
                            read_block_name(line, search_options[:fenced_start_and_end_regex],
                                            search_options[:block_name_match], search_options[:block_name_nick_match])
                          end).map.with_index do |(file, contents), index|
        # [file, contents.map { |detail| format(formspec, detail.index, detail.line) }, index]
        [file, contents.map do |detail|
                 format(formspec, { index: detail.index, line: detail.line })
               end, index]
      end
      {
        section_title: 'block names',
        data: matched_contents.map(&:first),
        formatted_text: matched_contents.map do |(file, details, index)|
                          { header: format('- %3.d: %s', index + 1, file),
                            content: AnsiFormatter.new(search_options).format_and_highlight_array(
                              details,
                              highlight: [highlight_value]
                            ) }
                        end,
        matched_contents: matched_contents
      }
    end

    def file_names(search_options, highlight_value)
      matched_files = find_file_names
      {
        section_title: 'file names',
        data: matched_files,
        formatted_text: [{ content: AnsiFormatter.new(search_options).format_and_highlight_array(
          matched_files, highlight: [highlight_value]
        ).join("\n") }]
      }
    end

    def read_block_name(line, fenced_start_and_end_regex, block_name_match,
                        block_name_nick_match)
      return unless line.match(fenced_start_and_end_regex)

      bm = extract_named_captures_from_option(line, block_name_match)
      return if bm.nil?

      name = bm[:title]

      if block_name_nick_match.present? && line =~ Regexp.new(block_name_nick_match)
        $~[0]
      else
        bm && bm[1] ? bm[:title] : name
      end
    end
  end

  ##
  #
  # :reek:DuplicateMethodCall { allow_calls: ['block', 'item', 'lm', 'opts', 'option', '@options', 'required_blocks'] }
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

    def warn_format(name, message, opts = {})
      Exceptions.warn_format(
        "CachedNestedFileReader.#{name} -- #{message}",
        opts
      )
    end

    # return arguments before ARGV_SEP
    # arguments after ARGV_SEP are passed to the generated script
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
      @options.document_inpseq
    rescue StandardError
      error_handler('execute_block_logic')
    # rubocop:disable Style/RescueStandardError
    rescue
      pp $!, $@
      exit 1
      # rubocop:enable Style/RescueStandardError
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
        elsif @options[:default_find_select_open]
          find_value(pos, execute_chosen_found: true)
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

    # return { exit: true } to cause app to exit
    def find_value(value, execute_chosen_found: false)
      find_path = @options[:find_path].present? ? @options[:find_path] : @options[:path]
      @fout.fout 'Searching in: ' \
                 "#{HashDelegator.new(@options).string_send_color(find_path,
                                                                  :menu_chrome_color)}"
      searcher = SearchResultsReport.new(value, [find_path])
      file_names = searcher.file_names(options, value)
      found_in_block_names = searcher.found_in_block_names(options, value,
                                                           formspec: '%<line>s')
      directory_names = searcher.directory_names(options, value)

      ### search in file contents (block names, chrome, or text)
      [found_in_block_names,
       directory_names,
       file_names].each do |data|
        next if data[:data].count.zero?
        next unless data[:formatted_text]

        @fout.fout "In #{data[:section_title]}" if data[:section_title]
        data[:formatted_text].each do |fi|
          @fout.fout fi[:header] if fi[:header]
          @fout.fout fi[:content] if fi[:content]
        end
      end
      return { exit: true } unless execute_chosen_found

      ## pick a document to open
      #
      files_in_directories = directory_names[:data].map do |dn|
        find_files('*', [dn], exclude_dirs: true)
      end.flatten(1).map { |str| FileInMenu.for_menu(str) }

      unless file_names[:data]&.count.positive? || files_in_directories&.count.positive? || found_in_block_names[:data]&.count.positive?
        return { exit: true }
      end

      vbn = found_in_block_names[:matched_contents].map do |matched_contents|
        filename, details, = matched_contents
        nexo = AnsiFormatter.new(@options).format_and_highlight_array(
          details,
          highlight: [value]
        )
        [FileInMenu.for_menu(filename)] +
          nexo.map do |str|
            { disabled: '', name: (' ' * 20) + str }
          end
      end.flatten

      choices = MenuBuilder.new.build_menu(file_names, directory_names, found_in_block_names,
                                           files_in_directories, vbn)

      @options[:filename] = FileInMenu.from_menu(
        select_document_if_multiple(
          choices,
          prompt: options[:prompt_select_md].to_s + ' ¤ Age in months'.fg_rgbh_AF_AF_00
        )
      )
      { exit: false }
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
          "Usage: #{executable_name} [(directory | file [block_name] | search_keyword)] [options]"
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
      when 'find', 'open'
        ->(value) {
          exit if find_value(value, execute_chosen_found: procname == 'open').fetch(:exit,
                                                                                    false)
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
          finalize_cli_argument_processing([])
          @fout.fout options.sort_by_key.to_yaml
        }
      when 'val_as_bool'
        ->(value) {
          value.instance_of?(::String) ? (value.chomp != '0') : value
        }
      when 'val_as_int'
        lambda(&:to_i)
      when 'val_as_str'
        lambda(&:to_s)
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
      @options.document_inpseq
    rescue StandardError
      error_handler('run_last_script')
    end

    def saved_name_split(name)
      mf = /#{@options[:saved_script_filename_prefix]}_(?<time>[0-9\-]+)_(?<file>.+)_,_(?<block>.+)\.sh/.match(name)
      return unless mf

      @options[:block_name] = mf[:block]
      @options[:filename] = mf[:file].gsub(@options[:saved_filename_pattern],
                                           @options[:saved_filename_replacement])
    end

    def select_document_if_multiple(files = list_markdown_files_in_path,
                                    prompt: options[:prompt_select_md].to_s)
      return files[0] if (count = files.count) == 1

      return unless count >= 2

      opts = options.dup
      select_option_or_exit(
        HashDelegator.new(@options).string_send_color(prompt,
                                                      :prompt_color_after_script_execution),
        files,
        opts.merge(per_page: opts[:select_page_height])
      )
    end

    # Presents a TTY prompt to select an option or exit, returns selected option or nil
    def select_option_or_exit(prompt_text, strings, opts = {})
      @options.select_option_with_metadata(
        prompt_text, strings, opts
      )&.fetch(:selected)
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
end # if
