#!/usr/bin/env ruby
# frozen_string_literal: true

# encoding=utf-8

require 'English'
require 'clipboard'
require 'fileutils'
require 'open3'
require 'optparse'
require 'shellwords'
require 'tty-prompt'
require 'yaml'

require_relative 'block_label'
require_relative 'cached_nested_file_reader'
require_relative 'cli'
require_relative 'colorize'
require_relative 'env'
require_relative 'fcb'
require_relative 'filter'
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

MDE_HISTORY_ENV_NAME = 'MDE_MENU_HISTORY'

# macros
#
LOAD_FILE = true

# custom error: file specified is missing
#
class FileMissingError < StandardError; end

# hash with keys sorted by name
# add Hash.sym_keys
#
class Hash
  unless defined?(sort_by_key)
    def sort_by_key
      keys.sort.to_h { |key| [key, self[key]] }
    end
  end

  unless defined?(sym_keys)
    def sym_keys
      transform_keys(&:to_sym)
    end
  end
end

# integer value for comparison
#
def options_fetch_display_level(options)
  options.fetch(:display_level, 1)
end

# integer value for comparison
#
def options_fetch_display_level_xbase_prefix(options)
  options.fetch(:level_xbase_prefix, '')
end

# stdout manager
#
module FOUT
  # standard output; not for debug
  #
  def fout(str)
    puts str
  end

  def fout_list(str)
    puts str
  end

  def fout_section(name, data)
    puts "# #{name}"
    puts data.to_yaml
  end

  def approved_fout?(level)
    level <= options_fetch_display_level(@options)
  end

  # display output at level or lower than filter (DISPLAY_LEVEL_DEFAULT)
  #
  def lout(str, level: DISPLAY_LEVEL_BASE)
    return unless approved_fout? level

    fout level == DISPLAY_LEVEL_BASE ? str : options_fetch_display_level_xbase_prefix(@options) + str
  end
end

def dp(str)
  lout " => #{str}", level: DISPLAY_LEVEL_DEBUG
end

public

# :reek:UtilityFunction
def list_recent_output(saved_stdout_folder, saved_stdout_glob, list_count)
  SavedFilesMatcher.most_recent_list(saved_stdout_folder,
                                     saved_stdout_glob, list_count)
end

# :reek:UtilityFunction
def list_recent_scripts(saved_script_folder, saved_script_glob, list_count)
  SavedFilesMatcher.most_recent_list(saved_script_folder,
                                     saved_script_glob, list_count)
end

# convert regex match groups to a hash with symbol keys
#
# :reek:UtilityFunction
def extract_named_captures_from_option(str, option)
  str.match(Regexp.new(option))&.named_captures&.sym_keys
end

module ArrayUtil
  def self.partition_by_predicate(arr)
    true_list = []
    false_list = []

    arr.each do |element|
      if yield(element)
        true_list << element
      else
        false_list << element
      end
    end

    [true_list, false_list]
  end
end

module StringUtil
  # Splits the given string on the first occurrence of the specified character.
  # Returns an array containing the portion of the string before the character and the rest of the string.
  #
  # @param input_str [String] The string to be split.
  # @param split_char [String] The character on which to split the string.
  # @return [Array<String>] An array containing two elements: the part of the string before split_char, and the rest of the string.
  def self.partition_at_first(input_str, split_char)
    split_index = input_str.index(split_char)

    if split_index.nil?
      [input_str, '']
    else
      [input_str[0...split_index], input_str[(split_index + 1)..-1]]
    end
  end
end

