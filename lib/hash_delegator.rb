#!/usr/bin/env bundle exec ruby
# frozen_string_literal: true

# encoding=utf-8

require 'clipboard'
require 'English'
require 'fileutils'
require 'io/console'
require 'open3'
require 'optparse'
require 'ostruct'
require 'set'
require 'shellwords'
require 'tempfile'
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
require_relative 'namer'
require_relative 'regexp'
require_relative 'resize_terminal'
require_relative 'std_out_err_logger'
require_relative 'streams_out'
require_relative 'string_util'

$pd = false unless defined?($pd)

class String
  # Checks if the string is not empty.
  # @return [Boolean] Returns true if the string is not empty, false otherwise.
  def non_empty?
    !empty?
  end
end

module HashDelegatorSelf
  # Applies an ANSI color method to a string using a specified color key.
  # The method retrieves the color method from the provided hash. If the color key
  # is not present in the hash, it uses a default color method.
  # @param string [String] The string to be colored.
  # @param color_methods [Hash] A hash where keys are color names (String/Symbol) and values are color methods.
  # @param color_key [String, Symbol] The key representing the desired color method in the color_methods hash.
  # @param default_method [String] (optional) Default color method to use if color_key is not found in color_methods. Defaults to 'plain'.
  # @return [String] The colored string.
  def apply_color_from_hash(string, color_methods, color_key,
                            default_method: 'plain')
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

  # Searches for the first element in a collection where the specified message sent to an element matches a given value.
  # This method is particularly useful for finding a specific hash-like object within an enumerable collection.
  # If no match is found, it returns a specified default value.
  #
  # @param blocks [Enumerable] The collection of hash-like objects to search.
  # @param msg [Symbol, String] The message to send to each element of the collection.
  # @param value [Object] The value to match against the result of the message sent to each element.
  # @param default [Object, nil] The default value to return if no match is found (optional).
  # @return [Object, nil] The first matching element or the default value if no match is found.
  def block_find(blocks, msg, value, default = nil)
    blocks.find { |item| item.send(msg) == value } || default
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
      prev_item&.fetch(:chrome, nil) &&
       !(prev_item && prev_item.oname.present?) &&
       current_item&.fetch(:chrome, nil) &&
       !(current_item && current_item.oname.present?)
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

  def join_code_lines(lines)
    ((lines || []) + ['']).join("\n")
  end

  def merge_lists(*args)
    # Filters out nil values, flattens the arrays, and ensures an empty list is returned if no valid lists are provided
    merged = args.compact.flatten
    merged.empty? ? [] : merged
  end

  def next_link_state(block_name_from_cli:, was_using_cli:, block_state:,
                      block_name: nil)
    # Set block_name based on block_name_from_cli
    block_name = @cli_block_name if block_name_from_cli

    # Determine the state of breaker based on was_using_cli and the block type
    # true only when block_name is nil, block_name_from_cli is false, was_using_cli is true, and the block_state.block[:shell] equals BlockType::BASH. In all other scenarios, breaker is false.
    breaker = !block_name && !block_name_from_cli && was_using_cli && block_state.block.fetch(
      :shell, nil
    ) == BlockType::BASH

    # Reset block_name_from_cli if the conditions are not met
    block_name_from_cli ||= false

    [block_name, block_name_from_cli, breaker]
  end

  def parse_yaml_data_from_body(body)
    body.any? ? YAML.load(body.join("\n")) : {}
  rescue StandardError
    error_handler('parse_yaml_data_from_body', { abort: true })
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

  # Evaluates the given string as Ruby code within a safe context.
  # If an error occurs, it calls the error_handler method with 'safeval'.
  # @param str [String] The string to be evaluated.
  # @return [Object] The result of evaluating the string.
  def safeval(str)
    # # Restricting to evaluate only expressions
    # unless str.match?(/\A\s*\w+\s*[\+\-\*\/\=\%\&\|\<\>\!]+\s*\w+\s*\z/)
    #   error_handler('safeval') # 'Invalid expression'
    #   return
    # end

    # # Whitelisting allowed operations
    # allowed_methods = %w[+ - * / == != < > <= >= && || % & |]
    # unless allowed_methods.any? { |op| str.include?(op) }
    #   error_handler('safeval', 'Operation not allowed')
    #   return
    # end

    # # Sanitize input (example: removing potentially harmful characters)
    # str = str.gsub(/[^0-9\+\-\*\/\(\)\<\>\!\=\%\&\|]/, '')
    # Evaluate the sanitized string
    result = nil
    binding.eval("result = #{str}")

    result
  rescue StandardError # catches NameError, StandardError
    pp $!, $@
    pp "code: #{str}"
    error_handler('safeval')
    exit 1
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
  def update_menu_attrib_yield_selected(fcb:, messages:, configuration: {},
                                        &block)
    initialize_fcb_names(fcb)
    return unless fcb.body

    default_block_title_from_body(fcb)
    MarkdownExec::Filter.yield_to_block_if_applicable(fcb, messages, configuration,
                                                      &block)
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

module PathUtils
  # Determines if a given path is absolute or substitutes a placeholder in an expression with the path.
  # @param path [String] The input path to check or fill in.
  # @param expression [String] The expression where a wildcard '*' is replaced by the path if it's not absolute.
  # @return [String] The absolute path or the expression with the wildcard replaced by the path.
  def self.resolve_path_or_substitute(path, expression)
    if path.start_with?('/')
      path
    else
      expression.gsub('*', path)
    end
  end
end

class BashCommentFormatter
  # Formats a multi-line string into a format safe for use in Bash comments.
  def self.format_comment(input_string)
    return '# ' if input_string.nil?
    return '# ' if input_string.empty?

    formatted = input_string.split("\n").map do |line|
      "# #{line.gsub('#', '\#')}"
    end
    formatted.join("\n")
  end
  # # fit oname in single bash comment
  # def oname_for_bash_comment(oname)
  #   oname.gsub("\n", ' ~ ').gsub(/  +/, ' ')
  # end
end

