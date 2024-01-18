#!/usr/bin/env bundle exec ruby
# frozen_string_literal: true

# encoding=utf-8

require 'English'
require 'clipboard'
require 'fileutils'
require 'open3'
require 'optparse'
require 'set'
require 'shellwords'
require 'tmpdir'
require 'tty-prompt'
require 'yaml'

require_relative 'array'
require_relative 'array_util'
require_relative 'block_label'
require_relative 'block_types'
require_relative 'cached_nested_file_reader'
require_relative 'constants'
require_relative 'directory_searcher'
require_relative 'exceptions'
require_relative 'fcb'
require_relative 'filter'
require_relative 'fout'
require_relative 'hash'
require_relative 'link_history'
require_relative 'mdoc'
require_relative 'regexp'
require_relative 'string_util'

class String
  # Checks if the string is not empty.
  # @return [Boolean] Returns true if the string is not empty, false otherwise.
  def non_empty?
    !empty?
  end
end

module HashDelegatorSelf
  # def add_back_option(menu_blocks)
  #   append_chrome_block(menu_blocks, MenuState::BACK)
  # end

  # Applies an ANSI color method to a string using a specified color key.
  # The method retrieves the color method from the provided hash. If the color key
  # is not present in the hash, it uses a default color method.
  # @param string [String] The string to be colored.
  # @param color_methods [Hash] A hash where keys are color names (String/Symbol) and values are color methods.
  # @param color_key [String, Symbol] The key representing the desired color method in the color_methods hash.
  # @param default_method [String] (optional) Default color method to use if color_key is not found in color_methods. Defaults to 'plain'.
  # @return [String] The colored string.
  def apply_color_from_hash(string, color_methods, color_key, default_method: 'plain')
    color_method = color_methods.fetch(color_key, default_method).to_sym
    string.to_s.send(color_method)
  end

  # # Enhanced `apply_color_from_hash` method to support dynamic color transformations
  # # @param string [String] The string to be colored.
  # # @param color_transformations [Hash] A hash mapping color names to lambdas that apply color transformations.
  # # @param color_key [String, Symbol] The key representing the desired color transformation in the color_transformations hash.
  # # @param default_transformation [Proc] Default color transformation to use if color_key is not found in color_transformations.
  # # @return [String] The colored string.
  # def apply_color_from_hash(string, color_transformations, color_key, default_transformation: ->(str) { str })
  #   transformation = color_transformations.fetch(color_key.to_sym, default_transformation)
  #   transformation.call(string)
  # end
  # color_transformations = {
  #   red: ->(str) { "\e[31m#{str}\e[0m" },  # ANSI color code for red
  #   green: ->(str) { "\e[32m#{str}\e[0m" },  # ANSI color code for green
  #   # Add more color transformations as needed
  # }
  # string = "Hello, World!"
  # colored_string = apply_color_from_hash(string, color_transformations, :red)
  # puts colored_string  # This will print the string in red

  # Searches for the first element in a collection where the specified key matches a given value.
  # This method is particularly useful for finding a specific hash-like object within an enumerable collection.
  # If no match is found, it returns a specified default value.
  #
  # @param blocks [Enumerable] The collection of hash-like objects to search.
  # @param key [Object] The key to search for in each element of the collection.
  # @param value [Object] The value to match against each element's corresponding key value.
  # @param default [Object, nil] The default value to return if no match is found (optional).
  # @return [Object, nil] The first matching element or the default value if no match is found.
  def block_find(blocks, key, value, default = nil)
    blocks.find { |item| item[key] == value } || default
  end

  def code_merge(*bodies)
    merge_lists(*bodies)
  end

  def count_matches_in_lines(lines, regex)
    lines.count { |line| line.to_s.match(regex) }
  end

  def create_directory_for_file(file_path)
    FileUtils.mkdir_p(File.dirname(file_path))
  end

  # Creates a file at the specified path, writes the given content to it,
  # and sets file permissions if required. Handles any errors encountered during the process.
  #
  # @param file_path [String] The path where the file will be created.
  # @param content [String] The content to write into the file.
  # @param chmod_value [Integer] The file permission value to set; skips if zero.
  def create_file_and_write_string_with_permissions(file_path, content,
                                                    chmod_value)
    create_directory_for_file(file_path)
    File.write(file_path, content)
    set_file_permissions(file_path, chmod_value) unless chmod_value.zero?
  rescue StandardError
    error_handler('create_file_and_write_string_with_permissions')
  end

  # def create_temp_file
  #   Dir::Tmpname.create(self.class.to_s) { |path| path }
  # end

  # Updates the title of an FCB object from its body content if the title is nil or empty.
  def default_block_title_from_body(fcb)
    return unless fcb.title.nil? || fcb.title.empty?

    fcb.derive_title_from_body
  end

  # delete the current line if it is empty and the previous is also empty
  def delete_consecutive_blank_lines!(blocks_menu)
    blocks_menu.process_and_conditionally_delete! do |prev_item, current_item, _next_item|
      prev_item&.fetch(:chrome, nil) && !prev_item&.fetch(:oname).present? &&
        current_item&.fetch(:chrome, nil) && !current_item&.fetch(:oname).present?
    end
  end

  # # Deletes a temporary file specified by an environment variable.
  # # Checks if the file exists before attempting to delete it and clears the environment variable afterward.
  # # Any errors encountered during deletion are handled gracefully.
  # def delete_required_temp_file(temp_blocks_file_path)
  #   return if temp_blocks_file_path.nil? || temp_blocks_file_path.empty?

  #   HashDelegator.remove_file_without_standard_errors(temp_blocks_file_path)
  # end

  def error_handler(name = '', opts = {}, error: $!)
    Exceptions.error_handler(
      "HashDelegator.#{name} -- #{error}",
      opts
    )
  end

  # # DebugHelper.d ["HDmm method_name: #{method_name}", "#{first_n_caller_items 1}"]
  # def first_n_caller_items(n)
  #   call_stack = caller
  #   base_path = File.realpath('.')

  #   # Modify the call stack to remove the base path and keep only the first n items
  #   call_stack.take(n + 1)[1..].map do |line|
  #     " . #{line.sub(/^#{Regexp.escape(base_path)}\//, '')}"
  #   end.join("\n")
  # end

  # Formats and returns the execution streams (like stdin, stdout, stderr) for a given key.
  # It concatenates the array of strings found under the specified key in the run_state's files.
  #
  # @param key [Symbol] The key corresponding to the desired execution stream.
  # @return [String] A concatenated string of the execution stream's contents.
  def format_execution_streams(key, files = {})
    (files || {}).fetch(key, []).join
  end

  # Indents all lines in a given string with a specified indentation string.
  # @param body [String] A multi-line string to be indented.
  # @param indent [String] The string used for indentation (default is an empty string).
  # @return [String] A single string with each line indented as specified.
  def indent_all_lines(body, indent = nil)
    return body unless indent&.non_empty?

    body.lines.map { |line| indent + line.chomp }.join("\n")
  end

  def initialize_fcb_names(fcb)
    fcb.oname = fcb.dname = fcb.title || ''
  end

  def merge_lists(*args)
    # Filters out nil values, flattens the arrays, and ensures an empty list is returned if no valid lists are provided
    merged = args.compact.flatten
    merged.empty? ? [] : merged
  end

  def next_link_state(block_name_from_cli, was_using_cli, block_state)
    # &bsp 'next_link_state', block_name_from_cli, was_using_cli, block_state
    # Set block_name based on block_name_from_cli
    block_name = block_name_from_cli ? @cli_block_name : nil
    # &bsp 'block_name:', block_name

    # Determine the state of breaker based on was_using_cli and the block type
    breaker = !block_name && !block_name_from_cli && was_using_cli && block_state.block[:shell] == BlockType::BASH
    # &bsp 'breaker:', breaker

    # Reset block_name_from_cli if the conditions are not met
    block_name_from_cli ||= false
    # &bsp 'block_name_from_cli:', block_name_from_cli

    [block_name, block_name_from_cli, breaker]
  end

  def parse_yaml_data_from_body(body)
    body.any? ? YAML.load(body.join("\n")) : {}
  end

  # Reads required code blocks from a temporary file specified by an environment variable.
  # @return [Array<String>] Lines read from the temporary file, or an empty array if file is not found or path is empty.
  def read_required_blocks_from_temp_file(temp_blocks_file_path)
    return [] if temp_blocks_file_path.to_s.empty?

    if File.exist?(temp_blocks_file_path)
      File.readlines(
        temp_blocks_file_path, chomp: true
      )
    else
      []
    end
  end

  def remove_file_without_standard_errors(path)
    FileUtils.rm_f(path)
  end

  # Evaluates the given string as Ruby code and rescues any StandardErrors.
  # If an error occurs, it calls the error_handler method with 'safeval'.
  # @param str [String] The string to be evaluated.
  # @return [Object] The result of evaluating the string.
  def safeval(str)
    eval(str)
  rescue StandardError # catches NameError, StandardError
    error_handler('safeval')
  end

  def set_file_permissions(file_path, chmod_value)
    File.chmod(chmod_value, file_path)
  end

  # Creates a TTY prompt with custom settings. Specifically, it disables the default 'cross' symbol and
  # defines a lambda function to handle interrupts.
  # @return [TTY::Prompt] A new TTY::Prompt instance with specified configurations.
  def tty_prompt_without_disabled_symbol
    TTY::Prompt.new(
      interrupt: lambda {
        puts
        raise TTY::Reader::InputInterrupt
      },
      symbols: { cross: ' ' }
    )
  end

  # Updates the attributes of the given fcb object and conditionally yields to a block.
  # It initializes fcb names and sets the default block title from fcb's body.
  # If the fcb has a body and meets certain conditions, it yields to the given block.
  #
  # @param fcb [Object] The fcb object whose attributes are to be updated.
  # @param selected_messages [Array<Symbol>] A list of message types to determine if yielding is applicable.
  # @param block [Block] An optional block to yield to if conditions are met.
  def update_menu_attrib_yield_selected(fcb, selected_messages, configuration = {}, &block)
    initialize_fcb_names(fcb)
    return unless fcb.body

    default_block_title_from_body(fcb)
    MarkdownExec::Filter.yield_to_block_if_applicable(fcb, selected_messages, configuration,
                                                      &block)
  end

  # Writes the provided code blocks to a file.
  # @param code_blocks [String] Code blocks to write into the file.
  def write_code_to_file(content, path)
    File.write(path, content)
  end

  def write_execution_output_to_file(files, filespec)
    FileUtils.mkdir_p File.dirname(filespec)

    File.write(
      filespec,
      ["-STDOUT-\n",
       format_execution_streams(ExecutionStreams::StdOut, files),
       "-STDERR-\n",
       format_execution_streams(ExecutionStreams::StdErr, files),
       "-STDIN-\n",
       format_execution_streams(ExecutionStreams::StdIn, files),
       "\n"].join
    )
  end

  # Yields a line as a new block if the selected message type includes :line.
  # @param [String] line The line to be processed.
  # @param [Array<Symbol>] selected_messages A list of message types to check.
  # @param [Proc] block The block to be called with the line data.
  def yield_line_if_selected(line, selected_messages, &block)
    return unless block && selected_messages.include?(:line)

    block.call(:line, MarkdownExec::FCB.new(body: [line]))
  end
end
### require_relative 'hash_delegator_self'

# This module provides methods for compacting and converting data structures.
module CompactionHelpers
  # Converts an array of key-value pairs into a hash, applying compaction to the values.
  # Each value is processed by `compact_hash` to remove ineligible elements.
  #
  # @param array [Array] The array of key-value pairs to be converted.
  # @return [Hash] A hash with keys from the array and compacted values.
  def compact_and_convert_array_to_hash(array)
    array.transform_values do |value|
      compact_hash(value)
    end
  end

  # Compacts a hash by removing ineligible elements.
  # It filters out nil, empty arrays, empty hashes, and empty strings from its values.
  # It also removes entries with :random as the key.
  #
  # @param hash [Hash] The hash to be compacted.
  # @return [Hash] A compacted version of the input hash.
  def compact_hash(hash)
    hash.map do |key, value|
      next if value_ineligible?(value) || key == :random

      [key, value]
    end.compact.to_h
  end

  # Converts a hash into another hash with indexed keys, applying compaction to the values.
  # The keys are indexed, and the values are compacted using `compact_and_convert_array_to_hash`.
  #
  # @param hash [Hash] The hash to be converted and compacted.
  # @return [Hash] A hash with indexed keys and the compacted original values.
  def compact_and_index_hash(hash)
    compact_and_convert_array_to_hash(hash.map.with_index do |value, index|
                                        [index, value]
                                      end.to_h)
  end

  private

  # Determines if a value is ineligible for inclusion in a compacted hash.
  # Ineligible values are nil, empty arrays, empty hashes, and empty strings.
  #
  # @param value [Object] The value to be checked.
  # @return [Boolean] True if the value is ineligible, false otherwise.
  def value_ineligible?(value)
    [nil, [], {}, ''].include?(value)
  end