# execute markdown documents
#
module MarkdownExec
  # :reek:IrresponsibleModule
  FNR11 = '/'
  FNR12 = ',~'

  SHELL_COLOR_OPTIONS = {
    BLOCK_TYPE_BASH => :menu_bash_color,
    BLOCK_TYPE_LINK => :menu_link_color,
    BLOCK_TYPE_OPTS => :menu_opts_color,
    BLOCK_TYPE_VARS => :menu_vars_color
  }.freeze

  ##
  #
  # rubocop:disable Layout/LineLength
  # :reek:DuplicateMethodCall { allow_calls: ['block', 'item', 'lm', 'opts', 'option', '@options', 'required_blocks'] }
  # rubocop:enable Layout/LineLength
  # :reek:MissingSafeMethod { exclude: [ read_configuration_file! ] }
  # :reek:TooManyInstanceVariables ### temp
  # :reek:TooManyMethods ### temp
  class MarkParse
    attr_reader :options

    include ArrayUtil
    include StringUtil
    include FOUT

    def initialize(options = {})
      @execute_aborted_at = nil
      @execute_completed_at = nil
      @execute_error = nil
      @execute_error_message = nil
      @execute_files = nil
      @execute_options = nil
      @execute_script_filespec = nil
      @execute_started_at = nil
      @option_parser = nil
      @options = options
      @prompt = tty_prompt_without_disabled_symbol
    end

    ##
    # Appends a summary of a block (FCB) to the blocks array.
    #
    def append_block_summary(blocks, fcb, opts)
      ## enhance fcb with block summary
      #
      blocks.push get_block_summary(opts, fcb)
    end

    ##
    # Appends a final divider to the blocks array if it is specified in options.
    #
    def append_final_divider(blocks, opts)
      return unless opts[:menu_divider_format].present? && opts[:menu_final_divider].present?

      blocks.push FCB.new(
        { chrome: true,
          disabled: '',
          dname: format(opts[:menu_divider_format],
                        opts[:menu_final_divider])
                               .send(opts[:menu_divider_color].to_sym),
          oname: opts[:menu_final_divider] }
      )
    end

    ##
    # Appends an initial divider to the blocks array if it is specified in options.
    #
    def append_initial_divider(blocks, opts)
      return unless opts[:menu_initial_divider].present?

      blocks.push FCB.new({
                            # name: '',
                            chrome: true,
                            dname: format(
                              opts[:menu_divider_format],
                              opts[:menu_initial_divider]
                            ).send(opts[:menu_divider_color].to_sym),
                            oname: opts[:menu_initial_divider],
                            disabled: '' # __LINE__.to_s
                          })
    end

    # Execute a code block after approval and provide user interaction options.
    #
    # This method displays required code blocks, asks for user approval, and
    # executes the code block if approved. It also allows users to copy the
    # code to the clipboard or save it to a file.
    #
    # @param opts [Hash] Options hash containing configuration settings.
    # @param mdoc [YourMDocClass] An instance of the MDoc class.
    #
    def approve_and_execute_block(opts, mdoc)
      selected = mdoc.get_block_by_name(opts[:block_name])

      if selected.fetch(:shell, '') == BLOCK_TYPE_LINK
        handle_shell_link(opts, selected.fetch(:body, ''), mdoc)
      elsif opts.fetch(:back, false)
        handle_back_link(opts)
      elsif selected[:shell] == BLOCK_TYPE_OPTS
        handle_shell_opts(opts, selected)
      else
        handle_remainder_blocks(mdoc, opts, selected)
      end
    end

    # return arguments before `--`
    #
    def arguments_for_mde(argv = ARGV)
      case ind = argv.find_index('--')
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
        [item[:opt_name], item[:proccode] ? item[:proccode].call(value) : value]
      end.compact.to_h
    end

    def blocks_per_opts(blocks, opts)
      return blocks if opts[:struct]

      blocks.map do |block|
        block.fetch(:text, nil) || block.oname
      end.compact.reject(&:empty?)
    end

    def calculated_options
      {
        bash: true, # bash block parsing in get_block_summary()
        saved_script_filename: nil, # calculated
        struct: true # allow get_block_summary()
      }
    end

    # Check whether the document exists and is readable
    def check_file_existence(filename)
      unless filename&.present?
        fout 'No blocks found.'
        return false
      end

      unless File.exist? filename
        fout 'Document is missing.'
        return false
      end
      true
    end

    def clear_required_file
      ENV['MDE_LINK_REQUIRED_FILE'] = ''
    end

    # Collect required code blocks based on the provided options.
    #
    # @param opts [Hash] Options hash containing configuration settings.
    # @param mdoc [YourMDocClass] An instance of the MDoc class.
    # @return [Array<String>] Required code blocks as an array of lines.
    def collect_required_code_lines(mdoc, selected, opts: {})
      # Apply hash in opts block to environment variables
      if selected[:shell] == BLOCK_TYPE_VARS
        data = YAML.load(selected[:body].join("\n"))
        data.each_key do |key|
          ENV[key] = value = data[key].to_s
          next unless opts[:menu_vars_set_format].present?

          print format(
            opts[:menu_vars_set_format],
            { key: key,
              value: value }
          ).send(opts[:menu_vars_set_color].to_sym)
        end
      end

      required = mdoc.collect_recursively_required_code(opts[:block_name], opts: opts)
      read_required_blocks_from_temp_file + required[:code]
    end

    def cfile
      @cfile ||= CachedNestedFileReader.new(
        import_pattern: @options.fetch(:import_pattern)
      )
    end

    EF_STDOUT = :stdout
    EF_STDERR = :stderr
    EF_STDIN  = :stdin

    # Existing command_execute method
    def command_execute(opts, command, args: [])
      @execute_files = Hash.new([])
      @execute_options = opts
      @execute_started_at = Time.now.utc

      Open3.popen3(opts[:shell], '-c', command, opts[:filename],
                   *args) do |stdin, stdout, stderr, exec_thr|
        handle_stream(opts, stdout, EF_STDOUT) do |line|
          yield nil, line, nil, exec_thr if block_given?
        end
        handle_stream(opts, stderr, EF_STDERR) do |line|
          yield nil, nil, line, exec_thr if block_given?
        end

        in_thr = handle_stream(opts, $stdin, EF_STDIN) do |line|
          stdin.puts(line)
          yield line, nil, nil, exec_thr if block_given?
        end

        exec_thr.join
        sleep 0.1
        in_thr.kill if in_thr&.alive?
      end

      @execute_completed_at = Time.now.utc
    rescue Errno::ENOENT => err
      #d 'command error ENOENT triggered by missing command in script'
      @execute_aborted_at = Time.now.utc
      @execute_error_message = err.message
      @execute_error = err
      @execute_files[EF_STDERR] += [@execute_error_message]
      fout "Error ENOENT: #{err.inspect}"
    rescue SignalException => err
      #d 'command SIGTERM triggered by user or system'
      @execute_aborted_at = Time.now.utc
      @execute_error_message = 'SIGTERM'
      @execute_error = err
      @execute_files[EF_STDERR] += [@execute_error_message]
      fout "Error ENOENT: #{err.inspect}"
    end

    def copy_to_clipboard(required_lines)
      text = required_lines.flatten.join($INPUT_RECORD_SEPARATOR)
      Clipboard.copy(text)
      fout "Clipboard updated: #{required_lines.count} blocks," \
           " #{required_lines.flatten.count} lines," \
           " #{text.length} characters"
    end

    def count_blocks_in_filename
      fenced_start_and_end_regex = Regexp.new @options[:fenced_start_and_end_regex]
      cnt = 0
      cfile.readlines(@options[:filename]).each do |line|
        cnt += 1 if line.match(fenced_start_and_end_regex)
      end
      cnt / 2
    end

    def create_and_write_file_with_permissions(file_path, content, chmod_value)
      dirname = File.dirname(file_path)
      FileUtils.mkdir_p dirname
      File.write(file_path, content)
      return if chmod_value.zero?

      File.chmod chmod_value, file_path
    end

    # Deletes a required temporary file specified by an environment variable.
    # The function checks if the file exists before attempting to delete it.
    # Clears the environment variable after deletion.
    #
    def delete_required_temp_file
      temp_blocks_file_path = ENV.fetch('MDE_LINK_REQUIRED_FILE', nil)

      return if temp_blocks_file_path.nil? || temp_blocks_file_path.empty?

      FileUtils.rm_f(temp_blocks_file_path)

      clear_required_file
    end

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

    # :reek:DuplicateMethodCall
    def display_required_code(opts, required_lines)
      frame = opts[:output_divider].send(opts[:output_divider_color].to_sym)
      fout frame
      required_lines.each { |cb| fout cb }
      fout frame
    end

    def execute_approved_block(opts, required_lines)
      write_command_file(opts, required_lines)
      command_execute(
        opts,
        required_lines.flatten.join("\n"),
        args: opts.fetch(:pass_args, [])
      )
      initialize_and_save_execution_output
      output_execution_summary
      output_execution_result
    end

    # Reports and executes block logic
    def execute_block_logic(files)
      @options[:filename] = select_document_if_multiple(files)
      select_approve_and_execute_block({
                                         bash: true,
                                         struct: true
                                       })
    end

    ## Executes the block specified in the options
    #
    def execute_block_with_error_handling(rest)
      finalize_cli_argument_processing(rest)
      execute_code_block_based_on_options(@options, @options[:block_name])
    rescue FileMissingError => err
      puts "File missing: #{err}"
    end

    # Main method to execute a block based on options and block_name
    def execute_code_block_based_on_options(options, _block_name = '')
      options = calculated_options.merge(options)
      update_options(options, over: false)

      simple_commands = {
        doc_glob: -> { fout options[:md_filename_glob] },
        list_blocks: lambda do
                       fout_list (files.map do |file|
                                    make_block_labels(filename: file, struct: true)
                                  end).flatten(1)
                     end,
        list_default_yaml: -> { fout_list list_default_yaml },
        list_docs: -> { fout_list files },
        list_default_env: -> { fout_list list_default_env },
        list_recent_output: lambda {
                              fout_list list_recent_output(
                                @options[:saved_stdout_folder],
                                @options[:saved_stdout_glob], @options[:list_count]
                              )
                            },
        list_recent_scripts: lambda {
                               fout_list list_recent_scripts(
                                 options[:saved_script_folder],
                                 options[:saved_script_glob], options[:list_count]
                               )
                             },
        pwd: -> { fout File.expand_path('..', __dir__) },
        run_last_script: -> { run_last_script },
        select_recent_output: -> { select_recent_output },
        select_recent_script: -> { select_recent_script },
        tab_completions: -> { fout tab_completions },
        menu_export: -> { fout menu_export }
      }

      return if execute_simple_commands(simple_commands)

      files = prepare_file_list(options)
      execute_block_logic(files)
      return unless @options[:output_saved_script_filename]

      fout "saved_filespec: #{@execute_script_filespec}"
    rescue StandardError => err
      warn(error = "ERROR ** MarkParse.execute_code_block_based_on_options(); #{err.inspect}")
      binding.pry if $tap_enable
      raise ArgumentError, error
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

    ##
    # Determines the types of blocks to select based on the filter.
    #
    def filter_block_types
      ## return type of blocks to select
      #
      %i[blocks line]
    end

    ## post-parse options configuration
    #
    def finalize_cli_argument_processing(rest)
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
      block_name = rest.shift
      @options[:block_name] = block_name if block_name.present?
    end

    ## summarize blocks
    #
    def get_block_summary(call_options, fcb)
      opts = optsmerge call_options
      # return fcb.body unless opts[:struct]
      return fcb unless opts[:bash]

      fcb.call = fcb.title.match(Regexp.new(opts[:block_calls_scan]))&.fetch(1, nil)
      titlexcall = if fcb.call
                     fcb.title.sub("%#{fcb.call}", '')
                   else
                     fcb.title
                   end
      bm = extract_named_captures_from_option(titlexcall, opts[:block_name_match])
      fcb.stdin = extract_named_captures_from_option(titlexcall, opts[:block_stdin_scan])
      fcb.stdout = extract_named_captures_from_option(titlexcall, opts[:block_stdout_scan])

      shell_color_option = SHELL_COLOR_OPTIONS[fcb[:shell]]
      fcb.title = fcb.oname = bm && bm[1] ? bm[:title] : titlexcall
      fcb.dname = if shell_color_option && opts[shell_color_option].present?
                    fcb.oname.send(opts[shell_color_option].to_sym)
                  else
                    fcb.oname
                  end
      fcb
    end

    ##
    # Handles errors that occur during the block listing process.
    #
    def handle_error(err)
      warn(error = "ERROR ** MarkParse.list_blocks_in_file(); #{err.inspect}")
      warn(caller[0..4])
      raise StandardError, error
    end

    # Handles the link-back operation.
    #
    # @param opts [Hash] Configuration options hash.
    # @return [Array<Symbol, String>] A tuple containing a LOAD_FILE flag and an empty string.
    def handle_back_link(opts)
      history_state_pop(opts)
      [LOAD_FILE, '']
    end

    # Handles the execution and display of remainder blocks from a selected menu item.
    #
    # @param mdoc [Object] Document object containing code blocks.
    # @param opts [Hash] Configuration options hash.
    # @param selected [Hash] Selected item from the menu.
    # @return [Array<Symbol, String>] A tuple containing a LOAD_FILE flag and an empty string.
    # @note The function can prompt the user for approval before executing code if opts[:user_must_approve] is true.
    def handle_remainder_blocks(mdoc, opts, selected)
      required_lines = collect_required_code_lines(mdoc, selected, opts: opts)
      if opts[:output_script] || opts[:user_must_approve]
        display_required_code(opts, required_lines)
      end
      allow = opts[:user_must_approve] ? prompt_for_user_approval(opts, required_lines) : true
      opts[:ir_approve] = allow
      execute_approved_block(opts, required_lines) if opts[:ir_approve]

      [!LOAD_FILE, '']
    end

    # Handles the link-shell operation.
    #
    # @param opts [Hash] Configuration options hash.
    # @param body [Array<String>] The body content.
    # @param mdoc [Object] Document object containing code blocks.
    # @return [Array<Symbol, String>] A tuple containing a LOAD_FILE flag and a block name.
    def handle_shell_link(opts, body, mdoc)
      data = body.present? ? YAML.load(body.join("\n")) : {}
      data_file = data.fetch('file', nil)
      return [!LOAD_FILE, ''] unless data_file

      history_state_push(mdoc, data_file, opts)

      data.fetch('vars', []).each do |var|
        ENV[var[0]] = var[1].to_s
      end

      [LOAD_FILE, data.fetch('block', '')]
    end

    # Handles options for the shell.
    #
    # @param opts [Hash] Configuration options hash.
    # @param selected [Hash] Selected item from the menu.
    # @return [Array<Symbol, String>] A tuple containing a NOT_LOAD_FILE flag and an empty string.
    def handle_shell_opts(opts, selected)
      data = YAML.load(selected[:body].join("\n"))
      data.each_key do |key|
        opts[key.to_sym] = value = data[key].to_s
        next unless opts[:menu_opts_set_format].present?

        print format(
          opts[:menu_opts_set_format],
          { key: key,
            value: value }
        ).send(opts[:menu_opts_set_color].to_sym)
      end
      [!LOAD_FILE, '']
    end

    # Handles reading and processing lines from a given IO stream
    #
    # @param stream [IO] The IO stream to read from (e.g., stdout, stderr, stdin).
    # @param file_type [Symbol] The type of file to which the stream corresponds.
    def handle_stream(opts, stream, file_type, swap: false)
      Thread.new do
        until (line = stream.gets).nil?
          @execute_files[file_type] = @execute_files[file_type] + [line.strip]
          print line if opts[:output_stdout]
          yield line if block_given?
        end
      rescue IOError
        #d 'stdout IOError, thread killed, do nothing'
      end
    end

    def history_state_exist?
      history = ENV.fetch(MDE_HISTORY_ENV_NAME, '')
      history.present? ? history : nil
    end

    def history_state_partition(opts)
      unit, rest = StringUtil.partition_at_first(
        ENV.fetch(MDE_HISTORY_ENV_NAME, ''),
        opts[:history_document_separator]
      )
      { unit: unit, rest: rest }.tap_inspect
    end

    def history_state_pop(opts)
      state = history_state_partition(opts)
      opts[:filename] = state[:unit]
      ENV[MDE_HISTORY_ENV_NAME] = state[:rest]
      delete_required_temp_file
    end

    def history_state_push(mdoc, data_file, opts)
      [data_file, opts[:block_name]].tap_inspect 'filename, blockname'
      new_history = opts[:filename] +
                    opts[:history_document_separator] +
                    ENV.fetch(MDE_HISTORY_ENV_NAME, '')
      opts[:filename] = data_file
      write_required_blocks_to_temp_file(mdoc, opts[:block_name], opts)
      ENV[MDE_HISTORY_ENV_NAME] = new_history
    end

    ## Sets up the options and returns the parsed arguments
    #
    def initialize_and_parse_cli_options
      @options = base_options
      read_configuration_file!(@options, ".#{MarkdownExec::APP_NAME.downcase}.yml")

      @option_parser = OptionParser.new do |opts|
        executable_name = File.basename($PROGRAM_NAME)
        opts.banner = [
          "#{MarkdownExec::APP_NAME}" \
          " - #{MarkdownExec::APP_DESC} (#{MarkdownExec::VERSION})",
          "Usage: #{executable_name} [(path | filename [block_name])] [options]"
        ].join("\n")

        menu_iter do |item|
          menu_option_append opts, @options, item
        end
      end
      @option_parser.load
      @option_parser.environment

      rest = @option_parser.parse!(arguments_for_mde)
      @options[:pass_args] = ARGV[rest.count + 1..]

      rest
    end

    def initialize_and_save_execution_output
      return unless @options[:save_execution_output]

      @options[:logged_stdout_filename] =
        SavedAsset.stdout_name(blockname: @options[:block_name],
                               filename: File.basename(@options[:filename], '.*'),
                               prefix: @options[:logged_stdout_filename_prefix],
                               time: Time.now.utc)

      @logged_stdout_filespec =
        @options[:logged_stdout_filespec] =
          File.join @options[:saved_stdout_folder],
                    @options[:logged_stdout_filename]
      @logged_stdout_filespec = @options[:logged_stdout_filespec]
      write_execution_output_to_file
    end

    # Initializes variables for regex and other states
    def initialize_state(opts)
      {
        fenced_start_and_end_regex: Regexp.new(opts[:fenced_start_and_end_regex]),
        fenced_start_extended_regex: Regexp.new(opts[:fenced_start_extended_regex]),
        fcb: FCB.new,
        in_fenced_block: false,
        headings: []
      }
    end

    # Main function to iterate through blocks in file
    def iter_blocks_in_file(opts = {}, &block)
      return unless check_file_existence(opts[:filename])

      state = initialize_state(opts)

      # get type of messages to select
      selected_messages = yield :filter

      cfile.readlines(opts[:filename]).each do |line|
        next unless line

        update_line_and_block_state(line, state, opts, selected_messages, &block)
      end
    end

    ##
    # Returns a list of blocks in a given file, including dividers, tasks, and other types of blocks.
    # The list can be customized via call_options and options_block.
    #
    # @param call_options [Hash] Options passed as an argument.
    # @param options_block [Proc] Block for dynamic option manipulation.
    # @return [Array<FCB>] An array of FCB objects representing the blocks.
    #
    def list_blocks_in_file(call_options = {}, &options_block)
      opts = optsmerge(call_options, options_block)
      use_chrome = !opts[:no_chrome]

      blocks = []
      append_initial_divider(blocks, opts) if use_chrome

      iter_blocks_in_file(opts) do |btype, fcb|
        case btype
        when :filter
          filter_block_types
        when :line
          process_line_blocks(blocks, fcb, opts, use_chrome)
        when :blocks
          append_block_summary(blocks, fcb, opts)
        end
      end

      append_final_divider(blocks, opts) if use_chrome
      blocks
    rescue StandardError => err
      handle_error(err)
    end

    ##
    # Processes lines within the file and converts them into blocks if they match certain criteria.
    #
    def process_line_blocks(blocks, fcb, opts, use_chrome)
      ## convert line to block
      #
      if opts[:menu_divider_match].present? &&
         (mbody = fcb.body[0].match opts[:menu_divider_match])
        if use_chrome
          blocks.push FCB.new(
            { chrome: true,
              disabled: '',
              dname: format(opts[:menu_divider_format],
                            mbody[:name]).send(opts[:menu_divider_color].to_sym),
              oname: mbody[:name] }
          )
        end
      elsif opts[:menu_task_match].present? &&
            (fcb.body[0].match opts[:menu_task_match])
        if use_chrome
          blocks.push FCB.new(
            { chrome: true,
              disabled: '',
              dname: format(
                opts[:menu_task_format],
                $~.named_captures.transform_keys(&:to_sym)
              ).send(opts[:menu_task_color].to_sym),
              oname: format(
                opts[:menu_task_format],
                $~.named_captures.transform_keys(&:to_sym)
              ) }
          )
        end
      else
        # line not added
      end
    end

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

    def list_files_per_options(options)
      list_files_specified(
        determine_filename(
          specified_filename: options[:filename]&.present? ? options[:filename] : nil,
          specified_folder: options[:path],
          default_filename: 'README.md',
          default_folder: '.'
        )
      )
    end

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

    ## output type (body string or full object) per option struct and bash
    #
    def list_named_blocks_in_file(call_options = {}, &options_block)
      opts = optsmerge call_options, options_block

      blocks = list_blocks_in_file(opts.merge(struct: true)).select do |fcb|
        # fcb.fetch(:name, '') != '' && Filter.fcb_select?(opts, fcb)
        Filter.fcb_select?(opts.merge(no_chrome: true), fcb)
      end
      blocks_per_opts(blocks, opts)
    end

    ## Handles the file loading and returns the blocks in the file and MDoc instance
    #
    def load_file_and_prepare_menu(opts)
      blocks_in_file = list_blocks_in_file(opts.merge(struct: true))
      mdoc = MDoc.new(blocks_in_file) do |nopts|
        opts.merge!(nopts)
      end
      blocks_menu = mdoc.fcbs_per_options(opts.merge(struct: true))
      [blocks_in_file, blocks_menu, mdoc]
    end

    def make_block_labels(call_options = {})
      opts = options.merge(call_options)
      list_blocks_in_file(opts).map do |fcb|
        BlockLabel.make(
          filename: opts[:filename],
          headings: fcb.fetch(:headings, []),
          menu_blocks_with_docname: opts[:menu_blocks_with_docname],
          menu_blocks_with_headings: opts[:menu_blocks_with_headings],
          title: fcb[:title],
          text: fcb[:text],
          body: fcb[:body]
        )
      end.compact
    end

    def menu_export(data = menu_for_optparse)
      data.map do |item|
        item.delete(:procname)
        item
      end.to_yaml
    end

    def menu_for_blocks(menu_options)
      options = calculated_options.merge menu_options
      menu = []
      iter_blocks_in_file(options) do |btype, fcb|
        case btype
        when :filter
          %i[blocks line]
        when :line
          if options[:menu_divider_match] &&
             (mbody = fcb.body[0].match(options[:menu_divider_match]))
            menu.push FCB.new({ dname: mbody[:name], oname: mbody[:name], disabled: '' })
          end
        when :blocks
          menu += [fcb.oname]
        end
      end
      menu
    end

    # :reek:DuplicateMethodCall
    # :reek:NestedIterators
    def menu_for_optparse
      menu_from_yaml.map do |menu_item|
        menu_item.merge(
          {
            opt_name: menu_item[:opt_name]&.to_sym,
            proccode: case menu_item[:procname]
                      when 'debug'
                        lambda { |value|
                          tap_config value: value
                        }
                      when 'exit'
                        lambda { |_|
                          exit
                        }
                      when 'help'
                        lambda { |_|
                          fout menu_help
                          exit
                        }
                      when 'path'
                        lambda { |value|
                          read_configuration_file!(options, value)
                        }
                      when 'show_config'
                        lambda { |_|
                          finalize_cli_argument_processing(options)
                          fout options.sort_by_key.to_yaml
                        }
                      when 'val_as_bool'
                        lambda { |value|
                          value.instance_of?(::String) ? (value.chomp != '0') : value
                        }
                      when 'val_as_int'
                        ->(value) { value.to_i }
                      when 'val_as_str'
                        ->(value) { value.to_s }
                      when 'version'
                        lambda { |_|
                          fout MarkdownExec::VERSION
                          exit
                        }
                      else
                        menu_item[:procname]
                      end
          }
        )
      end
    end

    def menu_help
      @option_parser.help
    end

    def menu_iter(data = menu_for_optparse, &block)
      data.map(&block)
    end

    def menu_option_append(opts, options, item)
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

    # :reek:ControlParameter
    def optsmerge(call_options = {}, options_block = nil)
      class_call_options = @options.merge(call_options || {})
      if options_block
        options_block.call class_call_options
      else
        class_call_options
      end
    end

    def output_execution_result
      oq = [['Block', @options[:block_name], DISPLAY_LEVEL_ADMIN],
            ['Command',
             [MarkdownExec::BIN_NAME,
              @options[:filename],
              @options[:block_name]].join(' '),
             DISPLAY_LEVEL_ADMIN]]

      [['Script', :saved_filespec],
       ['StdOut', :logged_stdout_filespec]].each do |label, name|
        oq << [label, @options[name], DISPLAY_LEVEL_ADMIN] if @options[name]
      end

      oq.map do |label, value, level|
        lout ["#{label}:".yellow, value.to_s].join(' '), level: level
      end
    end

    def output_execution_summary
      return unless @options[:output_execution_summary]

      fout_section 'summary', {
        execute_aborted_at: @execute_aborted_at,
        execute_completed_at: @execute_completed_at,
        execute_error: @execute_error,
        execute_error_message: @execute_error_message,
        execute_files: @execute_files,
        execute_options: @execute_options,
        execute_started_at: @execute_started_at,
        execute_script_filespec: @execute_script_filespec
      }
    end

    # Prepare the blocks menu by adding labels and other necessary details.
    #
    # @param blocks_in_file [Array<Hash>] The list of blocks from the file.
    # @param opts [Hash] The options hash.
    # @return [Array<Hash>] The updated blocks menu.
    def prepare_blocks_menu(blocks_in_file, opts)
      # next if fcb.fetch(:disabled, false)
      # next unless fcb.fetch(:name, '').present?
      blocks_in_file.map do |fcb|
        fcb.merge!(
          name: fcb.dname,
          label: BlockLabel.make(
            body: fcb[:body],
            filename: opts[:filename],
            headings: fcb.fetch(:headings, []),
            menu_blocks_with_docname: opts[:menu_blocks_with_docname],
            menu_blocks_with_headings: opts[:menu_blocks_with_headings],
            text: fcb[:text],
            title: fcb[:title]
          )
        )
        fcb.to_h
      end.compact
    end

    # Prepares and fetches file listings
    def prepare_file_list(options)
      list_files_per_options(options)
    end

    def process_fenced_block(fcb, opts, selected_messages, &block)
      fcb.oname = fcb.dname = fcb.title || ''
      return unless fcb.body

      set_fcb_title(fcb)

      if block &&
         selected_messages.include?(:blocks) &&
         Filter.fcb_select?(opts, fcb)
        block.call :blocks, fcb
      end
    end

    def process_line(line, _opts, selected_messages, &block)
      return unless block && selected_messages.include?(:line)

      #  dp 'text outside of fcb'
      fcb = FCB.new
      fcb.body = [line]
      block.call(:line, fcb)
    end

    ##
    # Presents a menu to the user for approving an action and performs additional tasks based on the selection.
    # The function provides options for approval, rejection, copying data to clipboard, or saving data to a file.
    #
    # @param opts [Hash] A hash containing various options for the menu.
    # @param required_lines [Array<String>] Lines of text or code that are subject to user approval.
    #
    # @option opts [String] :prompt_approve_block Prompt text for the approval menu.
    # @option opts [String] :prompt_yes Text for the 'Yes' choice in the menu.
    # @option opts [String] :prompt_no Text for the 'No' choice in the menu.
    # @option opts [String] :prompt_script_to_clipboard Text for the 'Copy to Clipboard' choice in the menu.
    # @option opts [String] :prompt_save_script Text for the 'Save to File' choice in the menu.
    #
    # @return [Boolean] Returns true if the user approves (selects 'Yes'), false otherwise.
    ##
    def prompt_for_user_approval(opts, required_lines)
      # Present a selection menu for user approval.
      sel = @prompt.select(opts[:prompt_approve_block], filter: true) do |menu|
        menu.default 1
        menu.choice opts[:prompt_yes], 1
        menu.choice opts[:prompt_no], 2
        menu.choice opts[:prompt_script_to_clipboard], 3
        menu.choice opts[:prompt_save_script], 4
      end

      if sel == 3
        copy_to_clipboard(required_lines)
      elsif sel == 4
        save_to_file(opts, required_lines)
      end

      sel == 1
    end

    ## insert back option at head or tail
    #
    ## Adds a back option at the head or tail of a menu
    #
    def prompt_menu_add_back(items, label)
      return items unless @options[:menu_with_back] && history_state_exist?

      state = history_state_partition(@options)
      @hs_curr = state[:unit]
      @hs_rest = state[:rest]
      @options[:menu_back_at_top] ? [label] + items : items + [label]
    end

    ## insert exit option at head or tail
    #
    def prompt_menu_add_exit(items, label)
      if @options[:menu_exit_at_top]
        (@options[:menu_with_exit] ? [label] : []) + items
      else
        items + (@options[:menu_with_exit] ? [label] : [])
      end
    end

    # :reek:UtilityFunction ### temp
    def read_configuration_file!(options, configuration_path)
      return unless File.exist?(configuration_path)

      options.merge!((YAML.load(File.open(configuration_path)) || {})
        .transform_keys(&:to_sym))
    end

    # Reads required code blocks from a temporary file specified by an environment variable.
    #
    # @return [Array<String>] An array containing the lines read from the temporary file.
    # @note Relies on the 'MDE_LINK_REQUIRED_FILE' environment variable to locate the file.
    def read_required_blocks_from_temp_file
      temp_blocks = []

      temp_blocks_file_path = ENV.fetch('MDE_LINK_REQUIRED_FILE', nil)
      return temp_blocks if temp_blocks_file_path.nil? || temp_blocks_file_path.empty?

      if File.exist?(temp_blocks_file_path)
        temp_blocks = File.readlines(temp_blocks_file_path, chomp: true)
      end

      temp_blocks
    end

    def run
      clear_required_file
      execute_block_with_error_handling(initialize_and_parse_cli_options)
      delete_required_temp_file
    rescue StandardError => err
      warn(error = "ERROR ** MarkParse.run(); #{err.inspect}")
      binding.pry if $tap_enable
      raise ArgumentError, error
    end

    def run_last_script
      filename = SavedFilesMatcher.most_recent(@options[:saved_script_folder],
                                               @options[:saved_script_glob])
      return unless filename

      saved_name_split filename
      @options[:save_executed_script] = false
      select_approve_and_execute_block({})
    end

    def save_to_file(opts, required_lines)
      write_command_file(opts.merge(save_executed_script: true),
                         required_lines)
      fout "File saved: #{@options[:saved_filespec]}"
    end

    def saved_name_split(name)
      # rubocop:disable Layout/LineLength
      mf = /#{@options[:saved_script_filename_prefix]}_(?<time>[0-9\-]+)_(?<file>.+)_,_(?<block>.+)\.sh/.match name
      # rubocop:enable Layout/LineLength
      return unless mf

      @options[:block_name] = mf[:block]
      @options[:filename] = mf[:file].gsub(FNR12, FNR11)
    end

    # Select and execute a code block from a Markdown document.
    #
    # This method allows the user to interactively select a code block from a
    # Markdown document, obtain approval, and execute the chosen block of code.
    #
    # @param call_options [Hash] Initial options for the method.
    # @param options_block [Block] Block of options to be merged with call_options.
    # @return [Nil] Returns nil if no code block is selected or an error occurs.
    def select_approve_and_execute_block(call_options, &options_block)
      opts = optsmerge(call_options, options_block)
      repeat_menu = true && !opts[:block_name].present?
      load_file = !LOAD_FILE
      default = 1

      loop do
        loop do
          opts[:back] = false
          blocks_in_file, blocks_menu, mdoc = load_file_and_prepare_menu(opts)

          unless opts[:block_name].present?
            block_name, state = wait_for_user_selection(blocks_in_file, blocks_menu, default,
                                                        opts)
            case state
            when :exit
              return nil
            when :back
              opts[:block_name] = block_name[:option]
              opts[:back] = true
            when :continue
              opts[:block_name] = block_name
            end
          end

          load_file, next_block_name = approve_and_execute_block(opts, mdoc)
          default = load_file == LOAD_FILE ? 1 : opts[:block_name]
          opts[:block_name] = next_block_name

          break if state == :continue && load_file == LOAD_FILE
          break unless repeat_menu
        end
        break if load_file != LOAD_FILE
      end
    rescue StandardError => err
      warn(error = "ERROR ** MarkParse.select_approve_and_execute_block(); #{err.inspect}")
      warn err.backtrace
      binding.pry if $tap_enable
      raise ArgumentError, error
    end

    def select_document_if_multiple(files = list_markdown_files_in_path)
      return files[0] if (count = files.count) == 1

      return unless count >= 2

      opts = options.dup
      select_option_or_exit opts[:prompt_select_md].to_s, files,
                            opts.merge(per_page: opts[:select_page_height])
    end

    # Presents a TTY prompt to select an option or exit, returns selected option or nil
    def select_option_or_exit(prompt_text, items, opts = {})
      result = select_option_with_metadata(prompt_text, items, opts)
      return unless result.fetch(:option, nil)

      result[:selected]
    end

    # Presents a TTY prompt to select an option or exit, returns metadata including option and selected
    def select_option_with_metadata(prompt_text, items, opts = {})
      selection = @prompt.select(prompt_text,
                                 prompt_menu_add_exit(
                                   prompt_menu_add_back(
                                     items,
                                     opts[:menu_option_back_name]
                                   ),
                                   opts[:menu_option_exit_name]
                                 ),
                                 opts.merge(filter: true))
      if selection == opts[:menu_option_back_name]
        { option: selection, curr: @hs_curr, rest: @hs_rest, shell: BLOCK_TYPE_LINK }
      elsif selection == opts[:menu_option_exit_name]
        { option: selection }
      else
        { selected: selection }
      end
    end

    def select_recent_output
      filename = select_option_or_exit(
        @options[:prompt_select_output].to_s,
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
        @options[:prompt_select_md].to_s,
        list_recent_scripts(
          @options[:saved_script_folder],
          @options[:saved_script_glob],
          @options[:list_count]
        ),
        @options.merge({ per_page: @options[:select_page_height] })
      )
      return if filename.nil?

      saved_name_split(filename)

      select_approve_and_execute_block({
                                         bash: true,
                                         save_executed_script: false,
                                         struct: true
                                       })
    end

    # set the title of an FCB object based on its body if it is nil or empty
    def set_fcb_title(fcb)
      return unless fcb.title.nil? || fcb.title.empty?

      fcb.title = (fcb&.body || []).join(' ').gsub(/  +/, ' ')[0..64]
    end

    def start_fenced_block(opts, line, headings, fenced_start_extended_regex)
      fcb_title_groups = line.match(fenced_start_extended_regex).named_captures.sym_keys
      rest = fcb_title_groups.fetch(:rest, '')

      fcb = FCB.new
      fcb.headings = headings
      fcb.oname = fcb.dname = fcb_title_groups.fetch(:name, '')
      fcb.shell = fcb_title_groups.fetch(:shell, '')
      fcb.title = fcb_title_groups.fetch(:name, '')
      fcb.body = []
      fcb.reqs, fcb.wraps =
        ArrayUtil.partition_by_predicate(rest.scan(/\+[^\s]+/).map do |req|
                                           req[1..-1]
                                         end) do |name|
        !name.match(Regexp.new(opts[:block_name_wrapper_match]))
      end
      fcb.call = rest.match(Regexp.new(opts[:block_calls_scan]))&.to_a&.first
      fcb.stdin = if (tn = rest.match(/<(?<type>\$)?(?<name>[A-Za-z_-]\S+)/))
                    tn.named_captures.sym_keys
                  end
      fcb.stdout = if (tn = rest.match(/>(?<type>\$)?(?<name>[A-Za-z_\-.\w]+)/))
                     tn.named_captures.sym_keys
                   end
      fcb
    end

    def tab_completions(data = menu_for_optparse)
      data.map do |item|
        "--#{item[:long_name]}" if item[:long_name]
      end.compact
    end

    def tty_prompt_without_disabled_symbol
      TTY::Prompt.new(interrupt: :exit, symbols: { cross: ' ' })
    end

    ##
    # Updates the hierarchy of document headings based on the given line and existing headings.
    # The function uses regular expressions specified in the `opts` to identify different levels of headings.
    #
    # @param line [String] The line of text to examine for heading content.
    # @param headings [Array<String>] The existing list of document headings.
    # @param opts [Hash] A hash containing options for regular expression matches for different heading levels.
    #
    # @option opts [String] :heading1_match Regular expression for matching first-level headings.
    # @option opts [String] :heading2_match Regular expression for matching second-level headings.
    # @option opts [String] :heading3_match Regular expression for matching third-level headings.
    #
    # @return [Array<String>] Updated list of headings.
    def update_document_headings(line, headings, opts)
      if (lm = line.match(Regexp.new(opts[:heading3_match])))
        [headings[0], headings[1], lm[:name]]
      elsif (lm = line.match(Regexp.new(opts[:heading2_match])))
        [headings[0], lm[:name]]
      elsif (lm = line.match(Regexp.new(opts[:heading1_match])))
        [lm[:name]]
      else
        headings
      end
    end

    ##
    # Processes an individual line within a loop, updating headings and handling fenced code blocks.
    # This function is designed to be called within a loop that iterates through each line of a document.
    #
    # @param line [String] The current line being processed.
    # @param state [Hash] The current state of the parser, including flags and data related to the processing.
    # @param opts [Hash] A hash containing various options for line and block processing.
    # @param selected_messages [Array<String>] Accumulator for lines or messages that are subject to further processing.
    # @param block [Proc] An optional block for further processing or transformation of lines.
    #
    # @option state [Array<String>] :headings Current headings to be updated based on the line.
    # @option state [Regexp] :fenced_start_and_end_regex Regular expression to match the start and end of a fenced block.
    # @option state [Boolean] :in_fenced_block Flag indicating whether the current line is inside a fenced block.
    # @option state [Object] :fcb An object representing the current fenced code block being processed.
    #
    # @option opts [Boolean] :menu_blocks_with_headings Flag indicating whether to update headings while processing.
    #
    # @return [Void] The function modifies the `state` and `selected_messages` arguments in place.
    ##
    def update_line_and_block_state(line, state, opts, selected_messages, &block)
      if opts[:menu_blocks_with_headings]
        state[:headings] =
          update_document_headings(line, state[:headings], opts)
      end

      if line.match(state[:fenced_start_and_end_regex])
        if state[:in_fenced_block]
          process_fenced_block(state[:fcb], opts, selected_messages, &block)
          state[:in_fenced_block] = false
        else
          state[:fcb] =
            start_fenced_block(opts, line, state[:headings],
                               state[:fenced_start_extended_regex])
          state[:in_fenced_block] = true
        end
      elsif state[:in_fenced_block] && state[:fcb].body
        state[:fcb].body += [line.chomp]
      else
        process_line(line, opts, selected_messages, &block)
      end
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

    ## Handles the menu interaction and returns selected block name and option state
    #
    def wait_for_user_selection(blocks_in_file, blocks_menu, default, opts)
      pt = opts[:prompt_select_block].to_s
      bm = prepare_blocks_menu(blocks_menu, opts)
      return [nil, :exit] if bm.count.zero?

      obj = select_option_with_metadata(pt, bm, opts.merge(
                                                  default: default,
                                                  per_page: opts[:select_page_height]
                                                ))
      case obj.fetch(:option, nil)
      when opts[:menu_option_exit_name]
        [nil, :exit]
      when opts[:menu_option_back_name]
        [obj, :back]
      else
        label_block = blocks_in_file.find { |fcb| fcb.dname == obj[:selected] }
        [label_block.oname, :continue]
      end
    end

    # Handles the core logic for generating the command file's metadata and content.
    def write_command_file(call_options, required_lines)
      return unless call_options[:save_executed_script]

      time_now = Time.now.utc
      opts = optsmerge call_options
      opts[:saved_script_filename] =
        SavedAsset.script_name(blockname: opts[:block_name],
                               filename: opts[:filename],
                               prefix: opts[:saved_script_filename_prefix],
                               time: time_now)

      @execute_script_filespec =
        @options[:saved_filespec] =
          File.join opts[:saved_script_folder], opts[:saved_script_filename]

      shebang = if @options[:shebang]&.present?
                  "#{@options[:shebang]} #{@options[:shell]}\n"
                else
                  ''
                end

      content = shebang +
                "# file_name: #{opts[:filename]}\n" \
                "# block_name: #{opts[:block_name]}\n" \
                "# time: #{time_now}\n" \
                "#{required_lines.flatten.join("\n")}\n"

      create_and_write_file_with_permissions(@options[:saved_filespec], content,
                                             @options[:saved_script_chmod])
    end

    def write_execution_output_to_file
      FileUtils.mkdir_p File.dirname(@options[:logged_stdout_filespec])

      ol = ["-STDOUT-\n"]
      ol += @execute_files&.fetch(EF_STDOUT, [])
      ol += ["\n-STDERR-\n"]
      ol += @execute_files&.fetch(EF_STDERR, [])
      ol += ["\n-STDIN-\n"]
      ol += @execute_files&.fetch(EF_STDIN, [])
      ol += ["\n"]
      File.write(@options[:logged_stdout_filespec], ol.join)
    end

    # Writes required code blocks to a temporary file and sets an environment variable with its path.
    #
    # @param block_name [String] The name of the block to collect code for.
    # @param opts [Hash] Additional options for collecting code.
    # @note Sets the 'MDE_LINK_REQUIRED_FILE' environment variable to the temporary file path.
    def write_required_blocks_to_temp_file(mdoc, block_name, opts = {})
      code_blocks = (read_required_blocks_from_temp_file +
                     mdoc.collect_recursively_required_code(
                       block_name,
                       opts: opts
                     )[:code]).join("\n")

      Dir::Tmpname.create(self.class.to_s) do |path|
        pp path
        File.write(path, code_blocks)
        ENV['MDE_LINK_REQUIRED_FILE'] = path
      end
    end
  end # class MarkParse