class StringWrapper
  attr_reader :width, :left_margin, :right_margin, :indent, :fill_margin

  # Initializes the StringWrapper with the given options.
  #
  # @param width [Integer] the maximum width of each line
  # @param left_margin [Integer] the number of spaces for the left margin
  # @param right_margin [Integer] the number of spaces for the right margin
  # @param indent [Integer] the number of spaces to indent all but the first line
  # @param fill_margin [Boolean] whether to fill the left margin with spaces
  def initialize(
    width:,
    fill_margin: false,
    first_indent: '',
    indent_space: '  ',
    left_margin: 0,
    margin_char: ' ',
    rest_indent: '',
    right_margin: 0
  )
    @fill_margin = fill_margin
    @first_indent = first_indent
    @indent = indent
    @indent_space = indent_space
    @rest_indent = rest_indent
    @right_margin = right_margin
    @width = width

    @margin_space = fill_margin ? (margin_char * left_margin) : ''
    @left_margin = @margin_space.length
  end

  # Wraps the given text according to the specified options.
  #
  # @param text [String] the text to wrap
  # @return [String] the wrapped text
  def wrap(text)
    text = text.dup if text.frozen?
    max_line_length = width - left_margin - right_margin - @indent_space.length
    lines = []
    current_line = String.new

    words = text.split
    words.each.with_index do |word, index|
      trial_length = word.length
      trial_length += @first_indent.length if index.zero?
      if index != 0
        trial_length += current_line.length + 1 + @rest_indent.length
      end
      if trial_length > max_line_length && (words.count != 0)
        lines << current_line
        current_line = word
        current_line = current_line.dup if current_line.frozen?
      else
        current_line << ' ' unless current_line.empty?
        current_line << word
      end
    end
    lines << current_line unless current_line.empty?

    lines.map.with_index do |line, index|
      @margin_space + if index.zero?
                        @first_indent
                      else
                        @rest_indent
                      end + line
    end
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

  class HashDelegatorParent
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
    def add_menu_chrome_blocks!(menu_blocks:, link_state:)
      return unless @delegate_object[:menu_link_format].present?

      if @delegate_object[:menu_with_inherited_lines]
        add_inherited_lines(menu_blocks: menu_blocks,
                            link_state: link_state)
      end

      # back before exit
      add_back_option(menu_blocks: menu_blocks) if should_add_back_option?

      # exit after other options
      if @delegate_object[:menu_with_exit]
        add_exit_option(menu_blocks: menu_blocks)
      end

      add_dividers(menu_blocks: menu_blocks)
    end

    private

    def add_back_option(menu_blocks:)
      append_chrome_block(menu_blocks: menu_blocks, menu_state: MenuState::BACK)
    end

    def add_dividers(menu_blocks:)
      append_divider(menu_blocks: menu_blocks, position: :initial)
      append_divider(menu_blocks: menu_blocks, position: :final)
    end

    def add_exit_option(menu_blocks:)
      append_chrome_block(menu_blocks: menu_blocks, menu_state: MenuState::EXIT)
    end

    def add_inherited_lines(menu_blocks:, link_state:)
      append_inherited_lines(menu_blocks: menu_blocks, link_state: link_state)
    end

    public

    # Appends a chrome block, which is a menu option for Back or Exit
    #
    # @param all_blocks [Array] The current blocks in the menu
    # @param type [Symbol] The type of chrome block to add (:back or :exit)
    def append_chrome_block(menu_blocks:, menu_state:)
      case menu_state
      when MenuState::BACK
        history_state_partition
        option_name = @delegate_object[:menu_option_back_name]
        insert_at_top = @delegate_object[:menu_back_at_top]
      when MenuState::EDIT
        option_name = @delegate_object[:menu_option_edit_name]
        insert_at_top = @delegate_object[:menu_load_at_top]
      when MenuState::EXIT
        option_name = @delegate_object[:menu_option_exit_name]
        insert_at_top = @delegate_object[:menu_exit_at_top]
      when MenuState::HISTORY
        option_name = @delegate_object[:menu_option_history_name]
        insert_at_top = @delegate_object[:menu_load_at_top]
      when MenuState::LOAD
        option_name = @delegate_object[:menu_option_load_name]
        insert_at_top = @delegate_object[:menu_load_at_top]
      when MenuState::SAVE
        option_name = @delegate_object[:menu_option_save_name]
        insert_at_top = @delegate_object[:menu_load_at_top]
      when MenuState::SHELL
        option_name = @delegate_object[:menu_option_shell_name]
        insert_at_top = @delegate_object[:menu_load_at_top]
      when MenuState::VIEW
        option_name = @delegate_object[:menu_option_view_name]
        insert_at_top = @delegate_object[:menu_load_at_top]
      else
        raise "Missing MenuState: #{menu_state}"
      end

      formatted_name = format(@delegate_object[:menu_link_format],
                              HashDelegator.safeval(option_name))
      chrome_block = FCB.new(
        chrome: true,
        dname: HashDelegator.new(@delegate_object).string_send_color(
          formatted_name, :menu_chrome_color
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
    def append_inherited_lines(menu_blocks:, link_state:, position: top)
      return unless link_state.inherited_lines_present?

      insert_at_top = @delegate_object[:menu_inherited_lines_at_top]
      chrome_blocks = link_state.inherited_lines_map do |line|
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
    def append_divider(menu_blocks:, position:)
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

    def assign_key_value_in_bash(key, value)
      if value =~ /["$\\`]/
        # requiring ShellWords to write into Bash scripts
        "#{key}=#{Shellwords.escape(value)}"
      else
        "#{key}=\"#{value}\""
      end
    end

    # private

    # Iterates through nested files to collect various types of blocks, including dividers, tasks, and others.
    # The method categorizes blocks based on their type and processes them accordingly.
    #
    # @return [Array<FCB>] An array of FCB objects representing the blocks.
    def blocks_from_nested_files
      register_console_attributes(@delegate_object)

      blocks = []
      iter_blocks_from_nested_files do |btype, fcb|
        process_block_based_on_type(blocks, btype, fcb)
      end
      # &bc  'blocks.count:', blocks.count
      blocks
    rescue StandardError
      HashDelegator.error_handler('blocks_from_nested_files')
    end

    # find a block by its original (undecorated) name or nickname (not visible in menu)
    # if matched, the block returned has properties that it is from cli and not ui
    def block_state_for_name_from_cli(block_name)
      SelectedBlockMenuState.new(
        @dml_blocks_in_file.find do |item|
          block_name == item.pub_name
        end&.merge(
          block_name_from_cli: true,
          block_name_from_ui: false
        ),
        MenuState::CONTINUE
      )
    end

    # private

    def calc_logged_stdout_filename(block_name:)
      return unless @delegate_object[:saved_stdout_folder]

      @delegate_object[:logged_stdout_filename] =
        SavedAsset.new(
          blockname: block_name,
          filename: @delegate_object[:filename],
          prefix: @delegate_object[:logged_stdout_filename_prefix],
          time: Time.now.utc,
          exts: '.out.txt',
          saved_asset_format: shell_escape_asset_format(@dml_link_state)
        ).generate_name

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
    def collect_required_code_lines(mdoc:, selected:, block_source:,
                                    link_state: LinkState.new)
      required = mdoc.collect_recursively_required_code(
        anyname: selected.pub_name,
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
      else
        warn format_and_highlight_dependencies(dependencies,
                                               highlight: [@delegate_object[:block_name]])
      end

      if selected[:shell] == BlockType::OPTS
        # body of blocks is returned as a list of lines to be read an YAML
        HashDelegator.code_merge(required[:blocks].map(&:body).flatten(1))
      else
        code_lines = selected[:shell] == BlockType::VARS ? set_environment_variables_for_block(selected) : []

        HashDelegator.code_merge(link_state&.inherited_lines,
                                 required[:code] + code_lines)
      end
    end

    def command_execute(command, args: [])
      @run_state.files = StreamsOut.new
      @run_state.options = @delegate_object
      @run_state.started_at = Time.now.utc

      if @delegate_object[:execute_in_own_window] &&
         @delegate_object[:execute_command_format].present? &&
         @run_state.saved_filespec.present?
        @run_state.in_own_window = true
        system(
          format(
            @delegate_object[:execute_command_format],
            command_execute_in_own_window_format_arguments(rest: args ? args.join(' ') : '')
          )
        )
      else
        @run_state.in_own_window = false
        execute_command_with_streams(
          [@delegate_object[:shell], '-c', command,
           @delegate_object[:filename], *args]
        )
      end

      @run_state.completed_at = Time.now.utc
    rescue Errno::ENOENT => err
      # Handle ENOENT error
      @run_state.aborted_at = Time.now.utc
      @run_state.error_message = err.message
      @run_state.error = err
      @run_state.files.append_stream_line(ExecutionStreams::STD_ERR,
                                          @run_state.error_message)
      @fout.fout "Error ENOENT: #{err.inspect}"
    rescue SignalException => err
      # Handle SignalException
      @run_state.aborted_at = Time.now.utc
      @run_state.error_message = 'SIGTERM'
      @run_state.error = err
      @run_state.files.append_stream_line(ExecutionStreams::STD_ERR,
                                          @run_state.error_message)
      @fout.fout "Error ENOENT: #{err.inspect}"
    end

    def command_execute_in_own_window_format_arguments(home: Dir.pwd, rest: '')
      {
        batch_index: @run_state.batch_index,
        batch_random: @run_state.batch_random,
        block_name: @delegate_object[:block_name],
        document_filename: File.basename(@delegate_object[:filename]),
        document_filespec: @delegate_object[:filename],
        home: home,
        output_filename: File.basename(@delegate_object[:logged_stdout_filespec]),
        output_filespec: @delegate_object[:logged_stdout_filespec],
        rest: rest,
        script_filename: @run_state.saved_filespec,
        script_filespec: File.join(home, @run_state.saved_filespec),
        started_at: @run_state.started_at.strftime(
          @delegate_object[:execute_command_title_time_format]
        )
      }
    end

    # This method is responsible for handling the execution of generic blocks in a markdown document.
    # It collects the required code lines from the document and, depending on the configuration,
    # may display the code for user approval before execution. It then executes the approved block.
    #
    # @param mdoc [Object] The markdown document object containing code blocks.
    # @param selected [Hash] The selected item from the menu to be executed.
    # @return [LoadFileLinkState] An object indicating whether to load the next block or reuse the current one.
    def compile_execute_and_trigger_reuse(mdoc:, selected:, block_source:,
                                          link_state: nil)
      required_lines = collect_required_code_lines(mdoc: mdoc, selected: selected, link_state: link_state,
                                                   block_source: block_source)
      output_or_approval = @delegate_object[:output_script] || @delegate_object[:user_must_approve]
      if output_or_approval
        display_required_code(required_lines: required_lines)
      end
      allow_execution = if @delegate_object[:user_must_approve]
                          prompt_for_user_approval(required_lines: required_lines,
                                                   selected: selected)
                        else
                          true
                        end

      if allow_execution
        execute_required_lines(required_lines: required_lines,
                               selected: selected)
      end

      link_state.block_name = nil
      LoadFileLinkState.new(LoadFile::REUSE, link_state)
    end

    # Check if the expression contains wildcard characters
    def contains_wildcards?(expr)
      expr.match(%r{\*|\?|\[})
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
    # return number of lines added
    def create_and_add_chrome_block(blocks:, match_data:,
                                    format_option:, color_method:,
                                    case_conversion: nil,
                                    center: nil,
                                    wrap: nil)
      line_cap = match_data.named_captures.transform_keys(&:to_sym)

      # replace tabs in indent
      line_cap[:indent] ||= ''
      line_cap[:indent] = line_cap[:indent].dup if line_cap[:indent].frozen?
      line_cap[:indent].gsub!("\t", '    ')
      # replace tabs in text
      line_cap[:text] ||= ''
      line_cap[:text] = line_cap[:text].dup if line_cap[:text].frozen?
      line_cap[:text].gsub!("\t", '    ')
      # missing capture
      line_cap[:line] ||= ''

      accepted_width = @delegate_object[:console_width] - 2
      line_caps = if wrap
                    if line_cap[:text].length > accepted_width
                      wrapper = StringWrapper.new(width: accepted_width - line_cap[:indent].length)
                      wrapper.wrap(line_cap[:text]).map do |line|
                        line_cap.dup.merge(text: line)
                      end
                    else
                      [line_cap]
                    end
                  else
                    [line_cap]
                  end
      if center
        line_caps.each do |line_obj|
          line_obj[:indent] = if line_obj[:text].length < accepted_width
                                ' ' * ((accepted_width - line_obj[:text].length) / 2)
                              else
                                ''
                              end
        end
      end

      line_caps.each do |line_obj|
        next if line_obj[:text].nil?

        case case_conversion
        when :upcase
          line_obj[:text].upcase!
        when :downcase
          line_obj[:text].downcase!
        end

        # format expects :line to be text only
        line_obj[:line] = line_obj[:text]
        oname = format(format_option, line_obj)
        line_obj[:line] = line_obj[:indent] + line_obj[:text]
        blocks.push FCB.new(
          chrome: true,
          disabled: '',
          dname: line_obj[:indent] + oname.send(color_method),
          oname: line_obj[:text]
        )
      end
      line_caps.count
    end

    ##
    # Processes lines within the file and converts them into blocks if they match certain criteria.
    # @param blocks [Array] The array to append new blocks to.
    # @param fcb [FCB] The file control block being processed.
    # @param opts [Hash] Options containing configuration for line processing.
    # @param use_chrome [Boolean] Indicates if the chrome styling should be applied.
    def create_and_add_chrome_blocks(blocks, fcb)
      match_criteria = [
        { color: :menu_heading1_color, format: :menu_heading1_format, match: :heading1_match, center: true, case_conversion: :upcase, wrap: true },
        { color: :menu_heading2_color, format: :menu_heading2_format, match: :heading2_match, center: true, wrap: true },
        { color: :menu_heading3_color, format: :menu_heading3_format, match: :heading3_match, center: true, case_conversion: :downcase, wrap: true },
        { color: :menu_divider_color,  format: :menu_divider_format,  match: :menu_divider_match },
        { color: :menu_note_color,     format: :menu_note_format,     match: :menu_note_match, wrap: true },
        { color: :menu_task_color,     format: :menu_task_format,     match: :menu_task_match, wrap: true }
      ]
      # rubocop:enable Style/UnlessElse
      match_criteria.each do |criteria|
        unless @delegate_object[criteria[:match]].present? &&
               (mbody = fcb.body[0].match @delegate_object[criteria[:match]])
          next
        end

        create_and_add_chrome_block(
          blocks: blocks,
          case_conversion: criteria[:case_conversion],
          center: criteria[:center],
          color_method: @delegate_object[criteria[:color]].to_sym,
          format_option: @delegate_object[criteria[:format]],
          match_data: mbody,
          wrap: criteria[:wrap]
        )
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
      option_name = selected_option.oname
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
    def display_required_code(required_lines:)
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

      @run_state.files.write_execution_output_to_file(@delegate_object[:logged_stdout_filespec])
    end

    # Select and execute a code block from a Markdown document.
    #
    # This method allows the user to interactively select a code block from a
    # Markdown document, obtain approval, and execute the chosen block of code.
    #
    # @return [Nil] Returns nil if no code block is selected or an error occurs.
    def document_inpseq
      @menu_base_options = @delegate_object
      @dml_link_state = LinkState.new(
        block_name: @delegate_object[:block_name],
        document_filename: @delegate_object[:filename]
      )
      @run_state.block_name_from_cli = @dml_link_state.block_name.present?
      @cli_block_name = @dml_link_state.block_name
      @dml_now_using_cli = @run_state.block_name_from_cli
      @dml_menu_default_dname = nil
      @dml_block_state = SelectedBlockMenuState.new
      @doc_saved_lines_files = []

      ## load file with code lines per options
      #
      if @menu_base_options[:load_code].present?
        @dml_link_state.inherited_lines = 
          @menu_base_options[:load_code].split(':').map do |path|
            File.readlines(path, chomp: true)
          end.flatten(1)

        inherited_block_names = []
        inherited_dependencies = {}
        selected = FCB.new(oname: 'load_code')
        pop_add_current_code_to_head_and_trigger_load(@dml_link_state, inherited_block_names,
                                                      code_lines, inherited_dependencies, selected)
      end

      fdo = ->(mo) {
        format(@delegate_object[:menu_link_format],
               HashDelegator.safeval(@delegate_object[mo])).pub_name
      }
      item_back = fdo.call(:menu_option_back_name)
      item_edit = fdo.call(:menu_option_edit_name)
      item_history = fdo.call(:menu_option_history_name)
      item_load = fdo.call(:menu_option_load_name)
      item_save = fdo.call(:menu_option_save_name)
      item_shell = fdo.call(:menu_option_shell_name)
      item_view = fdo.call(:menu_option_view_name)

      @run_state.batch_random = Random.new.rand
      @run_state.batch_index = 0

      @run_state.files = StreamsOut.new

      InputSequencer.new(
        @delegate_object[:filename],
        @delegate_object[:input_cli_rest]
      ).run do |msg, data|
        case msg
        when :parse_document # once for each menu
          # puts "@ - parse document #{data}"
          inpseq_parse_document(data)

          if @delegate_object[:menu_for_history]
            history_files(@dml_link_state).tap do |files|
              if files.count.positive?
                menu_enable_option(item_history, files.count, 'files',
                                   menu_state: MenuState::HISTORY)
              end
            end
          end

          if @delegate_object[:menu_for_saved_lines] && @delegate_object[:document_saved_lines_glob].present?

            sf = document_name_in_glob_as_file_name(@dml_link_state.document_filename,
                                                    @delegate_object[:document_saved_lines_glob])
            files = sf ? Dir.glob(sf) : []
            @doc_saved_lines_files = files.count.positive? ? files : []

            lines_count = @dml_link_state.inherited_lines_count

            # add menu items (glob, load, save) and enable selectively
            if files.count.positive? || lines_count.positive?
              menu_add_disabled_option(sf)
            end
            if files.count.positive?
              menu_enable_option(item_load, files.count, 'files',
                                 menu_state: MenuState::LOAD)
            end
            if lines_count.positive?
              menu_enable_option(item_edit, lines_count, 'lines',
                                 menu_state: MenuState::EDIT)
            end
            if lines_count.positive?
              menu_enable_option(item_save, 1, '',
                                 menu_state: MenuState::SAVE)
            end
            if lines_count.positive?
              menu_enable_option(item_view, 1, '',
                                 menu_state: MenuState::VIEW)
            end
            if @delegate_object[:menu_with_shell]
              menu_enable_option(item_shell, 1, '',
                                 menu_state: MenuState::SHELL)
            end

          end

        when :display_menu
          # warn "@ - display menu:"
          # ii_display_menu
          @dml_block_state = SelectedBlockMenuState.new
          @delegate_object[:block_name] = nil

        when :user_choice
          if @dml_link_state.block_name.present?
            # @prior_block_was_link = true
            @dml_block_state.block = @dml_blocks_in_file.find do |item|
              item.pub_name == @dml_link_state.block_name || item.oname == @dml_link_state.block_name
            end
            @dml_link_state.block_name = nil
          else
            # puts "? - Select a block to execute (or type #{$texit} to exit):"
            break if inpseq_user_choice == :break # into @dml_block_state
            break if @dml_block_state.block.nil? # no block matched
          end
          # puts "! - Executing block: #{data}"
          @dml_block_state.block&.pub_name

        when :execute_block
          case (block_name = data)
          when item_back
            debounce_reset
            @menu_user_clicked_back_link = true
            load_file_link_state = pop_link_history_and_trigger_load
            @dml_link_state = load_file_link_state.link_state

            InputSequencer.merge_link_state(
              @dml_link_state,
              InputSequencer.next_link_state(
                block_name: @dml_link_state.block_name,
                document_filename: @dml_link_state.document_filename,
                prior_block_was_link: true
              )
            )

          when item_edit
            debounce_reset
            edited = edit_text(@dml_link_state.inherited_lines_block)
            @dml_link_state.inherited_lines = edited.split("\n") if edited

            return :break if pause_user_exit

            InputSequencer.next_link_state(prior_block_was_link: true)

          when item_history
            debounce_reset
            files = history_files(@dml_link_state)
            files_table_rows = files.map do |file|
              if Regexp.new(@delegate_object[:saved_asset_match]) =~ file
                begin
                  OpenStruct.new(
                    file: file,
                    row: format(
                      @delegate_object[:saved_history_format],
                      # create with default '*' so unknown parameters are given a wildcard
                      $~.names.each_with_object(Hash.new('*')) do |name, hash|
                        hash[name.to_sym] = $~[name]
                      end
                    )
                  )
                rescue KeyError
                  # pp $!, $@
                  warn "Cannot format with: #{@delegate_object[:saved_history_format]}"
                  error_handler('saved_history_format')
                  break
                end
              else
                warn "Cannot parse name: #{file}"
                next
              end
            end&.compact&.sort_by(&:row)

            return :break unless files_table_rows

            # repeat select+display until user exits
            row_attrib = :row
            loop do
              case (name = prompt_select_code_filename(
                [@delegate_object[:prompt_filespec_back],
                 @delegate_object[:prompt_filespec_facet]] +
                 files_table_rows.map(&row_attrib),
                string: @delegate_object[:prompt_select_history_file],
                color_sym: :prompt_color_after_script_execution
              ))
              when @delegate_object[:prompt_filespec_back]
                break
              when @delegate_object[:prompt_filespec_facet]
                row_attrib = row_attrib == :row ? :file : :row
              else
                file = files_table_rows.select { |ftr| ftr.row == name }&.first
                info = file_info(file.file)
                warn "#{file.file} - #{info[:lines]} lines / #{info[:size]} bytes"
                warn(File.readlines(file.file,
                                    chomp: false).map.with_index do |line, ind|
                       format(' %s.  %s', format('% 4d', ind + 1).violet, line)
                     end)
              end
            end

            return :break if pause_user_exit

            InputSequencer.next_link_state(prior_block_was_link: true)

          when item_load
            debounce_reset
            sf = document_name_in_glob_as_file_name(@dml_link_state.document_filename,
                                                    @delegate_object[:document_saved_lines_glob])
            load_filespec = load_filespec_from_expression(sf)
            if load_filespec
              @dml_link_state.inherited_lines_append(
                File.readlines(load_filespec, chomp: true)
              )
            end

            return :break if pause_user_exit

            InputSequencer.next_link_state(prior_block_was_link: true)

          when item_save
            debounce_reset
            sf = document_name_in_glob_as_file_name(@dml_link_state.document_filename,
                                                    @delegate_object[:document_saved_lines_glob])
            save_filespec = save_filespec_from_expression(sf)
            if save_filespec && !write_file_with_directory_creation(
              save_filespec,
              HashDelegator.join_code_lines(@dml_link_state.inherited_lines)
            )
              return :break

            end

            InputSequencer.next_link_state(prior_block_was_link: true)

          when item_shell
            debounce_reset
            loop do
              command = prompt_for_command(":MDE #{Time.now.strftime('%FT%TZ')}> ".bgreen)
              break if !command.present? || command == 'exit'

              exit_status = execute_command_with_streams(
                [@delegate_object[:shell], '-c', command]
              )
              case exit_status
              when 0
                warn "#{'OK'.green} #{exit_status}"
              else
                warn "#{'ERR'.bred} #{exit_status}"
              end
            end

            return :break if pause_user_exit

            InputSequencer.next_link_state(prior_block_was_link: true)

          when item_view
            debounce_reset
            warn @dml_link_state.inherited_lines_block

            return :break if pause_user_exit

            InputSequencer.next_link_state(prior_block_was_link: true)

          else
            @dml_block_state = block_state_for_name_from_cli(block_name)
            if @dml_block_state.block && @dml_block_state.block.fetch(:shell,
                                                                      nil) == BlockType::OPTS
              debounce_reset
              link_state = LinkState.new
              options_state = read_show_options_and_trigger_reuse(
                link_state: link_state,
                mdoc: @dml_mdoc,
                selected: @dml_block_state.block
              )

              update_menu_base(options_state.options)
              options_state.load_file_link_state.link_state
            else
              inpseq_execute_block(block_name)

              if prompt_user_exit(block_name_from_cli: @run_state.block_name_from_cli,
                                  selected: @dml_block_state.block)
                return :break
              end

              ## order of block name processing: link block, cli, from user
              #
              @dml_link_state.block_name, @run_state.block_name_from_cli, cli_break =
                HashDelegator.next_link_state(
                  block_name: @dml_link_state.block_name,
                  block_name_from_cli: @dml_now_using_cli,
                  block_state: @dml_block_state,
                  was_using_cli: @dml_now_using_cli
                )

              if !@dml_block_state.block[:block_name_from_ui] && cli_break
                # &bsp '!block_name_from_ui + cli_break -> break'
                return :break
              end

              InputSequencer.next_link_state(
                block_name: @dml_link_state.block_name,
                prior_block_was_link: @dml_block_state.block.fetch(:shell,
                                                                   nil) != BlockType::BASH
              )
            end
          end

        when :exit?
          data == $texit
        when :stay?
          data == $stay
        else
          raise "Invalid message: #{msg}"
        end
      end
    rescue StandardError
      HashDelegator.error_handler('document_inpseq',
                                  { abort: true })
    end

    # remove leading "./"
    # replace characters: / : . * (space) with: (underscore)
    def document_name_in_glob_as_file_name(document_filename, glob)
      if document_filename.nil? || document_filename.empty?
        return document_filename
      end

      format(glob,
             { document_filename: document_filename.gsub(%r{^\./}, '').gsub(/[\/:\.\* ]/,
                                                                            '_') })
    end

    def dump_and_warn_block_state(selected:)
      if selected.nil?
        Exceptions.warn_format("Block not found -- name: #{@delegate_object[:block_name]}",
                               { abort: true })
      end

      return unless @delegate_object[:dump_selected_block]

      warn selected.to_yaml.sub(/^(?:---\n)?/, "Block:\n")
    end

    # Outputs warnings based on the delegate object's configuration
    #
    # @param delegate_object [Hash] The delegate object containing configuration flags.
    # @param blocks_in_file [Hash] Hash of blocks present in the file.
    # @param menu_blocks [Hash] Hash of menu blocks.
    # @param link_state [LinkState] Current state of the link.
    def dump_delobj(blocks_in_file, menu_blocks, link_state)
      if @delegate_object[:dump_delegate_object]
        warn format_and_highlight_hash(@delegate_object,
                                       label: '@delegate_object')
      end

      if @delegate_object[:dump_blocks_in_file]
        warn format_and_highlight_dependencies(compact_and_index_hash(blocks_in_file),
                                               label: 'blocks_in_file')
      end

      if @delegate_object[:dump_menu_blocks]
        warn format_and_highlight_dependencies(compact_and_index_hash(menu_blocks),
                                               label: 'menu_blocks')
      end

      if @delegate_object[:dump_inherited_block_names]
        warn format_and_highlight_lines(link_state.inherited_block_names,
                                        label: 'inherited_block_names')
      end
      if @delegate_object[:dump_inherited_dependencies]
        warn format_and_highlight_lines(link_state.inherited_dependencies,
                                        label: 'inherited_dependencies')
      end
      return unless @delegate_object[:dump_inherited_lines]

      warn format_and_highlight_lines(link_state.inherited_lines,
                                      label: 'inherited_lines')
    end

    # Opens text in an editor for user modification and returns the modified text.
    #
    # This method reads the provided text, opens it in the default editor,
    # and allows the user to modify it. If the user makes changes, the
    # modified text is returned. If the user exits the editor without
    # making changes or the editor is closed abruptly, appropriate messages
    # are displayed.
    #
    # @param [String] initial_text The initial text to be edited.
    # @param [String] temp_name The base name for the temporary file (default: 'edit_text').
    # @return [String, nil] The modified text, or nil if no changes were made or the editor was closed abruptly.
    def edit_text(initial_text, temp_name: 'edit_text')
      # Create a temporary file to store the initial text
      temp_file = Tempfile.new(temp_name)
      temp_file.write(initial_text)
      temp_file.rewind

      # Capture the modification time of the temporary file before editing
      before_mtime = temp_file.mtime

      # Open the temporary file in the default editor
      system("#{ENV['EDITOR'] || 'vi'} #{temp_file.path}")

      # Capture the exit status of the editor
      editor_exit_status = $?.exitstatus

      # Reopen the file to ensure the updated modification time is read
      temp_file.open
      after_mtime = temp_file.mtime

      # Check if the editor was exited normally or was interrupted
      if editor_exit_status != 0
        warn 'The editor was closed abruptly. No changes were made.'
        temp_file.close
        temp_file.unlink
        return
      end

      result_text = nil
      # Read the file if it was modified
      if before_mtime != after_mtime
        temp_file.rewind
        result_text = temp_file.read
      end

      # Remove the temporary file
      temp_file.close
      temp_file.unlink

      result_text
    end

    def exec_bash_next_state(selected:, mdoc:, link_state:, block_source: {})
      lfls = execute_shell_type(
        selected: selected,
        mdoc: mdoc,
        link_state: link_state,
        block_source: block_source
      )

      # if the same menu is being displayed, collect the display name of the selected menu item for use as the default item
      [lfls.link_state,
       lfls.load_file == LoadFile::LOAD ? nil : selected[:dname]]
      #.tap { |ret| pp [__FILE__,__LINE__,'exec_bash_next_state()',ret] }
    end

    # Executes a given command and processes its input, output, and error streams.
    #
    # @param [Array<String>] command the command to execute along with its arguments.
    # @yield [stdin, stdout, stderr, thread] if a block is provided, it yields input, output, error lines, and the execution thread.
    # @return [Integer] the exit status of the executed command (0 to 255).
    #
    # @example
    #   status = execute_command_with_streams(['ls', '-la']) do |stdin, stdout, stderr, thread|
    #     puts "STDOUT: #{stdout}" if stdout
    #     puts "STDERR: #{stderr}" if stderr
    #   end
    #   puts "Command exited with status: #{status}"
    def execute_command_with_streams(command)
      exit_status = nil

      Open3.popen3(*command) do |stdin, stdout, stderr, exec_thread|
        # Handle stdout stream
        handle_stream(stream: stdout,
                      file_type: ExecutionStreams::STD_OUT) do |line|
          yield nil, line, nil, exec_thread if block_given?
        end

        # Handle stderr stream
        handle_stream(stream: stderr,
                      file_type: ExecutionStreams::STD_ERR) do |line|
          yield nil, nil, line, exec_thread if block_given?
        end

        # Handle stdin stream
        input_thread = handle_stream(stream: $stdin,
                                     file_type: ExecutionStreams::STD_IN) do |line|
          stdin.puts(line)
          yield line, nil, nil, exec_thread if block_given?
        end

        # Wait for all streams to be processed
        wait_for_stream_processing
        exec_thread.join

        # Ensure the input thread is killed if it's still alive
        sleep 0.1
        input_thread.kill if input_thread&.alive?

        # Retrieve the exit status
        exit_status = exec_thread.value.exitstatus
      end

      exit_status
    end

    # Executes a block of code that has been approved for execution.
    # It sets the script block name, writes command files if required, and handles the execution
    # including output formatting and summarization.
    #
    # @param required_lines [Array<String>] The lines of code to be executed.
    # @param selected [FCB] The selected functional code block object.
    def execute_required_lines(required_lines: [], selected: FCB.new)
      if @delegate_object[:save_executed_script]
        write_command_file(required_lines: required_lines,
                           selected: selected)
      end
      if @dml_block_state
        calc_logged_stdout_filename(block_name: @dml_block_state.block.oname)
      end
      format_and_execute_command(code_lines: required_lines)
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
    def execute_shell_type(selected:, mdoc:, block_source:,
                           link_state: LinkState.new)
      if selected.fetch(:shell, '') == BlockType::LINK
        debounce_reset
        push_link_history_and_trigger_load(link_block_body: selected.fetch(:body, ''),
                                           mdoc: mdoc,
                                           selected: selected,
                                           link_state: link_state,
                                           block_source: block_source)

      elsif @menu_user_clicked_back_link
        debounce_reset
        pop_link_history_and_trigger_load

      elsif selected[:shell] == BlockType::OPTS
        debounce_reset
        block_names = []
        code_lines = []
        dependencies = {}
        options_state = read_show_options_and_trigger_reuse(
          link_state: link_state,
          mdoc: @dml_mdoc,
          selected: selected
        )
        update_menu_base(options_state.options)

        ### options_state.load_file_link_state
        link_state = LinkState.new
        link_history_push_and_next(
          curr_block_name: selected.pub_name,
          curr_document_filename: @delegate_object[:filename],
          inherited_block_names: ((link_state&.inherited_block_names || []) + block_names).sort.uniq,
          inherited_dependencies: (link_state&.inherited_dependencies || {}).merge(dependencies || {}), ### merge, not replace, key data
          inherited_lines: HashDelegator.code_merge(
            link_state&.inherited_lines, code_lines
          ),
          next_block_name: '',
          next_document_filename: @delegate_object[:filename],
          next_load_file: LoadFile::REUSE
        )

      elsif selected[:shell] == BlockType::VARS
        debounce_reset
        block_names = []
        code_lines = set_environment_variables_for_block(selected)
        dependencies = {}
        link_history_push_and_next(
          curr_block_name: selected.pub_name,
          curr_document_filename: @delegate_object[:filename],
          inherited_block_names: ((link_state&.inherited_block_names || []) + block_names).sort.uniq,
          inherited_dependencies: (link_state&.inherited_dependencies || {}).merge(dependencies || {}), ### merge, not replace, key data
          inherited_lines: HashDelegator.code_merge(
            link_state&.inherited_lines, code_lines
          ),
          next_block_name: '',
          next_document_filename: @delegate_object[:filename],
          next_load_file: LoadFile::REUSE
        )

      elsif debounce_allows
        compile_execute_and_trigger_reuse(mdoc: mdoc,
                                          selected: selected,
                                          link_state: link_state,
                                          block_source: block_source)

      else
        LoadFileLinkState.new(LoadFile::REUSE, link_state)
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

    # size of a file in bytes and the number of lines
    def file_info(file_path)
      file_size = 0
      line_count = 0

      File.open(file_path, 'r') do |file|
        file.each_line do |_line|
          line_count += 1
        end
        file_size = file.size
      end

      { size: file_size, lines: line_count }
    end

    def format_and_execute_command(code_lines:)
      formatted_command = code_lines.flatten.join("\n")
      @fout.fout fetch_color(data_sym: :script_execution_head,
                             color_sym: :script_execution_frame_color)
      command_execute(formatted_command, args: @pass_args)
      @fout.fout fetch_color(data_sym: :script_execution_tail,
                             color_sym: :script_execution_frame_color)
    end

    # Format expression using environment variables and run state
    def format_expression(expr)
      data = link_load_format_data
      ENV.each { |key, value| data[key] = value }
      format(expr, data)
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

    # Expand expression if it contains format specifiers
    def formatted_expression(expr)
      expr.include?('%{') ? format_expression(expr) : expr
    end

    def generate_temp_filename(ext = '.sh')
      filename = begin
        Dir::Tmpname.make_tmpname(['x', ext], nil)
      rescue NoMethodError
        require 'securerandom'
        "#{SecureRandom.urlsafe_base64}#{ext}"
      end
      File.join(Dir.tmpdir, filename)
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

      @delegate_object[:block_name] = block_state.block.pub_name
      @menu_user_clicked_back_link = block_state.state == MenuState::BACK
    end

    def handle_stream(stream:, file_type:, swap: false)
      @process_mutex.synchronize do
        Thread.new do
          stream.each_line do |line|
            line.strip!
            if @run_state.files.streams
              @run_state.files.append_stream_line(file_type,
                                                  line)
            end

            puts line if @delegate_object[:output_stdout]

            yield line if block_given?
          end
        rescue IOError
          # Handle IOError
        ensure
          @process_cv.signal
        end
      end
    end

    def history_files(link_state)
      Dir.glob(
        File.join(
          @delegate_object[:saved_script_folder],
          SavedAsset.new(
            filename: @delegate_object[:filename],
            saved_asset_format: shell_escape_asset_format(link_state)
          ).generate_name
        )
      )
    end

    # Initializes variables for regex and other states
    def initial_state
      {
        fenced_start_and_end_regex:
         Regexp.new(@delegate_object.fetch(
                      :fenced_start_and_end_regex, '^(?<indent> *)`{3,}'
                    )),
        fenced_start_extended_regex:
         Regexp.new(@delegate_object.fetch(
                      :fenced_start_and_end_regex, '^(?<indent> *)`{3,}'
                    )),
        fcb: MarkdownExec::FCB.new,
        in_fenced_block: false,
        headings: []
      }
    end

    def inpseq_execute_block(block_name)
      @dml_block_state = block_state_for_name_from_cli(block_name)
      dump_and_warn_block_state(selected: @dml_block_state.block)
      @dml_link_state, @dml_menu_default_dname =
        exec_bash_next_state(
          selected: @dml_block_state.block,
          mdoc: @dml_mdoc,
          link_state: @dml_link_state,
          block_source: {
            document_filename: @delegate_object[:filename],
            time_now_date: Time.now.utc.strftime(@delegate_object[:shell_code_label_time_format])
          }
        )
    end

    def inpseq_parse_document(_document_filename)
      @run_state.batch_index += 1
      @run_state.in_own_window = false

      # &bsp 'loop', block_name_from_cli, @cli_block_name
      @run_state.block_name_from_cli, @dml_now_using_cli, @dml_blocks_in_file, @dml_menu_blocks, @dml_mdoc =
        set_delobj_menu_loop_vars(block_name_from_cli: @run_state.block_name_from_cli,
                                  now_using_cli: @dml_now_using_cli,
                                  link_state: @dml_link_state)
    end

    def inpseq_user_choice
      @dml_block_state = load_cli_or_user_selected_block(all_blocks: @dml_blocks_in_file,
                                                         menu_blocks: @dml_menu_blocks,
                                                         default: @dml_menu_default_dname)
      # &bsp '@run_state.block_name_from_cli:',@run_state.block_name_from_cli
      if !@dml_block_state
        HashDelegator.error_handler('block_state missing', { abort: true })
      elsif @dml_block_state.state == MenuState::EXIT
        # &bsp 'load_cli_or_user_selected_block -> break'
        :break
      end
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

    def link_block_data_eval(link_state, code_lines, selected, link_block_data,
                             block_source:)
      all_code = HashDelegator.code_merge(link_state&.inherited_lines,
                                          code_lines)
      output_lines = []

      Tempfile.open do |file|
        cmd = "#{@delegate_object[:shell]} #{file.path}"
        file.write(all_code.join("\n"))
        file.rewind

        if link_block_data.fetch(LinkKeys::EXEC, false)
          @run_state.files = StreamsOut.new
          execute_command_with_streams([cmd]) do |_stdin, stdout, stderr, _thread|
            line = stdout || stderr
            output_lines.push(line) if line
          end

          ## select output_lines that look like assignment or match other specs
          #
          output_lines = process_string_array(
            output_lines,
            begin_pattern: @delegate_object.fetch(:output_assignment_begin,
                                                  nil),
            end_pattern: @delegate_object.fetch(:output_assignment_end, nil),
            scan1: @delegate_object.fetch(:output_assignment_match, nil),
            format1: @delegate_object.fetch(:output_assignment_format, nil)
          )

        else
          output_lines = `#{cmd}`.split("\n")
        end
      end

      unless output_lines
        HashDelegator.error_handler('all_code eval output_lines is nil',
                                    { abort: true })
      end

      label_format_above = @delegate_object[:shell_code_label_format_above]
      label_format_below = @delegate_object[:shell_code_label_format_below]

      [label_format_above && format(label_format_above,
                                    block_source.merge({ block_name: selected.pub_name }))] +
        output_lines.map do |line|
          re = Regexp.new(link_block_data.fetch('pattern', '(?<line>.*)'))
          next unless re =~ line

          re.gsub_format(line,
                         link_block_data.fetch('format',
                                               '%{line}'))
        end.compact +
        [label_format_below && format(label_format_below,
                                      block_source.merge({ block_name: selected.pub_name }))]
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

    def link_load_format_data
      {
        batch_index: @run_state.batch_index,
        batch_random: @run_state.batch_random,
        block_name: @delegate_object[:block_name],
        document_filename: File.basename(@delegate_object[:filename]),
        document_filespec: @delegate_object[:filename],
        home: Dir.pwd,
        started_at: Time.now.utc.strftime(@delegate_object[:execute_command_title_time_format])
      }
    end

    # Loads auto blocks based on delegate object settings and updates if new filename is detected.
    # Executes a specified block once per filename.
    # @param all_blocks [Array] Array of all block elements.
    # @return [Boolean, nil] True if values were modified, nil otherwise.
    def load_auto_opts_block(all_blocks, mdoc:)
      block_name = @delegate_object[:document_load_opts_block_name]
      unless block_name.present? && @most_recent_loaded_filename != @delegate_object[:filename]
        return
      end

      block = HashDelegator.block_find(all_blocks, :oname, block_name)
      return unless block

      options_state = read_show_options_and_trigger_reuse(
        mdoc: mdoc,
        selected: block
      )
      update_menu_base(options_state.options)

      @most_recent_loaded_filename = @delegate_object[:filename]
      true
    end

    def load_cli_or_user_selected_block(all_blocks: [], menu_blocks: [],
                                        default: nil)
      if @delegate_object[:block_name].present?
        block = all_blocks.find do |item|
          item.pub_name == @delegate_object[:block_name]
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

    # format + glob + select for file in load block
    # name has references to ENV vars and doc and batch vars incl. timestamp
    def load_filespec_from_expression(expression)
      # Process expression with embedded formatting
      expanded_expression = formatted_expression(expression)

      # Handle wildcards or direct file specification
      if contains_wildcards?(expanded_expression)
        load_filespec_wildcard_expansion(expanded_expression)
      else
        expanded_expression
      end
    end

    # Handle expression with wildcard characters
    def load_filespec_wildcard_expansion(expr, auto_load_single: false)
      files = find_files(expr)
      if files.count.zero?
        HashDelegator.error_handler("no files found with '#{expr}' ",
                                    { abort: true })
      elsif auto_load_single && files.count == 1
        files.first
      else
        ## user selects from existing files or other
        #
        case (name = prompt_select_code_filename(
          [@delegate_object[:prompt_filespec_back]] + files,
          string: @delegate_object[:prompt_select_code_file],
          color_sym: :prompt_color_after_script_execution
        ))
        when @delegate_object[:prompt_filespec_back]
          # do nothing
        else
          name
        end
      end
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
      all_blocks, mdoc = mdoc_and_blocks_from_nested_files if load_auto_opts_block(
        all_blocks, mdoc: mdoc
      )

      menu_blocks = mdoc.fcbs_per_options(@delegate_object)
      add_menu_chrome_blocks!(menu_blocks: menu_blocks, link_state: link_state)
      ### compress empty lines
      HashDelegator.delete_consecutive_blank_lines!(menu_blocks)
      [all_blocks, menu_blocks, mdoc]
    end

    def menu_add_disabled_option(name)
      raise unless name.present?
      raise if @dml_menu_blocks.nil?

      block = @dml_menu_blocks.find { |item| item.oname == name }

      # create menu item when it is needed (count > 0)
      #
      return unless block.nil?

      # append_chrome_block(menu_blocks: @dml_menu_blocks, menu_state: MenuState::LOAD)
      chrome_block = FCB.new(
        chrome: true,
        disabled: '',
        dname: HashDelegator.new(@delegate_object).string_send_color(
          name, :menu_inherited_lines_color
        ),
        oname: formatted_name
      )

      if insert_at_top
        @dml_menu_blocks.unshift(chrome_block)
      else
        @dml_menu_blocks.push(chrome_block)
      end
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
      option_value = HashDelegator.safeval(@delegate_object.fetch(
                                             option_symbol, ''
                                           ))

      if @delegate_object[:menu_chrome_format]
        format(@delegate_object[:menu_chrome_format], option_value)
      else
        option_value
      end
    end

    def menu_enable_option(name, count, type, menu_state: MenuState::LOAD)
      raise unless name.present?
      raise if @dml_menu_blocks.nil?

      item = @dml_menu_blocks.find { |block| block.oname == name }

      # create menu item when it is needed (count > 0)
      #
      if item.nil? && count.positive?
        append_chrome_block(menu_blocks: @dml_menu_blocks,
                            menu_state: menu_state)
        item = @dml_menu_blocks.find { |block| block.oname == name }
      end

      # update item if it exists
      #
      return unless item

      item[:dname] = type.present? ? "#{name} (#{count} #{type})" : name
      if count.positive?
        item.delete(:disabled)
      else
        item[:disabled] = ''
      end
    end

    def manage_cli_selection_state(block_name_from_cli:, now_using_cli:,
                                   link_state:)
      if block_name_from_cli && @cli_block_name == @menu_base_options[:menu_persist_block_name]
        # &bsp 'pause cli control, allow user to select block'
        block_name_from_cli = false
        now_using_cli = false
        @menu_base_options[:block_name] =
          @delegate_object[:block_name] = \
            link_state.block_name =
              @cli_block_name = nil
      end

      @delegate_object = @menu_base_options.dup
      @menu_user_clicked_back_link = false
      [block_name_from_cli, now_using_cli]
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

    def output_color_formatted(data_sym, color_sym)
      formatted_string = string_send_color(@delegate_object[data_sym],
                                           color_sym)
      @fout.fout formatted_string
    end

    def fout_execution_report
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

      @fout.fout_section 'summary', {
        execute_aborted_at: @run_state.aborted_at,
        execute_completed_at: @run_state.completed_at,
        execute_error: @run_state.error,
        execute_error_message: @run_state.error_message,
        execute_options: @run_state.options,
        execute_started_at: @run_state.started_at,
        saved_filespec: @run_state.saved_filespec,
        script_block_name: @run_state.script_block_name,
        streamed_lines: @run_state.files.streams
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

    def pause_user_exit
      @delegate_object[:pause_after_script_execution] &&
        prompt_select_continue == MenuState::EXIT
    end

    def pop_add_current_code_to_head_and_trigger_load(link_state, block_names, code_lines,
                                                      dependencies, selected, next_block_name: nil)
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
        LoadFileLinkState.new(LoadFile::LOAD, next_state)
      else
        # no history exists; must have been called independently => retain script
        link_history_push_and_next(
          curr_block_name: selected.pub_name,
          curr_document_filename: @delegate_object[:filename],
          inherited_block_names:
           ((link_state&.inherited_block_names || []) + block_names).sort.uniq,
          inherited_dependencies:
           (link_state&.inherited_dependencies || {}).merge(dependencies || {}), ### merge, not replace, key data
          inherited_lines:
           HashDelegator.code_merge(link_state&.inherited_lines, code_lines),
          next_block_name: next_block_name,
          next_document_filename: @delegate_object[:filename], # not next_document_filename
          next_load_file: LoadFile::REUSE # not next_document_filename == @delegate_object[:filename] ? LoadFile::REUSE : LoadFile::LOAD
        )
        # LoadFileLinkState.new(LoadFile::REUSE, link_state)
      end
    end

    # This method handles the back-link operation in the Markdown execution context.
    # It updates the history state and prepares to load the next block.
    #
    # @return [LoadFileLinkState] An object indicating the action to load the next block.
    def pop_link_history_and_trigger_load
      pop = @link_history.pop
      peek = @link_history.peek
      LoadFileLinkState.new(
        LoadFile::LOAD,
        LinkState.new(
          document_filename: pop.document_filename,
          inherited_block_names: peek.inherited_block_names,
          inherited_dependencies: peek.inherited_dependencies,
          inherited_lines: peek.inherited_lines
        )
      )
    end

    def post_execution_process
      do_save_execution_output
      output_execution_summary
      fout_execution_report if @delegate_object[:output_execution_report]
    end

    # Prepare the blocks menu by adding labels and other necessary details.
    #
    # @param all_blocks [Array<Hash>] The list of blocks from the file.
    # @param opts [Hash] The options hash.
    # @return [Array<Hash>] The updated blocks menu.
    def prepare_blocks_menu(menu_blocks)
      menu_blocks.map do |fcb|
        next if Filter.prepared_not_in_menu?(
          @delegate_object,
          fcb,
          %i[block_name_include_match block_name_wrapper_match]
        )

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
        unless @delegate_object[:no_chrome]
          create_and_add_chrome_blocks(blocks,
                                       fcb)
        end
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

    def prompt_for_command(prompt)
      print prompt

      gets.chomp
    rescue Interrupt
      nil
    end

    # Prompts the user to enter a path or name to substitute into the wildcard expression.
    # If interrupted by the user (e.g., pressing Ctrl-C), it returns nil.
    #
    # @param filespec [String] the wildcard expression to be substituted
    # @return [String, nil] the resolved path or substituted expression, or nil if interrupted
    def prompt_for_filespec_with_wildcard(filespec)
      puts format(@delegate_object[:prompt_show_expr_format],
                  { expr: filespec })
      puts @delegate_object[:prompt_enter_filespec]

      begin
        input = gets.chomp
        PathUtils.resolve_path_or_substitute(input, filespec)
      rescue Interrupt
        puts "\nOperation interrupted. Returning nil."
        nil
      end
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
    def prompt_for_user_approval(required_lines:, selected:)
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
        save_to_file(required_lines: required_lines, selected: selected)
      end

      sel == MenuOptions::YES
    rescue TTY::Reader::InputInterrupt
      exit 1
    end

    # public

    def prompt_select_code_filename(
      filenames,
      color_sym: :prompt_color_after_script_execution,
      string: @delegate_object[:prompt_select_code_file]
    )
      @prompt.select(
        string_send_color(string, color_sym),
        filter: true,
        per_page: @delegate_object[:select_page_height],
        quiet: true
      ) do |menu|
        filenames.each do |filename|
          menu.choice filename
        end
      end
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

    # user prompt to exit if the menu will be displayed again
    #
    def prompt_user_exit(block_name_from_cli:, selected:)
      selected[:shell] == BlockType::BASH &&
        @delegate_object[:pause_after_script_execution] &&
        prompt_select_continue == MenuState::EXIT
    end

    # Handles the processing of a link block in Markdown Execution.
    # It loads YAML data from the link_block_body content, pushes the state to history,
    # sets environment variables, and decides on the next block to load.
    #
    # @param link_block_body [Array<String>] The body content as an array of strings.
    # @param mdoc [Object] Markdown document object.
    # @param selected [FCB] Selected code block.
    # @return [LoadFileLinkState] Object indicating the next action for file loading.
    def push_link_history_and_trigger_load(link_block_body: [], mdoc: nil, selected: FCB.new,
                                           link_state: LinkState.new, block_source: {})
      link_block_data = HashDelegator.parse_yaml_data_from_body(link_block_body)

      ## collect blocks specified by block
      #
      if mdoc
        code_info = mdoc.collect_recursively_required_code(
          anyname: selected.pub_name,
          label_format_above: @delegate_object[:shell_code_label_format_above],
          label_format_below: @delegate_object[:shell_code_label_format_below],
          block_source: block_source
        )
        code_lines = code_info[:code]
        block_names = code_info[:block_names]
        dependencies = code_info[:dependencies]
      else
        block_names = []
        code_lines = []
        dependencies = {}
      end

      # load key and values from link block into current environment
      #
      if link_block_data[LinkKeys::VARS]
        code_lines.push BashCommentFormatter.format_comment(selected.pub_name)
        (link_block_data[LinkKeys::VARS] || []).each do |(key, value)|
          ENV[key] = value.to_s
          code_lines.push(assign_key_value_in_bash(key, value))
        end
      end

      ## append blocks loaded
      #
      if (load_expr = link_block_data.fetch(LinkKeys::LOAD, '')).present?
        load_filespec = load_filespec_from_expression(load_expr)
        if load_filespec
          code_lines += File.readlines(load_filespec,
                                       chomp: true)
        end
      end

      # if an eval link block, evaluate code_lines and return its standard output
      #
      if link_block_data.fetch(LinkKeys::EVAL,
                               false) || link_block_data.fetch(LinkKeys::EXEC,
                                                               false)
        code_lines = link_block_data_eval(link_state, code_lines, selected, link_block_data,
                                          block_source: block_source)
      end

      next_document_filename = write_inherited_lines_to_file(link_state,
                                                             link_block_data)
      next_block_name = link_block_data.fetch(LinkKeys::NEXT_BLOCK,
                                              nil) || link_block_data.fetch(LinkKeys::BLOCK,
                                                                            nil) || ''

      if link_block_data[LinkKeys::RETURN]
        pop_add_current_code_to_head_and_trigger_load(link_state, block_names, code_lines,
                                                      dependencies, selected, next_block_name: next_block_name)

      else
        link_history_push_and_next(
          curr_block_name: selected.pub_name,
          curr_document_filename: @delegate_object[:filename],
          inherited_block_names: ((link_state&.inherited_block_names || []) + block_names).sort.uniq,
          inherited_dependencies: (link_state&.inherited_dependencies || {}).merge(dependencies || {}), ### merge, not replace, key data
          inherited_lines: HashDelegator.code_merge(
            link_state&.inherited_lines, code_lines
          ),
          next_block_name: next_block_name,
          next_document_filename: next_document_filename,
          next_load_file: next_document_filename == @delegate_object[:filename] ? LoadFile::REUSE : LoadFile::LOAD
        )
      end
    end

    # Handle expression with wildcard characters
    # allow user to select or enter
    def puts_gets_oprompt_(filespec)
      puts format(@delegate_object[:prompt_show_expr_format],
                  { expr: filespec })
      puts @delegate_object[:prompt_enter_filespec]
      gets.chomp
    end

    # Processes YAML data from the selected menu item, updating delegate objects and optionally printing formatted output.
    # @param selected [Hash] Selected item from the menu containing a YAML body.
    # @param tgt2 [Hash, nil] An optional target hash to update with YAML data.
    # @return [LoadFileLinkState] An instance indicating the next action for loading files.
    def read_show_options_and_trigger_reuse(selected:,
                                            mdoc:, link_state: LinkState.new)
      obj = {}

      # concatenated body of all required blocks loaded a YAML
      data = YAML.load(
        collect_required_code_lines(
          mdoc: mdoc, selected: selected,
          link_state: link_state, block_source: {}
        ).join("\n")
      ).transform_keys(&:to_sym)

      if selected[:shell] == BlockType::OPTS
        obj = data
      else
        (data || []).each do |key, value|
          sym_key = key.to_sym
          obj[sym_key] = value

          if @delegate_object[:menu_opts_set_format].present?
            print_formatted_option(key, value)
          end
        end
      end

      link_state.block_name = nil
      OpenStruct.new(options: obj,
                     load_file_link_state: LoadFileLinkState.new(
                       LoadFile::REUSE, link_state
                     ))
    end

    # Registers console attributes by modifying the options hash.
    # This method handles terminal resizing and adjusts the console dimensions
    # and pagination settings based on the current terminal size.
    #
    # @param opts [Hash] a hash containing various options for the console settings.
    #   - :console_width [Integer, nil] The width of the console. If not provided or if the terminal is resized, it will be set to the current console width.
    #   - :console_height [Integer, nil] The height of the console. If not provided or if the terminal is resized, it will be set to the current console height.
    #   - :console_winsize [Array<Integer>, nil] The dimensions of the console [height, width]. If not provided or if the terminal is resized, it will be set to the current console dimensions.
    #   - :select_page_height [Integer, nil] The height of the page for selection. If not provided or if not positive, it will be set to the maximum of (console height - 3) or 4.
    #   - :per_page [Integer, nil] The number of items per page. If :select_page_height is not provided or if not positive, it will be set to the maximum of (console height - 3) or 4.
    #
    # @raise [StandardError] If an error occurs during the process, it will be caught and handled by calling HashDelegator.error_handler with 'register_console_attributes' and { abort: true }.
    #
    # @example
    #   opts = { console_width: nil, console_height: nil, select_page_height: nil }
    #   register_console_attributes(opts)
    #   # opts will be updated with the current console dimensions and pagination settings.
    def register_console_attributes(opts)
      if (resized = @delegate_object[:menu_resize_terminal])
        resize_terminal
      end

      if resized || !opts[:console_width]
        opts[:console_height], opts[:console_width] = opts[:console_winsize] =
          IO.console.winsize
      end

      unless opts[:select_page_height]&.positive?
        opts[:per_page] =
          opts[:select_page_height] =
            [opts[:console_height] - 3, 4].max
      end
    rescue StandardError
      HashDelegator.error_handler('register_console_attributes',
                                  { abort: true })
    end

    # Check if the delegate object responds to a given method.
    # @param method_name [Symbol] The name of the method to check.
    # @param include_private [Boolean] Whether to include private methods in the check.
    # @return [Boolean] true if the delegate object responds to the method, false otherwise.
    def respond_to?(method_name, include_private = false)
      if super
        true
      elsif @delegate_object.respond_to?(method_name, include_private)
        true
      elsif method_name.to_s.end_with?('=') && @delegate_object.respond_to?(:[]=,
                                                                            include_private)
        true
      else
        @delegate_object.respond_to?(method_name, include_private)
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

    # allow user to select or enter
    def save_filespec_from_expression(expression)
      # Process expression with embedded formatting
      formatted = formatted_expression(expression)

      # Handle wildcards or direct file specification
      if contains_wildcards?(formatted)
        save_filespec_wildcard_expansion(formatted)
      else
        formatted
      end
    end

    # Handle expression with wildcard characters
    # allow user to select or enter
    def save_filespec_wildcard_expansion(filespec)
      files = find_files(filespec)
      case files.count
      when 0
        prompt_for_filespec_with_wildcard(filespec)
      else
        ## user selects from existing files or other
        # input into path with wildcard for easy entry
        #
        case (name = prompt_select_code_filename(
          [@delegate_object[:prompt_filespec_back],
           @delegate_object[:prompt_filespec_other]] + files,
          string: @delegate_object[:prompt_select_code_file],
          color_sym: :prompt_color_after_script_execution
        ))
        when @delegate_object[:prompt_filespec_back]
          # do nothing
        when @delegate_object[:prompt_filespec_other]
          prompt_for_filespec_with_wildcard(filespec)
        else
          name
        end
      end
    end

    def save_to_file(required_lines:, selected:)
      write_command_file(required_lines: required_lines, selected: selected)
      @fout.fout "File saved: #{@run_state.saved_filespec}"
    end

    # Presents a TTY prompt to select an option or exit, returns metadata including option and selected
    def select_option_with_metadata(prompt_text, names, opts = {})
      ## configure to environment
      #
      register_console_attributes(opts)

      # crashes if all menu options are disabled
      selection = @prompt.select(prompt_text,
                                 names,
                                 opts.merge(filter: true))
      selected_name = names.find do |item|
        if item.instance_of?(Hash)
          item[:dname] == selection
        else
          item == selection
        end
      end
      if selected_name.instance_of?(String)
        selected_name = { dname: selected_name }
      end
      unless selected_name
        HashDelegator.error_handler('select_option_with_metadata',
                                    error: 'menu item not found')
        exit 1
      end

      selected_name.merge(
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

    # Update the block name in the link state and delegate object.
    #
    # This method updates the block name based on whether it was specified
    # through the CLI or derived from the link state.
    #
    # @param link_state [LinkState] The current link state object.
    # @param block_name_from_cli [Boolean] Indicates if the block name is from CLI.
    def set_delob_filename_block_name(link_state:, block_name_from_cli:)
      @delegate_object[:filename] = link_state.document_filename
      link_state.block_name = @delegate_object[:block_name] =
        block_name_from_cli ? @cli_block_name : link_state.block_name
    end

    def set_delobj_menu_loop_vars(block_name_from_cli:, now_using_cli:,
                                  link_state:)
      block_name_from_cli, now_using_cli =
        manage_cli_selection_state(block_name_from_cli: block_name_from_cli,
                                   now_using_cli: now_using_cli,
                                   link_state: link_state)
      set_delob_filename_block_name(link_state: link_state,
                                    block_name_from_cli: block_name_from_cli)

      # update @delegate_object and @menu_base_options in auto_load
      #
      blocks_in_file, menu_blocks, mdoc = mdoc_menu_and_blocks_from_nested_files(link_state)
      dump_delobj(blocks_in_file, menu_blocks, link_state)

      [block_name_from_cli, now_using_cli, blocks_in_file, menu_blocks, mdoc]
    end

    def set_environment_variables_for_block(selected)
      code_lines = []
      YAML.load(selected[:body].join("\n"))&.each do |key, value|
        ENV[key] = value.to_s

        require 'shellwords'
        code_lines.push "#{key}=\"#{Shellwords.escape(value)}\""

        next unless @delegate_object[:menu_vars_set_format].present?

        formatted_string = format(@delegate_object[:menu_vars_set_format],
                                  { key: key, value: value })
        print string_send_color(formatted_string, :menu_vars_set_color)
      end
      code_lines
    end

    def shell_escape_asset_format(link_state)
      raw = @delegate_object[:saved_asset_format]

      return raw unless @delegate_object[:shell_parameter_expansion]

      # unchanged if no parameter expansion takes place
      return raw unless /$/ =~ raw

      filespec = generate_temp_filename
      cmd = [@delegate_object[:shell], '-c', filespec].join(' ')

      marker = Random.new.rand.to_s

      code = (link_state&.inherited_lines || []) + ["echo -n \"#{marker}#{raw}\""]
      File.write filespec, HashDelegator.join_code_lines(code)
      File.chmod 0o755, filespec

      out = `#{cmd}`.sub(/.*?#{marker}/m, '')
      File.delete filespec
      out
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

      # disable fcb for data blocks
      disabled = fcb_title_groups.fetch(:shell, '') == 'yaml' ? '' : nil

      MarkdownExec::FCB.new(
        body: [],
        call: rest.match(Regexp.new(@delegate_object[:block_calls_scan]))&.to_a&.first,
        disabled: disabled,
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
          HashDelegator.update_menu_attrib_yield_selected(
            fcb: state[:fcb],
            messages: selected_messages,
            configuration: @delegate_object,
                                                          &block
          )
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

    ## apply options to current state
    #
    def update_menu_base(options)
      @menu_base_options.merge!(options)
      @delegate_object.merge!(options)
    end

    def wait_for_stream_processing
      @process_mutex.synchronize do
        @process_cv.wait(@process_mutex)
      end
    rescue Interrupt
      # user interrupts process
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
      if block_menu.empty?
        return SelectedBlockMenuState.new(nil,
                                          MenuState::EXIT)
      end

      # default value may not match if color is different from originating menu (opts changed while processing)
      selection_opts = if default && menu_blocks.map(&:dname).include?(default)
                         @delegate_object.merge(default: default)
                       else
                         @delegate_object
                       end

      sph = @delegate_object[:select_page_height]
      selection_opts.merge!(per_page: sph)

      selected_option = select_option_with_metadata(prompt_title, block_menu,
                                                    selection_opts)
      determine_block_state(selected_option)
    end

    # Handles the core logic for generating the command file's metadata and content.
    def write_command_file(required_lines:, selected:)
      return unless @delegate_object[:save_executed_script]

      time_now = Time.now.utc
      @run_state.saved_script_filename =
        SavedAsset.new(blockname: selected.pub_name,
                       exts: '.sh',
                       filename: @delegate_object[:filename],
                       prefix: @delegate_object[:saved_script_filename_prefix],
                       saved_asset_format: shell_escape_asset_format(@dml_link_state),
                       time: time_now).generate_name
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

    # Ensure the directory exists before writing the file
    def write_file_with_directory_creation(save_filespec, content)
      directory = File.dirname(save_filespec)

      begin
        FileUtils.mkdir_p(directory)
        File.write(save_filespec, content)
      rescue Errno::EACCES
        warn "Permission denied: Unable to write to file '#{save_filespec}'"
        nil
      rescue Errno::EROFS
        warn "Read-only file system: Unable to write to file '#{save_filespec}'"
        nil
      rescue StandardError => err
        warn "An error occurred while writing to file '#{save_filespec}': #{err.message}"
        nil
      end
    end

    # return next document file name
    def write_inherited_lines_to_file(link_state, link_block_data)
      save_expr = link_block_data.fetch(LinkKeys::SAVE, '')
      if save_expr.present?
        save_filespec = save_filespec_from_expression(save_expr)
        File.write(save_filespec,
                   HashDelegator.join_code_lines(link_state&.inherited_lines))
        @delegate_object[:filename]
      else
        link_block_data[LinkKeys::FILE] || @delegate_object[:filename]
      end
    end
  end

  class HashDelegator < HashDelegatorParent
    # Cleans a value, handling both Hash and Struct types.
    # For Structs, the cleaned version is converted to a hash.
    def self.clean_value(value)
      case value
      when Hash
        clean_hash_recursively(value)
      when Struct
        struct_hash = value.to_h # Convert the Struct to a hash
        clean_hash_recursively(struct_hash) # Clean the hash
        # Return the cleaned hash instead of updating the Struct

      else
        value
      end
    end

    # Recursively cleans the given object (hash or struct) from unwanted values.
    def self.clean_hash_recursively(obj)
      obj.each do |key, value|
        cleaned_value = clean_value(value) # Clean and possibly convert value
        obj[key] = cleaned_value if value.is_a?(Hash) || value.is_a?(Struct)
      end

      if obj.is_a?(Hash)
        obj.reject! do |_key, value|
          [nil, '', [], {}, nil].include?(value)
        end
      end

      obj
    end

    def self.next_link_state(*args, **kwargs, &block)
      super
    end
  end
end

return if $PROGRAM_NAME != __FILE__

require 'bundler/setup'
Bundler.require(:default)

require 'minitest/autorun'
require 'mocha/minitest'

class BashCommentFormatterTest < Minitest::Test
  # Test formatting a normal string without special characters
  def test_format_simple_string
    input = 'This is a simple comment.'
    expected = '# This is a simple comment.'
    assert_equal expected, BashCommentFormatter.format_comment(input)
  end

  # Test formatting a string containing hash characters
  def test_format_string_with_hash
    input = 'This is a #comment with hash.'
    expected = '# This is a \\#comment with hash.'
    assert_equal expected, BashCommentFormatter.format_comment(input)
  end

  # Test formatting an empty string
  def test_format_empty_string
    input = ''
    expected = '# '
    assert_equal expected, BashCommentFormatter.format_comment(input)
  end

  # Test formatting a multi-line string
  def test_format_multi_line_string
    input = "This is the first line.\nThis is the second line."
    expected = "# This is the first line.\n# This is the second line."
    assert_equal expected, BashCommentFormatter.format_comment(input)
  end

  # Test formatting strings with leading and trailing whitespace
  def test_format_whitespace
    input = '  This has leading and trailing spaces  '
    expected = '#   This has leading and trailing spaces  '
    assert_equal expected, BashCommentFormatter.format_comment(input)
  end
end

module MarkdownExec
  class TestHashDelegator0 < Minitest::Test
    def setup
      @hd = HashDelegator.new
    end

    # Test case for empty body
    def test_next_link_state
      @hd.next_link_state(block_name_from_cli: nil, was_using_cli: nil, block_state: nil,
                          block_name: nil)
    end
  end

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
      assert_equal LoadFile::REUSE,
                   @hd.push_link_history_and_trigger_load.load_file
    end

    # Test case for non-empty body without 'file' key
    def test_push_link_history_and_trigger_load_without_file_key
      body = ["vars:\n  KEY: VALUE"]
      assert_equal LoadFile::REUSE,
                   @hd.push_link_history_and_trigger_load(link_block_body: body).load_file
    end

    # Test case for non-empty body with 'file' key
    def test_push_link_history_and_trigger_load_with_file_key
      body = ["file: sample_file\nblock: sample_block\nvars:\n  KEY: VALUE"]
      expected_result = LoadFileLinkState.new(
        LoadFile::LOAD,
        LinkState.new(block_name: 'sample_block',
                      document_filename: 'sample_file',
                      inherited_dependencies: {},
                      inherited_lines: ['# ', 'KEY="VALUE"'])
      )
      assert_equal expected_result,
                   @hd.push_link_history_and_trigger_load(
                     link_block_body: body,
                     selected: FCB.new(block_name: 'sample_block',
                                       filename: 'sample_file')
                   )
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
      assert_raises(SystemExit) do
        HashDelegator.safeval('invalid_code_raises_exception')
      end
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
        @hd.append_divider(menu_blocks: menu_blocks, position: :initial)

        assert_equal 1, menu_blocks.size
        assert_equal 'Formatted Divider', menu_blocks.first.dname
      end

      def test_append_divider_final
        menu_blocks = []
        @hd.append_divider(menu_blocks: menu_blocks, position: :final)

        assert_equal 1, menu_blocks.size
        assert_equal 'Formatted Divider', menu_blocks.last.dname
      end

      def test_append_divider_without_format
        @hd.instance_variable_set(:@delegate_object, {})
        menu_blocks = []
        @hd.append_divider(menu_blocks: menu_blocks, position: :initial)

        assert_empty menu_blocks
      end
    end

    class TestHashDelegatorBlockFind < Minitest::Test
      def setup
        @hd = HashDelegator.new
      end

      def test_block_find_with_match
        blocks = [FCB.new(text: 'value1'), FCB.new(text: 'value2')]
        result = HashDelegator.block_find(blocks, :text, 'value1')
        assert_equal('value1', result.text)
      end

      def test_block_find_without_match
        blocks = [FCB.new(text: 'value1'), FCB.new(text: 'value2')]
        result = HashDelegator.block_find(blocks, :text, 'missing_value')
        assert_nil result
      end

      def test_block_find_with_default
        blocks = [FCB.new(text: 'value1'), FCB.new(text: 'value2')]
        result = HashDelegator.block_find(blocks, :text, 'missing_value', 'default')
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
        result = @hd.collect_required_code_lines(mdoc: @mdoc, selected: @selected,
                                                 block_source: {})

        assert_equal ['code line', 'key="value"'], result
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

        result = @hd.load_cli_or_user_selected_block(all_blocks: all_blocks)

        assert_equal all_blocks.first.merge(block_name_from_ui: false),
                     result.block
        assert_nil result.state
      end

      def test_user_selected_block
        block_state = SelectedBlockMenuState.new({ oname: 'block2' },
                                                 :some_state)
        @hd.stubs(:wait_for_user_selected_block).returns(block_state)

        result = @hd.load_cli_or_user_selected_block

        assert_equal block_state.block.merge(block_name_from_ui: true),
                     result.block
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
        selected_option = FCB.new(oname: 'Formatted Option')
        @hd.stubs(:menu_chrome_formatted_option).with(:menu_option_exit_name).returns('Formatted Option')

        result = @hd.determine_block_state(selected_option)

        assert_equal MenuState::EXIT, result.state
        assert_nil result.block
      end

      def test_determine_block_state_back
        selected_option = FCB.new(oname: 'Formatted Back Option')
        @hd.stubs(:menu_chrome_formatted_option).with(:menu_option_back_name).returns('Formatted Back Option')
        result = @hd.determine_block_state(selected_option)

        assert_equal MenuState::BACK, result.state
        assert_equal selected_option, result.block
      end

      def test_determine_block_state_continue
        selected_option = FCB.new(oname: 'Other Option')

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

        @hd.display_required_code(required_lines: required_lines)

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

      def test_format_execution_stream_with_valid_key
        result = HashDelegator.format_execution_stream(
          { stdout: %w[output1 output2] },
          ExecutionStreams::STD_OUT
        )

        assert_equal "output1\noutput2", result
      end

      def test_format_execution_stream_with_empty_key
        @hd.instance_variable_get(:@run_state).stubs(:files).returns({})

        result = HashDelegator.format_execution_stream(nil,
                                                       ExecutionStreams::STD_ERR)

        assert_equal '', result
      end

      def test_format_execution_stream_with_nil_files
        @hd.instance_variable_get(:@run_state).stubs(:files).returns(nil)

        result = HashDelegator.format_execution_stream(nil, :stdin)

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
        assert_equal LoadFile::LOAD, result.load_file
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
        file_type = ExecutionStreams::STD_OUT

        Thread.new { @hd.handle_stream(stream: stream, file_type: file_type) }

        @hd.wait_for_stream_processing

        assert_equal ['line 1', 'line 2'],
                     @hd.instance_variable_get(:@run_state).files[ExecutionStreams::STD_OUT]
      end

      def test_handle_stream_with_io_error
        stream = StringIO.new("line 1\nline 2\n")
        file_type = ExecutionStreams::STD_OUT
        stream.stubs(:each_line).raises(IOError)

        Thread.new { @hd.handle_stream(stream: stream, file_type: file_type) }

        @hd.wait_for_stream_processing

        assert_equal [],
                     @hd.instance_variable_get(:@run_state).files[ExecutionStreams::STD_OUT]
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
        @hd.cfile.expect(:readlines, ['line 1', 'line 2'], ['test.md'],
                         import_paths: nil)
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
      HashDelegator.yield_line_if_selected('Test line',
                                           [:line]) do |type, content|
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
      Filter.expects(:yield_to_block_if_applicable).with(@fcb, [:some_message],
                                                         {})

      HashDelegator.update_menu_attrib_yield_selected(fcb: @fcb,
                                                      messages: [:some_message])
    end

    def test_update_menu_attrib_yield_selected_without_body
      @fcb.stubs(:body).returns(nil)
      HashDelegator.expects(:initialize_fcb_names).with(@fcb)
      HashDelegator.update_menu_attrib_yield_selected(fcb: @fcb,
                                                      messages: [:some_message])
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

  class PathUtilsTest < Minitest::Test
    def test_absolute_path_returns_unchanged
      absolute_path = '/usr/local/bin'
      expression = 'path/to/*/directory'
      assert_equal absolute_path,
                   PathUtils.resolve_path_or_substitute(absolute_path,
                                                        expression)
    end

    def test_relative_path_gets_substituted
      relative_path = 'my_folder'
      expression = 'path/to/*/directory'
      expected_output = 'path/to/my_folder/directory'
      assert_equal expected_output,
                   PathUtils.resolve_path_or_substitute(relative_path,
                                                        expression)
    end

    def test_path_with_no_slash_substitutes_correctly
      relative_path = 'data'
      expression = 'path/to/*/directory'
      expected_output = 'path/to/data/directory'
      assert_equal expected_output,
                   PathUtils.resolve_path_or_substitute(relative_path,
                                                        expression)
    end

    def test_empty_path_substitution
      empty_path = ''
      expression = 'path/to/*/directory'
      expected_output = 'path/to//directory'
      assert_equal expected_output,
                   PathUtils.resolve_path_or_substitute(empty_path, expression)
    end

    # Test formatting a string containing UTF-8 characters
    def test_format_utf8_characters
      input = 'Unicode test: ā, ö, 💻, and 🚀 are fun!'
      expected = '# Unicode test: ā, ö, 💻, and 🚀 are fun!'
      assert_equal expected, BashCommentFormatter.format_comment(input)
    end
  end

  class PromptForFilespecWithWildcardTest < Minitest::Test
    def setup
      @delegate_object = {
        prompt_show_expr_format: 'Current expression: %{expr}',
        prompt_enter_filespec: 'Please enter a filespec:'
      }
      @original_stdin = $stdin
    end

    def teardown
      $stdin = @original_stdin
    end

    def test_prompt_for_filespec_with_normal_input
      $stdin = StringIO.new("test_input\n")
      result = prompt_for_filespec_with_wildcard('*.txt')
      assert_equal 'resolved_path_or_substituted_value', result
    end

    def test_prompt_for_filespec_with_interruption
      $stdin = StringIO.new
      # rubocop disable:Lint/NestedMethodDefinition
      def $stdin.gets; raise Interrupt; end
      # rubocop enable:Lint/NestedMethodDefinition

      result = prompt_for_filespec_with_wildcard('*.txt')
      assert_nil result
    end

    def test_prompt_for_filespec_with_empty_input
      $stdin = StringIO.new("\n")
      result = prompt_for_filespec_with_wildcard('*.txt')
      assert_equal 'resolved_path_or_substituted_value', result
    end

    private

    def prompt_for_filespec_with_wildcard(filespec)
      puts format(@delegate_object[:prompt_show_expr_format],
                  { expr: filespec })
      puts @delegate_object[:prompt_enter_filespec]

      begin
        input = gets.chomp
        PathUtils.resolve_path_or_substitute(input, filespec)
      rescue Interrupt
        nil
      end
    end

    module PathUtils
      def self.resolve_path_or_substitute(input, filespec)
        'resolved_path_or_substituted_value' # Placeholder implementation
      end
    end
  end
end # module MarkdownExec