end

module MarkdownExec
  class DebugHelper
    # Class-level variable to store history of printed messages
    @@printed_messages = Set.new

    # Outputs a warning message only once for a unique set of inputs
    #
    # @param str [Array] Variable number of arguments to be printed
    def self.d(*str)
      return if @@printed_messages.include?(str)

      warn(*str)
      @@printed_messages.add(str)
    end
  end

  class HashDelegator
    attr_accessor :most_recent_loaded_filename, :pass_args, :run_state

    extend HashDelegatorSelf
    include CompactionHelpers

    def initialize(delegate_object = {})
      @delegate_object = delegate_object
      @prompt = HashDelegator.tty_prompt_without_disabled_symbol

      @most_recent_loaded_filename = nil
      @pass_args = []
      @run_state = OpenStruct.new(
        link_history: []
      )
      @link_history = LinkHistory.new
      @fout = FOut.new(@delegate_object) ### slice only relevant keys

      @process_mutex = Mutex.new
      @process_cv = ConditionVariable.new
    end

    # private

    #   def [](key)
    #     @delegate_object[key]
    #   end

    #   def []=(key, value)
    #     @delegate_object[key] = value
    #   end

    # Modifies the provided menu blocks array by adding 'Back' and 'Exit' options,
    # along with initial and final dividers, based on the delegate object's configuration.
    #
    # @param menu_blocks [Array] The array of menu block elements to be modified.
    def add_menu_chrome_blocks!(menu_blocks, link_state)
      return unless @delegate_object[:menu_link_format].present?

      if @delegate_object[:menu_with_inherited_lines]
        add_inherited_lines(menu_blocks,
                            link_state)
      end

      # back before exit
      add_back_option(menu_blocks) if should_add_back_option?

      # exit after other options
      add_exit_option(menu_blocks) if @delegate_object[:menu_with_exit]

      add_dividers(menu_blocks)
    end

    private

    def add_back_option(menu_blocks)
      append_chrome_block(menu_blocks, MenuState::BACK)
    end

    def add_dividers(menu_blocks)
      append_divider(menu_blocks, :initial)
      append_divider(menu_blocks, :final)
    end

    def add_exit_option(menu_blocks)
      append_chrome_block(menu_blocks, MenuState::EXIT)
    end

    def add_inherited_lines(menu_blocks, link_state)
      append_inherited_lines(menu_blocks, link_state)
    end

    public

    # Appends a chrome block, which is a menu option for Back or Exit
    #
    # @param all_blocks [Array] The current blocks in the menu
    # @param type [Symbol] The type of chrome block to add (:back or :exit)
    def append_chrome_block(menu_blocks, type)
      case type
      when MenuState::BACK
        history_state_partition
        option_name = @delegate_object[:menu_option_back_name]
        insert_at_top = @delegate_object[:menu_back_at_top]
      when MenuState::EXIT
        option_name = @delegate_object[:menu_option_exit_name]
        insert_at_top = @delegate_object[:menu_exit_at_top]
      end

      formatted_name = format(@delegate_object[:menu_link_format],
                              HashDelegator.safeval(option_name))
      chrome_block = FCB.new(
        chrome: true,
        dname: HashDelegator.new(@delegate_object).string_send_color(
          formatted_name, :menu_link_color
        ),
        oname: formatted_name
      )

      if insert_at_top
        menu_blocks.unshift(chrome_block)
      else
        menu_blocks.push(chrome_block)
      end
    end

    # Appends a formatted divider to the specified position in a menu block array.
    # The method checks for the presence of formatting options before appending.
    #
    # @param menu_blocks [Array] The array of menu block elements.
    # @param position [Symbol] The position to insert the divider (:initial or :final).
    def append_inherited_lines(menu_blocks, link_state, position: top)
      return unless link_state.inherited_lines.present?

      insert_at_top = @delegate_object[:menu_inherited_lines_at_top]
      chrome_blocks = link_state.inherited_lines.map do |line|
        formatted = format(@delegate_object[:menu_inherited_lines_format],
                           { line: line })
        FCB.new(
          chrome: true,
          disabled: '',
          dname: HashDelegator.new(@delegate_object).string_send_color(
            formatted, :menu_inherited_lines_color
          ),
          oname: formatted
        )
      end

      if insert_at_top
        # Prepend an array of elements to the beginning
        menu_blocks.unshift(*chrome_blocks)
      else
        # Append an array of elements to the end
        menu_blocks.concat(chrome_blocks)
      end
    rescue StandardError
      HashDelegator.error_handler('append_inherited_lines')
    end

    # Appends a formatted divider to the specified position in a menu block array.
    # The method checks for the presence of formatting options before appending.
    #
    # @param menu_blocks [Array] The array of menu block elements.
    # @param position [Symbol] The position to insert the divider (:initial or :final).
    def append_divider(menu_blocks, position)
      return unless divider_formatting_present?(position)

      divider = create_divider(position)
      position == :initial ? menu_blocks.unshift(divider) : menu_blocks.push(divider)
    end

    # private

    # Applies shell color options to the given string if applicable.
    #
    # @param name [String] The name to potentially colorize.
    # @param shell_color_option [Symbol, nil] The shell color option to apply.
    # @return [String] The colorized or original name string.
    def apply_shell_color_option(name, shell_color_option)
      if shell_color_option && @delegate_object[shell_color_option].present?
        string_send_color(name, shell_color_option)
      else
        name
      end
    end

    # private

    # Iterates through nested files to collect various types of blocks, including dividers, tasks, and others.
    # The method categorizes blocks based on their type and processes them accordingly.
    #
    # @return [Array<FCB>] An array of FCB objects representing the blocks.
    def blocks_from_nested_files
      blocks = []
      iter_blocks_from_nested_files do |btype, fcb|
        process_block_based_on_type(blocks, btype, fcb)
      end
      # &bc  'blocks.count:', blocks.count
      blocks
    rescue StandardError
      HashDelegator.error_handler('blocks_from_nested_files')
    end

    # private

    def calc_logged_stdout_filename
      return unless @delegate_object[:saved_stdout_folder]

      @delegate_object[:logged_stdout_filename] =
        SavedAsset.stdout_name(blockname: @delegate_object[:block_name],
                               filename: File.basename(@delegate_object[:filename],
                                                       '.*'),
                               prefix: @delegate_object[:logged_stdout_filename_prefix],
                               time: Time.now.utc)

      @logged_stdout_filespec =
        @delegate_object[:logged_stdout_filespec] =
          File.join @delegate_object[:saved_stdout_folder],
                    @delegate_object[:logged_stdout_filename]
    end

    def cfile
      @cfile ||= CachedNestedFileReader.new(
        import_pattern: @delegate_object.fetch(:import_pattern) #, "^ *@import +(?<name>.+?) *$")
      )
    end

    # Check whether the document exists and is readable
    def check_file_existence(filename)
      unless filename&.present?
        @fout.fout 'No blocks found.'
        return false
      end

      unless File.exist? filename
        @fout.fout 'Document is missing.'
        return false
      end
      true
    end

    # Collects required code lines based on the selected block and the delegate object's configuration.
    # If the block type is VARS, it also sets environment variables based on the block's content.
    #
    # @param mdoc [YourMDocClass] An instance of the MDoc class.
    # @param selected [Hash] The selected block.
    # @return [Array<String>] Required code blocks as an array of lines.
    def collect_required_code_lines(mdoc, selected, link_state = LinkState.new, block_source:)
      set_environment_variables_for_block(selected) if selected[:shell] == BlockType::VARS

      required = mdoc.collect_recursively_required_code(
        selected[:nickname] || selected[:oname],
        label_format_above: @delegate_object[:shell_code_label_format_above],
        label_format_below: @delegate_object[:shell_code_label_format_below],
        block_source: block_source
      )
      dependencies = (link_state&.inherited_dependencies || {}).merge(required[:dependencies] || {})
      required[:unmet_dependencies] =
        (required[:unmet_dependencies] || []) - (link_state&.inherited_block_names || [])
      if required[:unmet_dependencies].present?
        ### filter against link_state.inherited_block_names

        warn format_and_highlight_dependencies(dependencies,
                                               highlight: required[:unmet_dependencies])
        runtime_exception(:runtime_exception_error_level,
                          'unmet_dependencies, flag: runtime_exception_error_level',
                          required[:unmet_dependencies])
      elsif true
        warn format_and_highlight_dependencies(dependencies,
                                               highlight: [@delegate_object[:block_name]])
      end

      HashDelegator.code_merge(link_state&.inherited_lines, required[:code])
    end

    def command_execute(command, args: [])
      @run_state.files = Hash.new([])
      @run_state.options = @delegate_object
      @run_state.started_at = Time.now.utc

      if @delegate_object[:execute_in_own_window] &&
         @delegate_object[:execute_command_format].present? &&
         @run_state.saved_filespec.present?
        @run_state.in_own_window = true
        system(
          format(
            @delegate_object[:execute_command_format],
            {
              batch_index: @run_state.batch_index,
              batch_random: @run_state.batch_random,
              block_name: @delegate_object[:block_name],
              document_filename: File.basename(@delegate_object[:filename]),
              document_filespec: @delegate_object[:filename],
              home: Dir.pwd,
              output_filename: File.basename(@delegate_object[:logged_stdout_filespec]),
              output_filespec: @delegate_object[:logged_stdout_filespec],
              script_filename: @run_state.saved_filespec,
              script_filespec: File.join(Dir.pwd, @run_state.saved_filespec),
              started_at: @run_state.started_at.strftime(
                @delegate_object[:execute_command_title_time_format]
              )
            }
          )
        )

      else
        @run_state.in_own_window = false
        Open3.popen3(@delegate_object[:shell],
                     '-c', command,
                     @delegate_object[:filename],
                     *args) do |stdin, stdout, stderr, exec_thr|
          handle_stream(stdout, ExecutionStreams::StdOut) do |line|
            yield nil, line, nil, exec_thr if block_given?
          end
          handle_stream(stderr, ExecutionStreams::StdErr) do |line|
            yield nil, nil, line, exec_thr if block_given?
          end

          in_thr = handle_stream($stdin, ExecutionStreams::StdIn) do |line|
            stdin.puts(line)
            yield line, nil, nil, exec_thr if block_given?
          end

          wait_for_stream_processing
          exec_thr.join
          sleep 0.1
          in_thr.kill if in_thr&.alive?
        end
      end

      @run_state.completed_at = Time.now.utc
    rescue Errno::ENOENT => err
      # Handle ENOENT error
      @run_state.aborted_at = Time.now.utc
      @run_state.error_message = err.message
      @run_state.error = err
      @run_state.files[ExecutionStreams::StdErr] += [@run_state.error_message]
      @fout.fout "Error ENOENT: #{err.inspect}"
    rescue SignalException => err
      # Handle SignalException
      @run_state.aborted_at = Time.now.utc
      @run_state.error_message = 'SIGTERM'
      @run_state.error = err
      @run_state.files[ExecutionStreams::StdErr] += [@run_state.error_message]
      @fout.fout "Error ENOENT: #{err.inspect}"
    end

    def load_cli_or_user_selected_block(all_blocks, menu_blocks, default)
      if @delegate_object[:block_name].present?
        block = all_blocks.find do |item|
          item[:oname] == @delegate_object[:block_name]
        end&.merge(block_name_from_ui: false)
      else
        block_state = wait_for_user_selected_block(all_blocks, menu_blocks,
                                                   default)
        block = block_state.block&.merge(block_name_from_ui: true)
        state = block_state.state
      end

      SelectedBlockMenuState.new(block, state)
    rescue StandardError
      HashDelegator.error_handler('load_cli_or_user_selected_block')
    end

    # This method is responsible for handling the execution of generic blocks in a markdown document.
    # It collects the required code lines from the document and, depending on the configuration,
    # may display the code for user approval before execution. It then executes the approved block.
    #
    # @param mdoc [Object] The markdown document object containing code blocks.
    # @param selected [Hash] The selected item from the menu to be executed.
    # @return [LoadFileLinkState] An object indicating whether to load the next block or reuse the current one.
    def compile_execute_and_trigger_reuse(mdoc, selected, link_state = nil, block_source:)
      required_lines = collect_required_code_lines(mdoc, selected, link_state,
                                                   block_source: block_source)
      output_or_approval = @delegate_object[:output_script] || @delegate_object[:user_must_approve]
      display_required_code(required_lines) if output_or_approval
      allow_execution = if @delegate_object[:user_must_approve]
                          prompt_for_user_approval(required_lines, selected)
                        else
                          true
                        end

      execute_required_lines(required_lines, selected) if allow_execution

      link_state.block_name = nil
      LoadFileLinkState.new(LoadFile::Reuse, link_state)
    end

    def copy_to_clipboard(required_lines)
      text = required_lines.flatten.join($INPUT_RECORD_SEPARATOR)
      Clipboard.copy(text)
      @fout.fout "Clipboard updated: #{required_lines.count} blocks," \
                 " #{required_lines.flatten.count} lines," \
                 " #{text.length} characters"
    end

    # Counts the number of fenced code blocks in a file.
    # It reads lines from a file and counts occurrences of lines matching the fenced block regex.
    # Assumes that every fenced block starts and ends with a distinct line (hence divided by 2).
    #
    # @return [Integer] The count of fenced code blocks in the file.
    def count_blocks_in_filename
      regex = Regexp.new(@delegate_object[:fenced_start_and_end_regex])
      lines = cfile.readlines(@delegate_object[:filename],
                              import_paths: @delegate_object[:import_paths]&.split(':'))
      HashDelegator.count_matches_in_lines(lines, regex) / 2
    end

    ##
    # Creates and adds a formatted block to the blocks array based on the provided match and format options.
    # @param blocks [Array] The array of blocks to add the new block to.
    # @param match_data [MatchData] The match data containing named captures for formatting.
    # @param format_option [String] The format string to be used for the new block.
    # @param color_method [Symbol] The color method to apply to the block's display name.
    def create_and_add_chrome_block(blocks, match_data, format_option,
                                    color_method)
      oname = format(format_option,
                     match_data.named_captures.transform_keys(&:to_sym))
      blocks.push FCB.new(
        chrome: true,
        disabled: '',
        dname: oname.send(color_method),
        oname: oname
      )
    end

    ##
    # Processes lines within the file and converts them into blocks if they match certain criteria.
    # @param blocks [Array] The array to append new blocks to.
    # @param fcb [FCB] The file control block being processed.
    # @param opts [Hash] Options containing configuration for line processing.
    # @param use_chrome [Boolean] Indicates if the chrome styling should be applied.
    def create_and_add_chrome_blocks(blocks, fcb)
      match_criteria = [
        { color: :menu_heading1_color, format: :menu_heading1_format, match: :heading1_match },
        { color: :menu_heading2_color, format: :menu_heading2_format, match: :heading2_match },
        { color: :menu_heading3_color, format: :menu_heading3_format, match: :heading3_match },
        { color: :menu_divider_color,  format: :menu_divider_format,  match: :menu_divider_match },
        { color: :menu_note_color,     format: :menu_note_format,     match: :menu_note_match },
        { color: :menu_task_color,     format: :menu_task_format,     match: :menu_task_match }
      ]
      # rubocop:enable Style/UnlessElse
      match_criteria.each do |criteria|
        unless @delegate_object[criteria[:match]].present? &&
               (mbody = fcb.body[0].match @delegate_object[criteria[:match]])
          next
        end

        create_and_add_chrome_block(blocks, mbody, @delegate_object[criteria[:format]],
                                    @delegate_object[criteria[:color]].to_sym)
        break
      end
    end

    def create_divider(position)
      divider_key = position == :initial ? :menu_initial_divider : :menu_final_divider
      oname = format(@delegate_object[:menu_divider_format],
                     HashDelegator.safeval(@delegate_object[divider_key]))

      FCB.new(
        chrome: true,
        disabled: '',
        dname: string_send_color(oname, :menu_divider_color),
        oname: oname
      )
    end

    # Prompts user if named block is the same as the prior execution.
    #
    # @return [Boolean] Execute the named block.
    def debounce_allows
      return true unless @delegate_object[:debounce_execution]

      # filter block if selected in menu
      return true if @run_state.block_name_from_cli

      # return false if @prior_execution_block == @delegate_object[:block_name]
      if @prior_execution_block == @delegate_object[:block_name]
        return @allowed_execution_block == @prior_execution_block || prompt_approve_repeat
      end

      @prior_execution_block = @delegate_object[:block_name]
      @allowed_execution_block = nil
      true
    end

    def debounce_reset
      @prior_execution_block = nil
    end

    # Determines the state of a selected block in the menu based on the selected option.
    # It categorizes the selected option into either EXIT, BACK, or CONTINUE state.
    #
    # @param selected_option [Hash] The selected menu option.
    # @return [SelectedBlockMenuState] An object representing the state of the selected block.
    def determine_block_state(selected_option)
      option_name = selected_option.fetch(:oname, nil)
      if option_name == menu_chrome_formatted_option(:menu_option_exit_name)
        return SelectedBlockMenuState.new(nil,
                                          MenuState::EXIT)
      end
      if option_name == menu_chrome_formatted_option(:menu_option_back_name)
        return SelectedBlockMenuState.new(selected_option,
                                          MenuState::BACK)
      end

      SelectedBlockMenuState.new(selected_option, MenuState::CONTINUE)
    end

    # Displays the required lines of code with color formatting for the preview section.
    # It wraps the code lines between a formatted header and tail.
    #
    # @param required_lines [Array<String>] The lines of code to be displayed.
    def display_required_code(required_lines)
      output_color_formatted(:script_preview_head,
                             :script_preview_frame_color)
      required_lines.each { |cb| @fout.fout cb }
      output_color_formatted(:script_preview_tail,
                             :script_preview_frame_color)
    end

    def divider_formatting_present?(position)
      divider_key = position == :initial ? :menu_initial_divider : :menu_final_divider
      @delegate_object[:menu_divider_format].present? && @delegate_object[divider_key].present?
    end

    def do_save_execution_output
      return unless @delegate_object[:save_execution_output]
      return if @run_state.in_own_window

      HashDelegator.write_execution_output_to_file(@run_state.files,
                                                   @delegate_object[:logged_stdout_filespec])
    end

    # Executes a block of code that has been approved for execution.
    # It sets the script block name, writes command files if required, and handles the execution
    # including output formatting and summarization.
    #
    # @param required_lines [Array<String>] The lines of code to be executed.
    # @param selected [FCB] The selected functional code block object.
    def execute_required_lines(required_lines = [], selected = FCB.new)
      write_command_file(required_lines, selected) if @delegate_object[:save_executed_script]
      calc_logged_stdout_filename
      format_and_execute_command(required_lines)
      post_execution_process
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
    def execute_shell_type(selected, mdoc, link_state = LinkState.new,
                           block_source:)
      if selected.fetch(:shell, '') == BlockType::LINK
        debounce_reset
        push_link_history_and_trigger_load(selected.fetch(:body, ''), mdoc, selected,
                                           link_state)

      elsif @menu_user_clicked_back_link
        debounce_reset
        pop_link_history_and_trigger_load

      elsif selected[:shell] == BlockType::OPTS
        debounce_reset
        options_state = read_show_options_and_trigger_reuse(selected, link_state)
        @menu_base_options.merge!(options_state.options)
        @delegate_object.merge!(options_state.options)
        options_state.load_file_link_state

      elsif debounce_allows
        compile_execute_and_trigger_reuse(mdoc, selected, link_state,
                                          block_source: block_source)
      else
        LoadFileLinkState.new(LoadFile::Reuse, link_state)
      end
    end

    # Retrieves a specific data symbol from the delegate object, converts it to a string,
    # and applies a color style based on the specified color symbol.
    #
    # @param default [String] The default value if the data symbol is not found.
    # @param data_sym [Symbol] The symbol key to fetch data from the delegate object.
    # @param color_sym [Symbol] The symbol key to fetch the color option for styling.
    # @return [String] The color-styled string.
    def fetch_color(default: '',
                    data_sym: :execution_report_preview_head,
                    color_sym: :execution_report_preview_frame_color)
      data_string = @delegate_object.fetch(data_sym, default).to_s
      string_send_color(data_string, color_sym)
    end

    def format_and_execute_command(lines)
      formatted_command = lines.flatten.join("\n")
      @fout.fout fetch_color(data_sym: :script_execution_head,
                             color_sym: :script_execution_frame_color)
      command_execute(formatted_command, args: @pass_args)
      @fout.fout fetch_color(data_sym: :script_execution_tail,
                             color_sym: :script_execution_frame_color)
    end

    # Formats a string based on a given context and applies color styling to it.
    # It retrieves format and color information from the delegate object and processes accordingly.
    #
    # @param default [String] The default value if the format symbol is not found (unused in current implementation).
    # @param context [Hash] Contextual data used for string formatting.
    # @param format_sym [Symbol] Symbol key to fetch the format string from the delegate object.
    # @param color_sym [Symbol] Symbol key to fetch the color option for string styling.
    # @return [String] The formatted and color-styled string.
    def format_references_send_color(default: '', context: {},
                                     format_sym: :output_execution_label_format,
                                     color_sym: :execution_report_preview_frame_color)
      formatted_string = format(@delegate_object.fetch(format_sym, ''),
                                context).to_s
      string_send_color(formatted_string, color_sym)
    end

    # Processes a block to generate its summary, modifying its attributes based on various matching criteria.
    # It handles special formatting for bash blocks, extracting and setting properties like call, stdin, stdout, and dname.
    #
    # @param fcb [Object] An object representing a functional code block.
    # @return [Object] The modified functional code block with updated summary attributes.
    def get_block_summary(fcb)
      return fcb unless @delegate_object[:bash]

      fcb.call = fcb.title.match(Regexp.new(@delegate_object[:block_calls_scan]))&.fetch(1, nil)
      titlexcall = fcb.call ? fcb.title.sub("%#{fcb.call}", '') : fcb.title
      bm = extract_named_captures_from_option(titlexcall,
                                              @delegate_object[:block_name_match])

      fcb.stdin = extract_named_captures_from_option(titlexcall,
                                                     @delegate_object[:block_stdin_scan])
      fcb.stdout = extract_named_captures_from_option(titlexcall,
                                                      @delegate_object[:block_stdout_scan])

      shell_color_option = SHELL_COLOR_OPTIONS[fcb[:shell]]

      if @delegate_object[:block_name_nick_match].present? && fcb.oname =~ Regexp.new(@delegate_object[:block_name_nick_match])
        fcb.nickname = $~[0]
        fcb.title = fcb.oname = format_multiline_body_as_title(fcb.body)
      else
        fcb.title = fcb.oname = bm && bm[1] ? bm[:title] : titlexcall
      end

      fcb.dname = HashDelegator.indent_all_lines(
        apply_shell_color_option(fcb.oname, shell_color_option),
        fcb.fetch(:indent, nil)
      )
      fcb
    end

    # Formats multiline body content as a title string.
    # indents all but first line with two spaces so it displays correctly in menu
    # @param body_lines [Array<String>] The lines of body content.
    # @return [String] Formatted title.
    def format_multiline_body_as_title(body_lines)
      body_lines.map.with_index do |line, index|
        index.zero? ? line : "  #{line}"
      end.join("\n") + "\n"
    end

    # Updates the delegate object's state based on the provided block state.
    # It sets the block name and determines if the user clicked the back link in the menu.
    #
    # @param block_state [Object] An object representing the state of a block in the menu.
    def handle_back_or_continue(block_state)
      return if block_state.nil?
      unless [MenuState::BACK,
              MenuState::CONTINUE].include?(block_state.state)
        return
      end

      @delegate_object[:block_name] = block_state.block[:oname]
      @menu_user_clicked_back_link = block_state.state == MenuState::BACK
    end

    def handle_stream(stream, file_type, swap: false)
      @process_mutex.synchronize do
        Thread.new do
          stream.each_line do |line|
            line.strip!
            @run_state.files[file_type] << line

            if @delegate_object[:output_stdout]
              # print line
              puts line
            end

            yield line if block_given?
          end
        rescue IOError
          # Handle IOError
        ensure
          @process_cv.signal
        end
      end
    end

    # Initializes variables for regex and other states
    def initial_state
      {
        fenced_start_and_end_regex: Regexp.new(@delegate_object.fetch(
                                                 :fenced_start_and_end_regex, '^(?<indent> *)`{3,}'
                                               )),
        fenced_start_extended_regex: Regexp.new(@delegate_object.fetch(
                                                  :fenced_start_and_end_regex, '^(?<indent> *)`{3,}'
                                                )),
        fcb: MarkdownExec::FCB.new,
        in_fenced_block: false,
        headings: []
      }
    end

    # Iterates through blocks in a file, applying the provided block to each line.
    # The iteration only occurs if the file exists.
    # @yield [Symbol] :filter Yields to obtain selected messages for processing.
    def iter_blocks_from_nested_files(&block)
      return unless check_file_existence(@delegate_object[:filename])

      state = initial_state
      selected_messages = yield :filter
      cfile.readlines(@delegate_object[:filename],
                      import_paths: @delegate_object[:import_paths]&.split(':')).each do |nested_line|
        if nested_line
          update_line_and_block_state(nested_line, state, selected_messages,
                                      &block)
        end
      end
    end

    def link_block_data_eval(link_state, code_lines, selected, link_block_data)
      all_code = HashDelegator.code_merge(link_state&.inherited_lines, code_lines)

      if link_block_data.fetch(LinkDataKeys::Exec, false)
        @run_state.files = Hash.new([])
        output_lines = []

        Open3.popen3(
          @delegate_object[:shell],
          '-c', all_code.join("\n")
        ) do |stdin, stdout, stderr, _exec_thr|
          handle_stream(stdout, ExecutionStreams::StdOut) do |line|
            output_lines.push(line)
          end
          handle_stream(stderr, ExecutionStreams::StdErr) do |line|
            output_lines.push(line)
          end

          in_thr = handle_stream($stdin, ExecutionStreams::StdIn) do |line|
            stdin.puts(line)
          end

          wait_for_stream_processing
          sleep 0.1
          in_thr.kill if in_thr&.alive?
        end

        ## select output_lines that look like assignment or match other specs
        #
        output_lines = process_string_array(
          output_lines,
          begin_pattern: @delegate_object.fetch(:output_assignment_begin, nil),
          end_pattern: @delegate_object.fetch(:output_assignment_end, nil),
          scan1: @delegate_object.fetch(:output_assignment_match, nil),
          format1: @delegate_object.fetch(:output_assignment_format, nil)
        )

      else
        output_lines = `#{all_code.join("\n")}`.split("\n")
      end

      unless output_lines
        HashDelegator.error_handler('all_code eval output_lines is nil', { abort: true })
      end

      label_format_above = @delegate_object[:shell_code_label_format_above]
      label_format_below = @delegate_object[:shell_code_label_format_below]
      block_source = { document_filename: link_state&.document_filename }

      [label_format_above && format(label_format_above,
                                    block_source.merge({ block_name: selected[:oname] }))] +
        output_lines.map do |line|
          re = Regexp.new(link_block_data.fetch('pattern', '(?<line>.*)'))
          re.gsub_format(line, link_block_data.fetch('format', '%{line}')) if re =~ line
        end.compact +
        [label_format_below && format(label_format_below,
                                      block_source.merge({ block_name: selected[:oname] }))]
    end

    def link_history_push_and_next(
      curr_block_name:, curr_document_filename:,
      inherited_block_names:, inherited_dependencies:, inherited_lines:,
      next_block_name:, next_document_filename:,
      next_load_file:
    )
      @link_history.push(
        LinkState.new(
          block_name: curr_block_name,
          document_filename: curr_document_filename,
          inherited_block_names: inherited_block_names,
          inherited_dependencies: inherited_dependencies,
          inherited_lines: inherited_lines
        )
      )
      LoadFileLinkState.new(
        next_load_file,
        LinkState.new(
          block_name: next_block_name,
          document_filename: next_document_filename,
          inherited_block_names: inherited_block_names,
          inherited_dependencies: inherited_dependencies,
          inherited_lines: inherited_lines
        )
      )
    end

    # Loads auto blocks based on delegate object settings and updates if new filename is detected.
    # Executes a specified block once per filename.
    # @param all_blocks [Array] Array of all block elements.
    # @return [Boolean, nil] True if values were modified, nil otherwise.
    def load_auto_blocks(all_blocks)
      block_name = @delegate_object[:document_load_opts_block_name]
      unless block_name.present? && @most_recent_loaded_filename != @delegate_object[:filename]
        return
      end

      block = HashDelegator.block_find(all_blocks, :oname, block_name)
      return unless block

      options_state = read_show_options_and_trigger_reuse(block)
      @menu_base_options.merge!(options_state.options)
      @delegate_object.merge!(options_state.options)

      @most_recent_loaded_filename = @delegate_object[:filename]
      true
    end

    def mdoc_and_blocks_from_nested_files
      menu_blocks = blocks_from_nested_files
      mdoc = MDoc.new(menu_blocks) do |nopts|
        @delegate_object.merge!(nopts)
      end
      [menu_blocks, mdoc]
    end

    ## Handles the file loading and returns the blocks in the file and MDoc instance
    #
    def mdoc_menu_and_blocks_from_nested_files(link_state)
      all_blocks, mdoc = mdoc_and_blocks_from_nested_files

      # recreate menu with new options
      #
      all_blocks, mdoc = mdoc_and_blocks_from_nested_files if load_auto_blocks(all_blocks)

      menu_blocks = mdoc.fcbs_per_options(@delegate_object)
      add_menu_chrome_blocks!(menu_blocks, link_state)
      ### compress empty lines
      HashDelegator.delete_consecutive_blank_lines!(menu_blocks) if true
      [all_blocks, menu_blocks, mdoc]
    end

    # Formats and optionally colors a menu option based on delegate object's configuration.
    # @param option_symbol [Symbol] The symbol key for the menu option in the delegate object.
    # @return [String] The formatted and possibly colored value of the menu option.
    def menu_chrome_colored_option(option_symbol = :menu_option_back_name)
      formatted_option = menu_chrome_formatted_option(option_symbol)
      return formatted_option unless @delegate_object[:menu_chrome_color]

      string_send_color(formatted_option, :menu_chrome_color)
    end

    # Formats a menu option based on the delegate object's configuration.
    # It safely evaluates the value of the option and optionally formats it.
    # @param option_symbol [Symbol] The symbol key for the menu option in the delegate object.
    # @return [String] The formatted or original value of the menu option.
    def menu_chrome_formatted_option(option_symbol = :menu_option_back_name)
      option_value = HashDelegator.safeval(@delegate_object.fetch(option_symbol, ''))

      if @delegate_object[:menu_chrome_format]
        format(@delegate_object[:menu_chrome_format], option_value)
      else
        option_value
      end
    end

    # If a method is missing, treat it as a key for the @delegate_object.
    def method_missing(method_name, *args, &block)
      if @delegate_object.respond_to?(method_name)
        @delegate_object.send(method_name, *args, &block)
      elsif method_name.to_s.end_with?('=') && args.size == 1
        @delegate_object[method_name.to_s.chop.to_sym] = args.first
      else
        @delegate_object[method_name]
        # super
      end
    end

    def shift_cli_argument
      return true unless @menu_base_options[:input_cli_rest].present?

      @cli_block_name = @menu_base_options[:input_cli_rest].shift
      false
    end

    def output_color_formatted(data_sym, color_sym)
      formatted_string = string_send_color(@delegate_object[data_sym],
                                           color_sym)
      @fout.fout formatted_string
    end

    def output_execution_result
      @fout.fout fetch_color(data_sym: :execution_report_preview_head,
                             color_sym: :execution_report_preview_frame_color)
      [
        ['Block', @run_state.script_block_name],
        ['Command', ([MarkdownExec::BIN_NAME, @delegate_object[:filename]] +
                     (@run_state.link_history.map { |item|
                        item[:block_name]
                      }) +
                     [@run_state.script_block_name]).join(' ')],
        ['Script', @run_state.saved_filespec],
        ['StdOut', @delegate_object[:logged_stdout_filespec]]
      ].each do |label, value|
        next unless value

        output_labeled_value(label, value, DISPLAY_LEVEL_ADMIN)
      end
      @fout.fout fetch_color(data_sym: :execution_report_preview_tail,
                             color_sym: :execution_report_preview_frame_color)
    end

    def output_execution_summary
      return unless @delegate_object[:output_execution_summary]

      fout_section 'summary', {
        execute_aborted_at: @run_state.aborted_at,
        execute_completed_at: @run_state.completed_at,
        execute_error: @run_state.error,
        execute_error_message: @run_state.error_message,
        execute_files: @run_state.files,
        execute_options: @run_state.options,
        execute_started_at: @run_state.started_at,
        script_block_name: @run_state.script_block_name,
        saved_filespec: @run_state.saved_filespec
      }
    end

    def output_labeled_value(label, value, level)
      @fout.lout format_references_send_color(
        context: { name: string_send_color(label, :output_execution_label_name_color),
                   value: string_send_color(value.to_s,
                                            :output_execution_label_value_color) },
        format_sym: :output_execution_label_format
      ), level: level
    end

    def pop_add_current_code_to_head_and_trigger_load(link_state, block_names, code_lines,
                                                      dependencies, selected)
      pop = @link_history.pop # updatable
      if pop.document_filename
        next_state = LinkState.new(
          block_name: pop.block_name,
          document_filename: pop.document_filename,
          inherited_block_names:
           (pop.inherited_block_names + block_names).sort.uniq,
          inherited_dependencies:
           dependencies.merge(pop.inherited_dependencies || {}), ### merge, not replace, key data
          inherited_lines:
           HashDelegator.code_merge(pop.inherited_lines, code_lines)
        )
        @link_history.push(next_state)

        next_state.block_name = nil
        LoadFileLinkState.new(LoadFile::Load, next_state)
      else
        # no history exists; must have been called independently => retain script
        link_history_push_and_next(
          curr_block_name: selected[:oname],
          curr_document_filename: @delegate_object[:filename],
          inherited_block_names: ((link_state&.inherited_block_names || []) + block_names).sort.uniq,
          inherited_dependencies: (link_state&.inherited_dependencies || {}).merge(dependencies || {}), ### merge, not replace, key data
          inherited_lines: HashDelegator.code_merge(link_state&.inherited_lines, code_lines),
          next_block_name: '', # not link_block_data['block'] || ''
          next_document_filename: @delegate_object[:filename], # not next_document_filename
          next_load_file: LoadFile::Reuse # not next_document_filename == @delegate_object[:filename] ? LoadFile::Reuse : LoadFile::Load
        )
        # LoadFileLinkState.new(LoadFile::Reuse, link_state)
      end
    end

    # This method handles the back-link operation in the Markdown execution context.
    # It updates the history state and prepares to load the next block.
    #
    # @return [LoadFileLinkState] An object indicating the action to load the next block.
    def pop_link_history_and_trigger_load
      pop = @link_history.pop
      peek = @link_history.peek
      LoadFileLinkState.new(LoadFile::Load, LinkState.new(
                                              document_filename: pop.document_filename,
                                              inherited_block_names: peek.inherited_block_names,
                                              inherited_dependencies: peek.inherited_dependencies,
                                              inherited_lines: peek.inherited_lines
                                            ))
    end

    def post_execution_process
      do_save_execution_output
      output_execution_summary
      output_execution_result
    end

    # Prepare the blocks menu by adding labels and other necessary details.
    #
    # @param all_blocks [Array<Hash>] The list of blocks from the file.
    # @param opts [Hash] The options hash.
    # @return [Array<Hash>] The updated blocks menu.
    def prepare_blocks_menu(menu_blocks)
      menu_blocks.map do |fcb|
        next if Filter.prepared_not_in_menu?(@delegate_object, fcb,
                                             %i[block_name_include_match block_name_wrapper_match])

        fcb.merge!(
          name: fcb.dname,
          label: BlockLabel.make(
            body: fcb[:body],
            filename: @delegate_object[:filename],
            headings: fcb.fetch(:headings, []),
            menu_blocks_with_docname: @delegate_object[:menu_blocks_with_docname],
            menu_blocks_with_headings: @delegate_object[:menu_blocks_with_headings],
            text: fcb[:text],
            title: fcb[:title]
          )
        )
        fcb.to_h
      end.compact
    end

    def print_formatted_option(key, value)
      formatted_str = format(@delegate_object[:menu_opts_set_format],
                             { key: key, value: value })
      print string_send_color(formatted_str, :menu_opts_set_color)
    end

    # private

    def process_block_based_on_type(blocks, btype, fcb)
      case btype
      when :blocks
        blocks.push(get_block_summary(fcb))
      when :filter
        %i[blocks line]
      when :line
        create_and_add_chrome_blocks(blocks, fcb) unless @delegate_object[:no_chrome]
      end
    end

    def process_string_array(arr, begin_pattern: nil, end_pattern: nil, scan1: nil,
                             format1: nil)
      in_block = !begin_pattern.present?
      collected_lines = []

      arr.each do |line|
        if in_block
          if end_pattern.present? && line.match?(end_pattern)
            in_block = false
          elsif scan1.present?
            if format1.present?
              caps = extract_named_captures_from_option(line, scan1)
              if caps
                formatted = format(format1, caps)
                collected_lines << formatted
              end
            else
              caps = line.match(scan1)
              if caps
                formatted = caps[0]
                collected_lines << formatted
              end
            end
          else
            collected_lines << line
          end
        elsif begin_pattern.present? && line.match?(begin_pattern)
          in_block = true
        end
      end

      collected_lines
    end

    def prompt_approve_repeat
      sel = @prompt.select(
        string_send_color(@delegate_object[:prompt_debounce],
                          :prompt_color_after_script_execution),
        default: @delegate_object[:prompt_no],
        filter: true,
        quiet: true
      ) do |menu|
        menu.choice @delegate_object[:prompt_yes]
        menu.choice @delegate_object[:prompt_no]
        menu.choice @delegate_object[:prompt_uninterrupted]
      end
      return false if sel == @delegate_object[:prompt_no]
      return true if sel == @delegate_object[:prompt_yes]

      @allowed_execution_block = @prior_execution_block
      true
    rescue TTY::Reader::InputInterrupt
      exit 1
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
    def prompt_for_user_approval(required_lines, selected)
      # Present a selection menu for user approval.
      sel = @prompt.select(
        string_send_color(@delegate_object[:prompt_approve_block],
                          :prompt_color_after_script_execution),
        filter: true
      ) do |menu|
        # sel = @prompt.select(@delegate_object[:prompt_approve_block], filter: true) do |menu|
        menu.default MenuOptions::YES
        menu.choice @delegate_object[:prompt_yes], MenuOptions::YES
        menu.choice @delegate_object[:prompt_no], MenuOptions::NO
        menu.choice @delegate_object[:prompt_script_to_clipboard],
                    MenuOptions::SCRIPT_TO_CLIPBOARD
        menu.choice @delegate_object[:prompt_save_script],
                    MenuOptions::SAVE_SCRIPT
      end

      if sel == MenuOptions::SCRIPT_TO_CLIPBOARD
        copy_to_clipboard(required_lines)
      elsif sel == MenuOptions::SAVE_SCRIPT
        save_to_file(required_lines, selected)
      end

      sel == MenuOptions::YES
    rescue TTY::Reader::InputInterrupt
      exit 1
    end

    def prompt_select_continue
      sel = @prompt.select(
        string_send_color(@delegate_object[:prompt_after_script_execution],
                          :prompt_color_after_script_execution),
        filter: true,
        quiet: true
      ) do |menu|
        menu.choice @delegate_object[:prompt_yes]
        menu.choice @delegate_object[:prompt_exit]
      end
      sel == @delegate_object[:prompt_exit] ? MenuState::EXIT : MenuState::CONTINUE
    rescue TTY::Reader::InputInterrupt
      exit 1
    end

    # public

    # Handles the processing of a link block in Markdown Execution.
    # It loads YAML data from the link_block_body content, pushes the state to history,
    # sets environment variables, and decides on the next block to load.
    #
    # @param link_block_body [Array<String>] The body content as an array of strings.
    # @param mdoc [Object] Markdown document object.
    # @param selected [FCB] Selected code block.
    # @return [LoadFileLinkState] Object indicating the next action for file loading.
    def push_link_history_and_trigger_load(link_block_body, mdoc, selected,
                                           link_state = LinkState.new)
      link_block_data = HashDelegator.parse_yaml_data_from_body(link_block_body)

      # load key and values from link block into current environment
      #
      (link_block_data['vars'] || []).each do |(key, value)|
        ENV[key] = value.to_s
      end

      ## collect blocks specified by block
      #
      if mdoc
        code_info = mdoc.collect_recursively_required_code(
          selected[:oname],
          label_format_above: @delegate_object[:shell_code_label_format_above],
          label_format_below: @delegate_object[:shell_code_label_format_below],
          block_source: { document_filename: link_state.document_filename }
        )
        code_lines = code_info[:code]
        block_names = code_info[:block_names]
        dependencies = code_info[:dependencies]
      else
        block_names = []
        code_lines = []
        dependencies = {}
      end
      next_document_filename = link_block_data['file'] || @delegate_object[:filename]

      ## append blocks loaded per LinkDataKeys::Load
      #
      if (load_filespec = link_block_data.fetch(LinkDataKeys::Load, '')).present?
        code_lines += File.readlines(load_filespec, chomp: true)
      end

      # if an eval link block, evaluate code_lines and return its standard output
      #
      if link_block_data.fetch(LinkDataKeys::Eval,
                               false) || link_block_data.fetch(LinkDataKeys::Exec, false)
        code_lines = link_block_data_eval(link_state, code_lines, selected, link_block_data)
      end

      if link_block_data[LinkDataKeys::Return]
        pop_add_current_code_to_head_and_trigger_load(link_state, block_names, code_lines,
                                                      dependencies, selected)

      else
        link_history_push_and_next(
          curr_block_name: selected[:oname],
          curr_document_filename: @delegate_object[:filename],
          inherited_block_names: ((link_state&.inherited_block_names || []) + block_names).sort.uniq,
          inherited_dependencies: (link_state&.inherited_dependencies || {}).merge(dependencies || {}), ### merge, not replace, key data
          inherited_lines: HashDelegator.code_merge(link_state&.inherited_lines, code_lines),
          next_block_name: link_block_data['block'] || '',
          next_document_filename: next_document_filename,
          next_load_file: next_document_filename == @delegate_object[:filename] ? LoadFile::Reuse : LoadFile::Load
        )
      end
    end

    def runtime_exception(exception_sym, name, items)
      if @delegate_object[exception_sym] != 0
        data = { name: name, detail: items.join(', ') }
        warn(
          format(
            @delegate_object.fetch(:exception_format_name, "\n%{name}"),
            data
          ).send(@delegate_object.fetch(:exception_color_name, :red)) +
          format(
            @delegate_object.fetch(:exception_format_detail, " - %{detail}\n"),
            data
          ).send(@delegate_object.fetch(:exception_color_detail, :yellow))
        )
      end
      return unless (@delegate_object[exception_sym]).positive?

      exit @delegate_object[exception_sym]
    end

    def save_to_file(required_lines, selected)
      write_command_file(required_lines, selected)
      @fout.fout "File saved: #{@run_state.saved_filespec}"
    end

    # Select and execute a code block from a Markdown document.
    #
    # This method allows the user to interactively select a code block from a
    # Markdown document, obtain approval, and execute the chosen block of code.
    #
    # @return [Nil] Returns nil if no code block is selected or an error occurs.
    def document_menu_loop
      @menu_base_options = @delegate_object
      link_state = LinkState.new(
        block_name: @delegate_object[:block_name],
        document_filename: @delegate_object[:filename]
      )
      @run_state.block_name_from_cli = link_state.block_name.present?
      @cli_block_name = link_state.block_name
      now_using_cli = @run_state.block_name_from_cli
      menu_default_dname = nil

      @run_state.batch_random = Random.new.rand
      @run_state.batch_index = 0

      loop do
        @run_state.batch_index += 1
        @run_state.in_own_window = false

        # &bsp 'loop', block_name_from_cli, @cli_block_name
        @run_state.block_name_from_cli, now_using_cli, blocks_in_file, menu_blocks, mdoc = \
          set_delobj_menu_loop_vars(@run_state.block_name_from_cli, now_using_cli, link_state)

        # cli or user selection
        #
        block_state = load_cli_or_user_selected_block(blocks_in_file, menu_blocks,
                                                      menu_default_dname)
        # &bsp '@run_state.block_name_from_cli:',@run_state.block_name_from_cli
        if !block_state
          HashDelegator.error_handler('block_state missing', { abort: true })
        elsif block_state.state == MenuState::EXIT
          # &bsp 'load_cli_or_user_selected_block -> break'
          break
        end

        dump_and_warn_block_state(block_state.block)
        link_state, menu_default_dname = exec_bash_next_state(block_state.block, mdoc,
                                                              link_state)
        if prompt_user_exit(@run_state.block_name_from_cli, block_state.block)
          # &bsp 'prompt_user_exit -> break'
          break
        end

        link_state.block_name, @run_state.block_name_from_cli, cli_break = \
          HashDelegator.next_link_state(!shift_cli_argument, now_using_cli, block_state)

        if !block_state.block[:block_name_from_ui] && cli_break
          # &bsp '!block_name_from_ui + cli_break -> break'
          break
        end
      end
    rescue StandardError
      HashDelegator.error_handler('document_menu_loop',
                                  { abort: true })
    end

    def exec_bash_next_state(block_state_block, mdoc, link_state)
      lfls = execute_shell_type(
        block_state_block,
        mdoc,
        link_state,
        block_source: { document_filename: @delegate_object[:filename] }
      )

      # if the same menu is being displayed, collect the display name of the selected menu item for use as the default item
      [lfls.link_state,
       lfls.load_file == LoadFile::Load ? nil : block_state_block[:dname]]
    end

    def set_delobj_menu_loop_vars(block_name_from_cli, now_using_cli, link_state)
      block_name_from_cli, now_using_cli = \
        manage_cli_selection_state(block_name_from_cli, now_using_cli, link_state)
      set_delob_filename_block_name(link_state, block_name_from_cli)

      # update @delegate_object and @menu_base_options in auto_load
      #
      blocks_in_file, menu_blocks, mdoc = mdoc_menu_and_blocks_from_nested_files(link_state)
      dump_delobj(blocks_in_file, menu_blocks, link_state)

      [block_name_from_cli, now_using_cli, blocks_in_file, menu_blocks, mdoc]
    end

    # user prompt to exit if the menu will be displayed again
    #
    def prompt_user_exit(block_name_from_cli, block_state_block)
      !block_name_from_cli &&
        block_state_block[:shell] == BlockType::BASH &&
        @delegate_object[:pause_after_script_execution] &&
        prompt_select_continue == MenuState::EXIT
    end

    def manage_cli_selection_state(block_name_from_cli, now_using_cli, link_state)
      if block_name_from_cli && @cli_block_name == @menu_base_options[:menu_persist_block_name]
        # &bsp 'pause cli control, allow user to select block'
        block_name_from_cli = false
        now_using_cli = false
        @menu_base_options[:block_name] = \
          @delegate_object[:block_name] = \
            link_state.block_name = \
              @cli_block_name = nil
      end

      @delegate_object = @menu_base_options.dup
      @menu_user_clicked_back_link = false
      [block_name_from_cli, now_using_cli]
    end

    # Update the block name in the link state and delegate object.
    #
    # This method updates the block name based on whether it was specified
    # through the CLI or derived from the link state.
    #
    # @param link_state [LinkState] The current link state object.
    # @param block_name_from_cli [Boolean] Indicates if the block name is from CLI.
    def set_delob_filename_block_name(link_state, block_name_from_cli)
      @delegate_object[:filename] = link_state.document_filename
      link_state.block_name = @delegate_object[:block_name] =
        block_name_from_cli ? @cli_block_name : link_state.block_name
    end

    # Outputs warnings based on the delegate object's configuration
    #
    # @param delegate_object [Hash] The delegate object containing configuration flags.
    # @param blocks_in_file [Hash] Hash of blocks present in the file.
    # @param menu_blocks [Hash] Hash of menu blocks.
    # @param link_state [LinkState] Current state of the link.
    def dump_delobj(blocks_in_file, menu_blocks, link_state)
      if @delegate_object[:dump_delegate_object]
        warn format_and_highlight_hash(@delegate_object, label: '@delegate_object')
      end

      if @delegate_object[:dump_blocks_in_file]
        warn format_and_highlight_dependencies(compact_and_index_hash(blocks_in_file),
                                               label: 'blocks_in_file')
      end

      if @delegate_object[:dump_menu_blocks]
        warn format_and_highlight_dependencies(compact_and_index_hash(menu_blocks),
                                               label: 'menu_blocks')
      end

      return unless @delegate_object[:dump_inherited_lines]

      warn format_and_highlight_lines(link_state.inherited_lines, label: 'inherited_lines')
    end

    def dump_and_warn_block_state(block_state_block)
      if block_state_block.nil?
        Exceptions.warn_format("Block not found -- name: #{@delegate_object[:block_name]}",
                               { abort: true })
      end

      return unless @delegate_object[:dump_selected_block]

      warn block_state_block.to_yaml.sub(/^(?:---\n)?/, "Block:\n")
    end

    # Presents a TTY prompt to select an option or exit, returns metadata including option and selected
    def select_option_with_metadata(prompt_text, names, opts = {})
      selection = @prompt.select(prompt_text,
                                 names,
                                 opts.merge(filter: true))

      item = if names.first.instance_of?(String)
               { dname: selection }
             else
               names.find { |item| item[:dname] == selection }
             end
      unless item
        HashDelegator.error_handler('select_option_with_metadata', error: 'menu item not found')
        exit 1
      end

      item.merge(
        if selection == menu_chrome_colored_option(:menu_option_back_name)
          { option: selection, shell: BlockType::LINK }
        elsif selection == menu_chrome_colored_option(:menu_option_exit_name)
          { option: selection }
        else
          { selected: selection }
        end
      )
    rescue TTY::Reader::InputInterrupt
      exit 1
    rescue StandardError
      HashDelegator.error_handler('select_option_with_metadata')
    end

    def set_environment_variables_for_block(selected)
      YAML.load(selected[:body].join("\n"))&.each do |key, value|
        ENV[key] = value.to_s
        next unless @delegate_object[:menu_vars_set_format].present?

        formatted_string = format(@delegate_object[:menu_vars_set_format],
                                  { key: key, value: value })
        print string_send_color(formatted_string, :menu_vars_set_color)
      end
    end

    def should_add_back_option?
      @delegate_object[:menu_with_back] && @link_history.prior_state_exist?
    end

    # Initializes a new fenced code block (FCB) object based on the provided line and heading information.
    # @param line [String] The line initiating the fenced block.
    # @param headings [Array<String>] Current headings hierarchy.
    # @param fenced_start_extended_regex [Regexp] Regular expression to identify fenced block start.
    # @return [MarkdownExec::FCB] A new FCB instance with the parsed attributes.
    def start_fenced_block(line, headings, fenced_start_extended_regex)
      fcb_title_groups = line.match(fenced_start_extended_regex).named_captures.sym_keys
      rest = fcb_title_groups.fetch(:rest, '')
      reqs, wraps =
        ArrayUtil.partition_by_predicate(rest.scan(/\+[^\s]+/).map do |req|
                                           req[1..-1]
                                         end) do |name|
        !name.match(Regexp.new(@delegate_object[:block_name_wrapper_match]))
      end

      dname = oname = title = ''
      nickname = nil
      if @delegate_object[:block_name_nick_match].present? && oname =~ Regexp.new(@delegate_object[:block_name_nick_match])
        nickname = $~[0]
      else
        dname = oname = title = fcb_title_groups.fetch(:name, '')
      end

      MarkdownExec::FCB.new(
        body: [],
        call: rest.match(Regexp.new(@delegate_object[:block_calls_scan]))&.to_a&.first,
        dname: dname,
        headings: headings,
        indent: fcb_title_groups.fetch(:indent, ''),
        nickname: nickname,
        oname: oname,
        reqs: reqs,
        shell: fcb_title_groups.fetch(:shell, ''),
        stdin: if (tn = rest.match(/<(?<type>\$)?(?<name>[A-Za-z_-]\S+)/))
                 tn.named_captures.sym_keys
               end,
        stdout: if (tn = rest.match(/>(?<type>\$)?(?<name>[A-Za-z_\-.\w]+)/))
                  tn.named_captures.sym_keys
                end,
        title: title,
        wraps: wraps
      )
    end

    # Applies a color method to a string based on the provided color symbol.
    # The color method is fetched from @delegate_object and applied to the string.
    # @param string [String] The string to which the color will be applied.
    # @param color_sym [Symbol] The symbol representing the color method.
    # @param default [String] Default color method to use if color_sym is not found in @delegate_object.
    # @return [String] The string with the applied color method.
    def string_send_color(string, color_sym)
      HashDelegator.apply_color_from_hash(string, @delegate_object, color_sym)
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
    def update_line_and_block_state(nested_line, state, selected_messages,
                                    &block)
      line = nested_line.to_s
      if line.match(@delegate_object[:fenced_start_and_end_regex])
        if state[:in_fenced_block]
          ## end of code block
          #
          HashDelegator.update_menu_attrib_yield_selected(state[:fcb], selected_messages, @delegate_object,
                                                          &block)
          state[:in_fenced_block] = false
        else
          ## start of code block
          #
          state[:fcb] =
            start_fenced_block(line, state[:headings],
                               @delegate_object[:fenced_start_extended_regex])
          state[:fcb][:depth] = nested_line[:depth]
          state[:in_fenced_block] = true
        end
      elsif state[:in_fenced_block] && state[:fcb].body
        ## add line to fenced code block
        # remove fcb indent if possible
        #
        state[:fcb].body += [
          line.chomp.sub(/^#{state[:fcb].indent}/, '')
        ]
      elsif nested_line[:depth].zero? || @delegate_object[:menu_include_imported_notes]
        # add line if it is depth 0 or option allows it
        #
        HashDelegator.yield_line_if_selected(line, selected_messages, &block)

      else
        # &bsp 'line is not recognized for block state'

      end
    end

    # Processes YAML data from the selected menu item, updating delegate objects and optionally printing formatted output.
    # @param selected [Hash] Selected item from the menu containing a YAML body.
    # @param tgt2 [Hash, nil] An optional target hash to update with YAML data.
    # @return [LoadFileLinkState] An instance indicating the next action for loading files.
    def read_show_options_and_trigger_reuse(selected, link_state = LinkState.new)
      obj = {}
      data = YAML.load(selected[:body].join("\n"))
      (data || []).each do |key, value|
        sym_key = key.to_sym
        obj[sym_key] = value

        print_formatted_option(key, value) if @delegate_object[:menu_opts_set_format].present?
      end

      link_state.block_name = nil
      OpenStruct.new(options: obj,
                     load_file_link_state: LoadFileLinkState.new(
                       LoadFile::Reuse, link_state
                     ))
    end

    def wait_for_stream_processing
      @process_mutex.synchronize do
        @process_cv.wait(@process_mutex)
      end
    end

    def wait_for_user_selected_block(all_blocks, menu_blocks, default)
      block_state = wait_for_user_selection(all_blocks, menu_blocks, default)
      handle_back_or_continue(block_state)
      block_state
    rescue StandardError
      HashDelegator.error_handler('wait_for_user_selected_block')
    end

    def wait_for_user_selection(_all_blocks, menu_blocks, default)
      prompt_title = string_send_color(
        @delegate_object[:prompt_select_block].to_s, :prompt_color_after_script_execution
      )

      block_menu = prepare_blocks_menu(menu_blocks)
      return SelectedBlockMenuState.new(nil, MenuState::EXIT) if block_menu.empty?

      # default value may not match if color is different from originating menu (opts changed while processing)
      selection_opts = if default && menu_blocks.map(&:dname).include?(default)
                         @delegate_object.merge(default: default)
                       else
                         @delegate_object
                       end

      selection_opts.merge!(per_page: @delegate_object[:select_page_height])

      selected_option = select_option_with_metadata(prompt_title, block_menu,
                                                    selection_opts)
      determine_block_state(selected_option)
    end

    # Handles the core logic for generating the command file's metadata and content.
    def write_command_file(required_lines, selected)
      return unless @delegate_object[:save_executed_script]

      time_now = Time.now.utc
      @run_state.saved_script_filename =
        SavedAsset.script_name(
          blockname: selected[:nickname] || selected[:oname],
          filename: @delegate_object[:filename],
          prefix: @delegate_object[:saved_script_filename_prefix],
          time: time_now
        )
      @run_state.saved_filespec =
        File.join(@delegate_object[:saved_script_folder],
                  @run_state.saved_script_filename)

      shebang = if @delegate_object[:shebang]&.present?
                  "#{@delegate_object[:shebang]} #{@delegate_object[:shell]}\n"
                else
                  ''
                end

      content = shebang +
                "# file_name: #{@delegate_object[:filename]}\n" \
                "# block_name: #{@delegate_object[:block_name]}\n" \
                "# time: #{time_now}\n" \
                "#{required_lines.flatten.join("\n")}\n"

      HashDelegator.create_file_and_write_string_with_permissions(
        @run_state.saved_filespec,
        content,
        @delegate_object[:saved_script_chmod]
      )
    rescue StandardError
      HashDelegator.error_handler('write_command_file')
    end

    # Writes required code blocks to a temporary file and sets an environment variable with its path.
    #
    # @param mdoc [Object] The Markdown document object.
    # @param block_name [String] The name of the block to collect code for.
    def write_required_blocks_to_file(mdoc, block_name, temp_file_path, import_filename: nil)
      c1 = if mdoc
             mdoc.collect_recursively_required_code(
               block_name,
               label_format_above: @delegate_object[:shell_code_label_format_above],
               label_format_below: @delegate_object[:shell_code_label_format_below]
             )[:code]
           else
             []
           end

      code_blocks = (HashDelegator.read_required_blocks_from_temp_file(import_filename) +
                     c1).join("\n")

      HashDelegator.write_code_to_file(code_blocks, temp_file_path)
    end
  end
end

return if $PROGRAM_NAME != __FILE__

require 'bundler/setup'
Bundler.require(:default)

require 'minitest/autorun'
require 'mocha/minitest'

module MarkdownExec
  class TestHashDelegator < Minitest::Test
    def setup
      @hd = HashDelegator.new
      @mdoc = mock('MarkdownDocument')
    end

    def test_calling_execute_required_lines_calls_command_execute_with_argument_args_value
      pigeon = 'E'
      obj = {
        output_execution_label_format: '',
        output_execution_label_name_color: 'plain',
        output_execution_label_value_color: 'plain'
      }

      c = MarkdownExec::HashDelegator.new(obj)
      c.pass_args = pigeon

      # Expect that method opts_command_execute is called with argument args having value pigeon
      c.expects(:command_execute).with(
        '',
        args: pigeon
      )

      # Call method opts_execute_required_lines
      c.execute_required_lines
    end

    # Test case for empty body
    def test_push_link_history_and_trigger_load_with_empty_body
      assert_equal LoadFile::Reuse,
                   @hd.push_link_history_and_trigger_load([], nil, FCB.new).load_file
    end

    # Test case for non-empty body without 'file' key
    def test_push_link_history_and_trigger_load_without_file_key
      body = ["vars:\n  KEY: VALUE"]
      assert_equal LoadFile::Reuse,
                   @hd.push_link_history_and_trigger_load(body, nil, FCB.new).load_file
    end

    # Test case for non-empty body with 'file' key
    def test_push_link_history_and_trigger_load_with_file_key
      body = ["file: sample_file\nblock: sample_block\nvars:\n  KEY: VALUE"]
      expected_result = LoadFileLinkState.new(LoadFile::Load,
                                              LinkState.new(block_name: 'sample_block',
                                                            document_filename: 'sample_file',
                                                            inherited_dependencies: {},
                                                            inherited_lines: []))
      assert_equal expected_result,
                   @hd.push_link_history_and_trigger_load(body, nil, FCB.new(block_name: 'sample_block',
                                                                             filename: 'sample_file'))
    end

    def test_indent_all_lines_with_indent
      body = "Line 1\nLine 2"
      indent = '  ' # Two spaces
      expected_result = "  Line 1\n  Line 2"
      assert_equal expected_result, HashDelegator.indent_all_lines(body, indent)
    end

    def test_indent_all_lines_without_indent
      body = "Line 1\nLine 2"
      indent = nil

      assert_equal body, HashDelegator.indent_all_lines(body, indent)
    end

    def test_indent_all_lines_with_empty_indent
      body = "Line 1\nLine 2"
      indent = ''

      assert_equal body, HashDelegator.indent_all_lines(body, indent)
    end

    def test_safeval_successful_evaluation
      assert_equal 4, HashDelegator.safeval('2 + 2')
    end

    def test_safeval_rescue_from_error
      HashDelegator.stubs(:error_handler).with('safeval')
      assert_nil HashDelegator.safeval('invalid code')
    end

    def test_set_fcb_title
      # sample input and output data for testing default_block_title_from_body method
      input_output_data = [
        {
          input: MarkdownExec::FCB.new(title: nil,
                                       body: ["puts 'Hello, world!'"]),
          output: "puts 'Hello, world!'"
        },
        {
          input: MarkdownExec::FCB.new(title: '',
                                       body: ['def add(x, y)',
                                              '  x + y', 'end']),
          output: "def add(x, y)\n    x + y\n  end\n"
        },
        {
          input: MarkdownExec::FCB.new(title: 'foo', body: %w[bar baz]),
          output: 'foo' # expect the title to remain unchanged
        }
      ]

      # iterate over the input and output data and
      # assert that the method sets the title as expected
      input_output_data.each do |data|
        input = data[:input]
        output = data[:output]
        HashDelegator.default_block_title_from_body(input)
        assert_equal output, input.title
      end
    end

    class TestHashDelegatorAppendDivider < Minitest::Test
      def setup
        @hd = HashDelegator.new
        @hd.instance_variable_set(:@delegate_object, {
                                    menu_divider_format: 'Format',
                                    menu_initial_divider: 'Initial Divider',
                                    menu_final_divider: 'Final Divider',
                                    menu_divider_color: :color
                                  })
        @hd.stubs(:string_send_color).returns('Formatted Divider')
        HashDelegator.stubs(:safeval).returns('Safe Value')
      end

      def test_append_divider_initial
        menu_blocks = []
        @hd.append_divider(menu_blocks, :initial)

        assert_equal 1, menu_blocks.size
        assert_equal 'Formatted Divider', menu_blocks.first.dname
      end

      def test_append_divider_final
        menu_blocks = []
        @hd.append_divider(menu_blocks, :final)

        assert_equal 1, menu_blocks.size
        assert_equal 'Formatted Divider', menu_blocks.last.dname
      end

      def test_append_divider_without_format
        @hd.instance_variable_set(:@delegate_object, {})
        menu_blocks = []
        @hd.append_divider(menu_blocks, :initial)

        assert_empty menu_blocks
      end
    end

    class TestHashDelegatorBlockFind < Minitest::Test
      def setup
        @hd = HashDelegator.new
      end

      def test_block_find_with_match
        blocks = [{ key: 'value1' }, { key: 'value2' }]
        result = HashDelegator.block_find(blocks, :key, 'value1')
        assert_equal({ key: 'value1' }, result)
      end

      def test_block_find_without_match
        blocks = [{ key: 'value1' }, { key: 'value2' }]
        result = HashDelegator.block_find(blocks, :key, 'value3')
        assert_nil result
      end

      def test_block_find_with_default
        blocks = [{ key: 'value1' }, { key: 'value2' }]
        result = HashDelegator.block_find(blocks, :key, 'value3', 'default')
        assert_equal 'default', result
      end
    end

    class TestHashDelegatorBlocksFromNestedFiles < Minitest::Test
      def setup
        @hd = HashDelegator.new
        @hd.stubs(:iter_blocks_from_nested_files).yields(:blocks, FCB.new)
        @hd.stubs(:get_block_summary).returns(FCB.new)
        @hd.stubs(:create_and_add_chrome_blocks)
        @hd.instance_variable_set(:@delegate_object, {})
        HashDelegator.stubs(:error_handler)
      end

      def test_blocks_from_nested_files
        result = @hd.blocks_from_nested_files

        assert_kind_of Array, result
        assert_kind_of FCB, result.first
      end

      def test_blocks_from_nested_files_with_no_chrome
        @hd.instance_variable_set(:@delegate_object, { no_chrome: true })
        @hd.expects(:create_and_add_chrome_blocks).never

        result = @hd.blocks_from_nested_files

        assert_kind_of Array, result
      end
    end

    class TestHashDelegatorCollectRequiredCodeLines < Minitest::Test
      def setup
        @hd = HashDelegator.new
        @hd.instance_variable_set(:@delegate_object, {})
        @mdoc = mock('YourMDocClass')
        @selected = { shell: BlockType::VARS, body: ['key: value'] }
        HashDelegator.stubs(:read_required_blocks_from_temp_file).returns([])
        @hd.stubs(:string_send_color)
        @hd.stubs(:print)
      end

      def test_collect_required_code_lines_with_vars
        YAML.stubs(:load).returns({ 'key' => 'value' })
        @mdoc.stubs(:collect_recursively_required_code).returns({ code: ['code line'] })
        result = @hd.collect_required_code_lines(@mdoc, @selected, block_source: {})

        assert_equal ['code line'], result
      end
    end

    class TestHashDelegatorCommandOrUserSelectedBlock < Minitest::Test
      def setup
        @hd = HashDelegator.new
        @hd.instance_variable_set(:@delegate_object, {})
        HashDelegator.stubs(:error_handler)
        @hd.stubs(:wait_for_user_selected_block)
      end

      def test_command_selected_block
        all_blocks = [{ oname: 'block1' }, { oname: 'block2' }]
        @hd.instance_variable_set(:@delegate_object,
                                  { block_name: 'block1' })

        result = @hd.load_cli_or_user_selected_block(all_blocks, [], nil)

        assert_equal all_blocks.first.merge(block_name_from_ui: false), result.block
        assert_nil result.state
      end

      def test_user_selected_block
        block_state = SelectedBlockMenuState.new({ oname: 'block2' },
                                                 :some_state)
        @hd.stubs(:wait_for_user_selected_block).returns(block_state)

        result = @hd.load_cli_or_user_selected_block([], [], nil)

        assert_equal block_state.block.merge(block_name_from_ui: true), result.block
        assert_equal :some_state, result.state
      end
    end

    class TestHashDelegatorCountBlockInFilename < Minitest::Test
      def setup
        @hd = HashDelegator.new
        @hd.instance_variable_set(:@delegate_object,
                                  { fenced_start_and_end_regex: '^```',
                                    filename: '/path/to/file' })
        @hd.stubs(:cfile).returns(mock('cfile'))
      end

      def test_count_blocks_in_filename
        file_content = ["```ruby\n", "puts 'Hello'\n", "```\n",
                        "```python\n", "print('Hello')\n", "```\n"]
        @hd.cfile.stubs(:readlines).with('/path/to/file',
                                         import_paths: nil).returns(file_content)

        count = @hd.count_blocks_in_filename

        assert_equal 2, count
      end

      def test_count_blocks_in_filename_with_no_matches
        file_content = ["puts 'Hello'\n", "print('Hello')\n"]
        @hd.cfile.stubs(:readlines).with('/path/to/file',
                                         import_paths: nil).returns(file_content)

        count = @hd.count_blocks_in_filename

        assert_equal 0, count
      end
    end

    class TestHashDelegatorCreateAndWriteFile < Minitest::Test
      def setup
        @hd = HashDelegator.new
        HashDelegator.stubs(:error_handler)
        FileUtils.stubs(:mkdir_p)
        File.stubs(:write)
        File.stubs(:chmod)
      end

      def test_create_file_and_write_string_with_permissions
        file_path = '/path/to/file'
        content = 'sample content'
        chmod_value = 0o644

        FileUtils.expects(:mkdir_p).with('/path/to').once
        File.expects(:write).with(file_path, content).once
        File.expects(:chmod).with(chmod_value, file_path).once

        HashDelegator.create_file_and_write_string_with_permissions(file_path, content,
                                                                    chmod_value)

        assert true # Placeholder for actual test assertions
      end

      def test_create_and_write_file_without_chmod
        file_path = '/path/to/file'
        content = 'sample content'
        chmod_value = 0

        FileUtils.expects(:mkdir_p).with('/path/to').once
        File.expects(:write).with(file_path, content).once
        File.expects(:chmod).never

        HashDelegator.create_file_and_write_string_with_permissions(file_path, content,
                                                                    chmod_value)

        assert true # Placeholder for actual test assertions
      end
    end

    class TestHashDelegatorDetermineBlockState < Minitest::Test
      def setup
        @hd = HashDelegator.new
        @hd.stubs(:menu_chrome_formatted_option).returns('Formatted Option')
      end

      def test_determine_block_state_exit
        selected_option = { oname: 'Formatted Option' }
        @hd.stubs(:menu_chrome_formatted_option).with(:menu_option_exit_name).returns('Formatted Option')

        result = @hd.determine_block_state(selected_option)

        assert_equal MenuState::EXIT, result.state
        assert_nil result.block
      end

      def test_determine_block_state_back
        selected_option = { oname: 'Formatted Back Option' }
        @hd.stubs(:menu_chrome_formatted_option).with(:menu_option_back_name).returns('Formatted Back Option')
        result = @hd.determine_block_state(selected_option)

        assert_equal MenuState::BACK, result.state
        assert_equal selected_option, result.block
      end

      def test_determine_block_state_continue
        selected_option = { oname: 'Other Option' }

        result = @hd.determine_block_state(selected_option)

        assert_equal MenuState::CONTINUE, result.state
        assert_equal selected_option, result.block
      end
    end

    class TestHashDelegatorDisplayRequiredCode < Minitest::Test
      def setup
        @hd = HashDelegator.new
        @hd.instance_variable_set(:@fout, mock('fout'))
        @hd.instance_variable_set(:@delegate_object, {})
        @hd.stubs(:string_send_color)
      end

      def test_display_required_code
        required_lines = %w[line1 line2]
        @hd.instance_variable_get(:@delegate_object).stubs(:[]).with(:script_preview_head).returns('Header')
        @hd.instance_variable_get(:@delegate_object).stubs(:[]).with(:script_preview_tail).returns('Footer')
        @hd.instance_variable_get(:@fout).expects(:fout).times(4)

        @hd.display_required_code(required_lines)

        # Verifying that fout is called for each line and for header & footer
        assert true # Placeholder for actual test assertions
      end
    end

    class TestHashDelegatorFetchColor < Minitest::Test
      def setup
        @hd = HashDelegator.new
        @hd.instance_variable_set(:@delegate_object, {})
      end

      def test_fetch_color_with_valid_data
        @hd.instance_variable_get(:@delegate_object).stubs(:fetch).with(
          :execution_report_preview_head, ''
        ).returns('Data String')
        @hd.stubs(:string_send_color).with('Data String',
                                           :execution_report_preview_frame_color).returns('Colored Data String')

        result = @hd.fetch_color

        assert_equal 'Colored Data String', result
      end

      def test_fetch_color_with_missing_data
        @hd.instance_variable_get(:@delegate_object).stubs(:fetch).with(
          :execution_report_preview_head, ''
        ).returns('')
        @hd.stubs(:string_send_color).with('',
                                           :execution_report_preview_frame_color).returns('Default Colored String')

        result = @hd.fetch_color

        assert_equal 'Default Colored String', result
      end
    end

    class TestHashDelegatorFormatReferencesSendColor < Minitest::Test
      def setup
        @hd = HashDelegator.new
        @hd.instance_variable_set(:@delegate_object, {})
      end

      def test_format_references_send_color_with_valid_data
        @hd.instance_variable_get(:@delegate_object).stubs(:fetch).with(
          :output_execution_label_format, ''
        ).returns('Formatted: %{key}')
        @hd.stubs(:string_send_color).returns('Colored String')

        result = @hd.format_references_send_color(context: { key: 'value' },
                                                  color_sym: :execution_report_preview_frame_color)

        assert_equal 'Colored String', result
      end

      def test_format_references_send_color_with_missing_format
        @hd.instance_variable_get(:@delegate_object).stubs(:fetch).with(
          :output_execution_label_format, ''
        ).returns('')
        @hd.stubs(:string_send_color).returns('Default Colored String')

        result = @hd.format_references_send_color(context: { key: 'value' },
                                                  color_sym: :execution_report_preview_frame_color)

        assert_equal 'Default Colored String', result
      end
    end

    class TestHashDelegatorFormatExecutionStreams < Minitest::Test
      def setup
        @hd = HashDelegator.new
        @hd.instance_variable_set(:@run_state, mock('run_state'))
      end

      def test_format_execution_streams_with_valid_key
        result = HashDelegator.format_execution_streams(:stdout,
                                                        { stdout: %w[output1 output2] })

        assert_equal 'output1output2', result
      end

      def test_format_execution_streams_with_empty_key
        @hd.instance_variable_get(:@run_state).stubs(:files).returns({})

        result = HashDelegator.format_execution_streams(:stderr)

        assert_equal '', result
      end

      def test_format_execution_streams_with_nil_files
        @hd.instance_variable_get(:@run_state).stubs(:files).returns(nil)

        result = HashDelegator.format_execution_streams(:stdin)

        assert_equal '', result
      end
    end

    class TestHashDelegatorHandleBackLink < Minitest::Test
      def setup
        @hd = HashDelegator.new
        @hd.stubs(:history_state_pop)
      end

      def test_pop_link_history_and_trigger_load
        # Verifying that history_state_pop is called
        # @hd.expects(:history_state_pop).once

        result = @hd.pop_link_history_and_trigger_load

        # Asserting the result is an instance of LoadFileLinkState
        assert_instance_of LoadFileLinkState, result
        assert_equal LoadFile::Load, result.load_file
        assert_nil result.link_state.block_name
      end
    end

    class TestHashDelegatorHandleBlockState < Minitest::Test
      def setup
        @hd = HashDelegator.new
        @mock_block_state = mock('block_state')
      end

      def test_handle_back_or_continue_with_back
        @mock_block_state.stubs(:state).returns(MenuState::BACK)
        @mock_block_state.stubs(:block).returns({ oname: 'sample_block' })

        @hd.handle_back_or_continue(@mock_block_state)

        assert_equal 'sample_block',
                     @hd.instance_variable_get(:@delegate_object)[:block_name]
        assert @hd.instance_variable_get(:@menu_user_clicked_back_link)
      end

      def test_handle_back_or_continue_with_continue
        @mock_block_state.stubs(:state).returns(MenuState::CONTINUE)
        @mock_block_state.stubs(:block).returns({ oname: 'another_block' })

        @hd.handle_back_or_continue(@mock_block_state)

        assert_equal 'another_block',
                     @hd.instance_variable_get(:@delegate_object)[:block_name]
        refute @hd.instance_variable_get(:@menu_user_clicked_back_link)
      end

      def test_handle_back_or_continue_with_other
        @mock_block_state.stubs(:state).returns(nil) # MenuState::OTHER
        @mock_block_state.stubs(:block).returns({ oname: 'other_block' })

        @hd.handle_back_or_continue(@mock_block_state)

        assert_nil @hd.instance_variable_get(:@delegate_object)[:block_name]
        assert_nil @hd.instance_variable_get(:@menu_user_clicked_back_link)
      end
    end

    class TestHashDelegatorHandleGenericBlock < Minitest::Test
      def setup
        @hd = HashDelegator.new
        @mock_document = mock('MarkdownDocument')
        @selected_item = mock('FCB')
      end

      def test_compile_execute_and_trigger_reuse_without_user_approval
        # Mock the delegate object configuration
        @hd.instance_variable_set(:@delegate_object,
                                  { output_script: false,
                                    user_must_approve: false })

        # Test the method without user approval
        # Expectations and assertions go here
      end

      def test_compile_execute_and_trigger_reuse_with_user_approval
        # Mock the delegate object configuration
        @hd.instance_variable_set(:@delegate_object,
                                  { output_script: false,
                                    user_must_approve: true })

        # Test the method with user approval
        # Expectations and assertions go here
      end

      def test_compile_execute_and_trigger_reuse_with_output_script
        # Mock the delegate object configuration
        @hd.instance_variable_set(:@delegate_object,
                                  { output_script: true,
                                    user_must_approve: false })

        # Test the method with output script option
        # Expectations and assertions go here
      end
    end

    # require 'stringio'

    class TestHashDelegatorHandleStream < Minitest::Test
      def setup
        @hd = HashDelegator.new
        @hd.instance_variable_set(:@run_state,
                                  OpenStruct.new(files: { stdout: [] }))
        @hd.instance_variable_set(:@delegate_object,
                                  { output_stdout: true })
      end

      def test_handle_stream
        stream = StringIO.new("line 1\nline 2\n")
        file_type = :stdout

        Thread.new { @hd.handle_stream(stream, file_type) }

        @hd.wait_for_stream_processing

        assert_equal ['line 1', 'line 2'],
                     @hd.instance_variable_get(:@run_state).files[:stdout]
      end

      def test_handle_stream_with_io_error
        stream = StringIO.new("line 1\nline 2\n")
        file_type = :stdout
        stream.stubs(:each_line).raises(IOError)

        Thread.new { @hd.handle_stream(stream, file_type) }

        @hd.wait_for_stream_processing

        assert_equal [],
                     @hd.instance_variable_get(:@run_state).files[:stdout]
      end
    end

    class TestHashDelegatorIterBlocksFromNestedFiles < Minitest::Test
      def setup
        @hd = HashDelegator.new
        @hd.instance_variable_set(:@delegate_object,
                                  { filename: 'test.md' })
        @hd.stubs(:check_file_existence).with('test.md').returns(true)
        @hd.stubs(:initial_state).returns({})
        @hd.stubs(:cfile).returns(Minitest::Mock.new)
        @hd.stubs(:update_line_and_block_state)
      end

      def test_iter_blocks_from_nested_files
        @hd.cfile.expect(:readlines, ['line 1', 'line 2'], ['test.md'], import_paths: nil)
        selected_messages = ['filtered message']

        result = @hd.iter_blocks_from_nested_files { selected_messages }
        assert_equal ['line 1', 'line 2'], result

        @hd.cfile.verify
      end

      def test_iter_blocks_from_nested_files_with_no_file
        @hd.stubs(:check_file_existence).with('test.md').returns(false)

        assert_nil(@hd.iter_blocks_from_nested_files do
                     ['filtered message']
                   end)
      end
    end

    class TestHashDelegatorMenuChromeColoredOption < Minitest::Test
      def setup
        @hd = HashDelegator.new
        @hd.instance_variable_set(:@delegate_object, {
                                    menu_option_back_name: 'Back',
                                    menu_chrome_color: :red,
                                    menu_chrome_format: '-- %s --'
                                  })
        @hd.stubs(:menu_chrome_formatted_option).with(:menu_option_back_name).returns('-- Back --')
        @hd.stubs(:string_send_color).with('-- Back --',
                                           :menu_chrome_color).returns('-- Back --'.red)
      end

      def test_menu_chrome_colored_option_with_color
        assert_equal '-- Back --'.red,
                     @hd.menu_chrome_colored_option(:menu_option_back_name)
      end

      def test_menu_chrome_colored_option_without_color
        @hd.instance_variable_set(:@delegate_object,
                                  { menu_option_back_name: 'Back' })
        assert_equal '-- Back --',
                     @hd.menu_chrome_colored_option(:menu_option_back_name)
      end
    end

    class TestHashDelegatorMenuChromeFormattedOptionWithoutFormat < Minitest::Test
      def setup
        @hd = HashDelegator.new
        @hd.instance_variable_set(:@delegate_object, {
                                    menu_option_back_name: "'Back'",
                                    menu_chrome_format: '-- %s --'
                                  })
        HashDelegator.stubs(:safeval).with("'Back'").returns('Back')
      end

      def test_menu_chrome_formatted_option_with_format
        assert_equal '-- Back --',
                     @hd.menu_chrome_formatted_option(:menu_option_back_name)
      end

      def test_menu_chrome_formatted_option_without_format
        @hd.instance_variable_set(:@delegate_object,
                                  { menu_option_back_name: "'Back'" })
        assert_equal 'Back',
                     @hd.menu_chrome_formatted_option(:menu_option_back_name)
      end
    end

    class TestHashDelegatorStartFencedBlock < Minitest::Test
      def setup
        @hd = HashDelegator.new({
                                  block_name_wrapper_match: 'WRAPPER_REGEX',
                                  block_calls_scan: 'CALLS_REGEX'
                                })
      end

      def test_start_fenced_block
        line = '```fenced'
        headings = ['Heading 1']
        regex = /```(?<name>\w+)(?<rest>.*)/

        fcb = @hd.start_fenced_block(line, headings, regex)

        assert_instance_of MarkdownExec::FCB, fcb
        assert_equal headings, fcb.headings
        assert_equal 'fenced', fcb.dname
      end
    end

    class TestHashDelegatorStringSendColor < Minitest::Test
      def setup
        @hd = HashDelegator.new
        @hd.instance_variable_set(:@delegate_object,
                                  { red: 'red', green: 'green' })
      end

      def test_string_send_color
        assert_equal 'Hello'.red, @hd.string_send_color('Hello', :red)
        assert_equal 'World'.green,
                     @hd.string_send_color('World', :green)
        assert_equal 'Default'.plain,
                     @hd.string_send_color('Default', :blue)
      end
    end

    def test_yield_line_if_selected_with_line
      block_called = false
      HashDelegator.yield_line_if_selected('Test line', [:line]) do |type, content|
        block_called = true
        assert_equal :line, type
        assert_equal 'Test line', content.body[0]
      end
      assert block_called
    end

    def test_yield_line_if_selected_without_line
      block_called = false
      HashDelegator.yield_line_if_selected('Test line', [:other]) do |_|
        block_called = true
      end
      refute block_called
    end

    def test_yield_line_if_selected_without_block
      result = HashDelegator.yield_line_if_selected('Test line', [:line])
      assert_nil result
    end
  end

  class TestHashDelegatorUpdateMenuAttribYieldSelectedWithBody < Minitest::Test
    def setup
      @hd = HashDelegator.new
      @fcb = mock('Fcb')
      @fcb.stubs(:body).returns(true)
      HashDelegator.stubs(:initialize_fcb_names)
      HashDelegator.stubs(:default_block_title_from_body)
      Filter.stubs(:yield_to_block_if_applicable)
    end

    def test_update_menu_attrib_yield_selected_with_body
      HashDelegator.expects(:initialize_fcb_names).with(@fcb)
      HashDelegator.expects(:default_block_title_from_body).with(@fcb)
      Filter.expects(:yield_to_block_if_applicable).with(@fcb, [:some_message], {})

      HashDelegator.update_menu_attrib_yield_selected(@fcb, [:some_message])
    end

    def test_update_menu_attrib_yield_selected_without_body
      @fcb.stubs(:body).returns(nil)
      HashDelegator.expects(:initialize_fcb_names).with(@fcb)
      HashDelegator.update_menu_attrib_yield_selected(@fcb, [:some_message])
    end
  end

  class TestHashDelegatorWaitForUserSelectedBlock < Minitest::Test
    def setup
      @hd = HashDelegator.new
      HashDelegator.stubs(:error_handler)
    end

    def test_wait_for_user_selected_block_with_back_state
      mock_block_state = Struct.new(:state, :block).new(MenuState::BACK,
                                                        { oname: 'back_block' })
      @hd.stubs(:wait_for_user_selection).returns(mock_block_state)

      result = @hd.wait_for_user_selected_block([], ['Block 1', 'Block 2'],
                                                nil)

      assert_equal 'back_block',
                   @hd.instance_variable_get(:@delegate_object)[:block_name]
      assert @hd.instance_variable_get(:@menu_user_clicked_back_link)
      assert_equal mock_block_state, result
    end

    def test_wait_for_user_selected_block_with_continue_state
      mock_block_state = Struct.new(:state, :block).new(
        MenuState::CONTINUE, { oname: 'continue_block' }
      )
      @hd.stubs(:wait_for_user_selection).returns(mock_block_state)

      result = @hd.wait_for_user_selected_block([], ['Block 1', 'Block 2'],
                                                nil)

      assert_equal 'continue_block',
                   @hd.instance_variable_get(:@delegate_object)[:block_name]
      refute @hd.instance_variable_get(:@menu_user_clicked_back_link)
      assert_equal mock_block_state, result
    end
  end

  class TestHashDelegatorYieldToBlock < Minitest::Test
    def setup
      @hd = HashDelegator.new
      @fcb = mock('Fcb')
      MarkdownExec::Filter.stubs(:fcb_select?).returns(true)
    end

    def test_yield_to_block_if_applicable_with_correct_conditions
      block_called = false
      Filter.yield_to_block_if_applicable(@fcb, [:blocks]) do |type, fcb|
        block_called = true
        assert_equal :blocks, type
        assert_equal @fcb, fcb
      end
      assert block_called
    end

    def test_yield_to_block_if_applicable_without_block
      result = Filter.yield_to_block_if_applicable(@fcb, [:blocks])
      assert_nil result
    end

    def test_yield_to_block_if_applicable_with_incorrect_conditions
      block_called = false
      MarkdownExec::Filter.stubs(:fcb_select?).returns(false)
      Filter.yield_to_block_if_applicable(@fcb, [:non_blocks]) do |_|
        block_called = true
      end
      refute block_called
    end
  end
end # module MarkdownExec