end # module MarkdownExec

if $PROGRAM_NAME == __FILE__
  require 'bundler/setup'
  Bundler.require(:default)

  require 'minitest/autorun'

  module MarkdownExec
    class TestMarkParse < Minitest::Test
      require 'mocha/minitest'

      def test_calling_execute_approved_block_calls_command_execute_with_argument_args_value
        pigeon = 'E'
        obj = { pass_args: pigeon }

        c = MarkdownExec::MarkParse.new

        # Expect that method command_execute is called with argument args having value pigeon
        c.expects(:command_execute).with(
          obj,
          '',
          args: pigeon
        )

        # Call method execute_approved_block
        c.execute_approved_block(obj, [])
      end

      def setup
        @mark_parse = MarkdownExec::MarkParse.new
      end

      def test_set_fcb_title
        # sample input and output data for testing set_fcb_title method
        input_output_data = [
          {
            input: FCB.new(title: nil, body: ["puts 'Hello, world!'"]),
            output: "puts 'Hello, world!'"
          },
          {
            input: FCB.new(title: '', body: ['def add(x, y)', '  x + y', 'end']),
            output: 'def add(x, y) x + y end'
          },
          {
            input: FCB.new(title: 'foo', body: %w[bar baz]),
            output: 'foo' # expect the title to remain unchanged
          }
        ]

        # iterate over the input and output data and
        # assert that the method sets the title as expected
        input_output_data.each do |data|
          input = data[:input]
          output = data[:output]
          @mark_parse.set_fcb_title(input)
          assert_equal output, input.title
        end
      end
    end
  end
end
