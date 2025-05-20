#!/usr/bin/env -S bundle exec ruby
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

require_relative 'ansi_string'
require_relative 'array'
require_relative 'array_util'
require_relative 'block_types'
require_relative 'cached_nested_file_reader'
require_relative 'command_result'
require_relative 'constants'
require_relative 'directory_searcher'
require_relative 'error_reporting'
require_relative 'evaluate_shell_expressions'
require_relative 'exceptions'
require_relative 'fcb'
require_relative 'filter'
require_relative 'format_table'
require_relative 'fout'
require_relative 'hash'
require_relative 'hierarchy_string'
require_relative 'link_history'
require_relative 'mdoc'
require_relative 'namer'
require_relative 'regexp'
require_relative 'resize_terminal'
require_relative 'streams_out'
require_relative 'string_util'
require_relative 'table_extractor'
require_relative 'text_analyzer'
require_relative 'value_or_exception'

$pd = false unless defined?($pd)
$table_cell_truncate = true
EXIT_STATUS_REQUIRED_EMPTY = 248

module HashDelegatorSelf
  # Applies an ANSI color method to a string using a specified color key.
  # The method retrieves the color method from the provided hash. If the
  # color key is not present in the hash, it uses a default color method.
  # @param string [String] The string to be colored.
  # @param color_methods [Hash] A hash where keys are color names
  #   (String/Symbol) and values are color methods.
  # @param color_key [String, Symbol] The key representing
  #  the desired
  #   color method in the color_methods hash.
  # @param default_method [String] (optional) Default color method to
  #   use if color_key is not found in color_methods. Defaults to 'plain'.
  # @return [String] The colored string.
  def apply_color_from_hash(string, color_methods, color_key,
                            default_method: 'plain')
    color_method = color_methods.fetch(color_key, default_method).to_sym
    AnsiString.new(string.to_s).send(color_method)
  end

  # Searches for the first element in a collection where the specified
  # message sent to an element matches a given value.
  # This method is particularly useful for finding a specific hash-like
  # object within an enumerable collection.
  # If no match is found, it returns a specified default value.
  #
  # @param blocks [Enumerable] The collection of hash-like
  #  objects to search.
  # @param msg [Symbol, String] The message to send to each element of
  #  the collection.
  # @param value [Object] The value to match against the result of the message
  #  sent to each element.
  # @param default [Object, nil] The default value to return if no match is
  #  found (optional).
  # @return [Object, nil] The first matching element or the default value if
  #  no match is found.
  def block_find(blocks, msg, value, default = nil)
    blocks.find { |item| item.send(msg) == value } || default
  end

  def block_match(blocks, msg, value, default = nil)
    blocks.select { |item| value =~ item.send(msg) }
  end

  def block_select(blocks, msg, value, default = nil)
    blocks.select { |item| item.send(msg) == value }
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

  # Creates a file at the specified path, writes the given
  #  content to it, and sets file permissions if required.
  # Handles any errors encountered during the process.
  #
  # @param file_path [String] The path where the file will
  #  be created.
  # @param content [String] The content to write into the file.
  # @param chmod_value [Integer] The file permission value
  #  to set; skips if zero.
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

  # Updates the title of an FCB object from its body content if the title
  # is nil or empty.
  def default_block_title_from_body(fcb)
    return fcb.title unless fcb.title.nil? || fcb.title.empty?

    fcb.derive_title_from_body
  end

  # delete the current line if it is empty and the previous is also empty
  def delete_consecutive_blank_lines!(blocks_menu)
    blocks_menu.process_and_conditionally_delete! do
      |prev_item, current_item, _next_item|
      !current_item.is_split? &&
        prev_item&.fetch(:chrome, nil) &&
        !(prev_item && prev_item.oname.present?) &&
        current_item&.fetch(:chrome, nil) &&
        !(current_item && current_item.oname.present?)
    end
  end

  def error_handler(name = '', opts = {}, error: $!)
    Exceptions.error_handler(
      "HashDelegator.#{name} -- #{error}",
      opts
    )
  end

  # Indents all lines in a given string with a specified indentation string.
  # @param body [String] A multi-line string to be indented.
  # @param indent [String] The string used for indentation
  #  (default is an empty string).
  # @return [String] A single string with each line indented as specified.
  def indent_all_lines(body, indent = nil)
    return body unless indent&.present?

    body.lines.map { |line| indent + line.chomp }.join("\n")
  end

  def initialize_fcb_names(fcb)
    fcb.oname = fcb.dname = fcb.title || ''
    fcb.s2title = fcb.oname
  end

  def join_code_lines(lines)
    ((lines || []) + ['']).join("\n")
  end

  def merge_lists(*args)
    # Filters out nil values, flattens the arrays, and ensures an
    #  empty list is returned if no valid lists are provided.
    merged = args.compact.flatten
    merged.empty? ? [] : merged
  end

  def next_link_state(
    block_name_from_cli:, was_using_cli:, block_state:, block_name: nil
  )
    # Set block_name based on block_name_from_cli
    block_name = @cli_block_name if block_name_from_cli

    # Determine the state of breaker based on was_using_cli and the block type
    # true only when block_name is nil, block_name_from_cli is false,
    # was_using_cli is true, and the block_state.block.shell equals
    # BlockType::BASH. In all other scenarios, breaker is false.
    breaker = !block_name &&
              !block_name_from_cli &&
              was_using_cli &&
              block_state.block.type == BlockType::SHELL

    # Reset block_name_from_cli if the conditions are not met
    block_name_from_cli ||= false

    [block_name, block_name_from_cli, breaker]
  end

  def parse_yaml_data_from_body(body)
    body&.any? ? YAML.load(body.join("\n")) : {}
  rescue StandardError
    error_handler("parse_yaml_data_from_body for body: #{body}",
                  { abort: true })
  end

  # Reads required code blocks from a temporary file specified
  #  by an environment variable.
  # @return [Array<String>] Lines read from the temporary file, or
  #  an empty array if file is not found or path is empty.
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
    # allowed_methods = %w[+ - * / == != < > <= >= && || % &
    #  |]
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

  # find tables in multiple lines and format horizontally
  def tables_into_columns!(blocks_menu, delegate_object, screen_width_for_table)
    return unless delegate_object[:tables_into_columns]

    lines = blocks_menu.map(&:oname)
    text_tables = TableExtractor.extract_tables(
      lines,
      regexp: delegate_object[:table_parse_regexp]
    )
    return unless text_tables.count.positive?

    text_tables.each do |table|
      next unless table[:columns].positive?

      range = table[:start_index]..(table[:start_index] + table[:rows] - 1)
      lines = blocks_menu[range].map(&:dname)
      table__hs = MarkdownTableFormatter.format_table__hs(
        column_count: table[:columns],
        decorate: {
          border: delegate_object[:table_border_color],
          header_row: delegate_object[:table_header_row_color],
          row: delegate_object[:table_row_color],
          separator_line: delegate_object[:table_separator_line_color]
        },
        lines: lines,
        table_width: screen_width_for_table,
        truncate: $table_cell_truncate
      )

      exceeded_table_cell = false # any cell in table is exceeded
      truncated_table_cell = false # any cell in table is truncated
      table__hs.each do |table_hs|
        table_hs.substrings.each do |substrings|
          substrings.each do |node|
            next unless node[:text].instance_of?(TrackedString)

            exceeded_table_cell ||= node[:text].exceeded
            truncated_table_cell = node[:text].truncated
            break if truncated_table_cell
          end
          break if truncated_table_cell
        end
        break if truncated_table_cell
      end

      unless table__hs.count == range.size
        raise 'Invalid result from MarkdownTableFormatter.format_table()'
      end

      # read indentation from first line
      indent = blocks_menu[range.first].oname.split('|', 2).first

      # replace text in each block
      range.each.with_index do |block_ind, ind|
        fcb = blocks_menu[block_ind]
        fcb.s3formatted_table_row = fcb.padded = table__hs[ind]
        fcb.padded_width = table__hs[ind].padded_width
        if fcb.center
          cw = (screen_width_for_table - table__hs[ind].padded_width) / 2
          if cw.positive?
            indent = ' ' * cw
            fcb.s3indent = fcb.indent = indent
          end
        else
          fcb.s3indent = fcb.indent
        end
        fcb.s3indent ||= ''
        fcb.dname = fcb.indented_decorated = fcb.s3indent + fcb.s3formatted_table_row.decorate

        if ind.zero?
          fcb.truncated_table_cell = truncated_table_cell
          if exceeded_table_cell
            fcb.delete_key(:disabled)
          end
        end
      end
    end
  end
  # s0indent: indent,
  # s0printable: line_obj[:text],
  # s1decorated: decorated,
  # s2title = fcb.oname
  # s3formatted_table_row = fcb.padded = table__hs[ind]

  # Creates a TTY prompt with custom settings. Specifically,
  #  it disables the default 'cross' symbol and
  # defines a lambda function to handle interrupts.
  # @return [TTY::Prompt] A new TTY::Prompt instance
  #  with specified configurations.
  def tty_prompt_without_disabled_symbol
    TTY::Prompt.new(
      interrupt: lambda {
        puts # next line in case not at start
        raise TTY::Reader::InputInterrupt
      },
      symbols: { cross: ' ' }
    )
  end

  # Updates the attributes of the given fcb object and
  #  conditionally yields to a block.
  # It initializes fcb names and sets the default block title from fcb's body.
  # If the fcb has a body and meets certain conditions,
  #  it yields to the given block.
  #
  # @param fcb [Object] The fcb object whose attributes are to be updated.
  # @param selected_types [Array<Symbol>] A list of message types to
  #  determine if yielding is applicable.
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
  # @param [Array<Symbol>] selected_types A list of message types to check.
  # @param [Proc] block The block to be called with the line data.
  def yield_line_if_selected(line, selected_types, all_fcbs: nil,
                             source_id: '', &block)
    return unless block && block_type_selected?(selected_types, :line)

    block.call(:line, persist_fcb_self(all_fcbs, body: [line], id: source_id))
  end

  def persist_fcb_self(all_fcbs, options)
    raise if all_fcbs.nil?

    # if the id is present, update the existing fcb
    if options[:id]
      fcb = all_fcbs.find { |fcb| fcb.id == options[:id] }
      if fcb
        fcb.update(options)
        return fcb
      end
    end
    MarkdownExec::FCB.new(options).tap do |fcb|
      all_fcbs << fcb
    end
  end
end

# This module provides methods for compacting and converting data structures.
module CompactionHelpers
  # Converts an array of key-value pairs into a hash,
  #  applying compaction to the values.
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
  # It filters out nil, empty arrays, empty hashes,
  #  and empty strings from its values.
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

  # Converts a hash into another hash with indexed keys,
  #  applying compaction to the values.
  # The keys are indexed, and the values are
  #  compacted using `compact_and_convert_array_to_hash`.
  #
  # @param hash [Hash] The hash to be converted and compacted.
  # @return [Hash] A hash with indexed keys and the compacted original values.
  def compact_and_index_hash(hash)
    compact_and_convert_array_to_hash(hash.map.with_index do |value, index|
                                        [index, value]
                                      end.to_h)
  end

  private

  # Determines if a value is ineligible for inclusion in a
  #  compacted hash.
  # Ineligible values are nil, empty arrays, empty hashes,
  #  and empty strings.
  #
  # @param value [Object] The value to be checked.
  # @return [Boolean] True if the value is ineligible, false otherwise.
  def value_ineligible?(value)
    [nil, [], {}, ''].include?(value)
  end
end

module PathUtils
  # Determines if a given path is absolute or substitutes a
  #  placeholder in an expression with the path.
  # @param path [String] The input path to check or fill in.
  # @param expression [String] The expression where a wildcard
  #  '*' is replaced by the path if it's not absolute.
  # @return [String] The absolute path or the expression with
  #  the wildcard replaced by the path.
  def self.resolve_path_or_substitute(path, expression)
    if path.start_with?('/')
      path
    else
      expression.gsub('*', path)
    end
  end
end

class BashCommentFormatter
  # Formats a multi-line string into a format safe for use
  #  in Bash comments.
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
  # @param right_margin [Integer] the number of spaces for
  #  the right margin
  # @param indent [Integer] the number of
  #  spaces to indent all but the first line
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
    attr_accessor :pass_args, :run_state,
                  :p_all_arguments, :p_options_parsed, :p_params, :p_rest

    extend HashDelegatorSelf
    include CompactionHelpers
    include TextAnalyzer

    def initialize(delegate_object = {})
      @delegate_object = delegate_object
      @prompt = HashDelegator.tty_prompt_without_disabled_symbol

      @opts_most_recent_filename = nil
      @ux_most_recent_filename = nil
      @vars_most_recent_filename = nil
      @pass_args = []
      @run_state = OpenStruct.new(
        link_history: [],
        source: OpenStruct.new
      )
      @link_history = LinkHistory.new
      @fout = FOut.new(@delegate_object) ### slice only relevant keys

      @process_mutex = Mutex.new
      @process_cv = ConditionVariable.new
      @dml_link_state = Struct.new(:document_filename, :inherited_lines)
                              .new(@delegate_object[:filename], [])
      @dml_menu_blocks = []
      @fcb_store = [] # all fcbs created

      @p_all_arguments = []
      @p_options_parsed = []
      @p_params = {}
      @p_rest = []

      @compressed_ids = {}
      @expanded_ids = {}
    end

    ##
    # Returns the absolute path of the given file path.
    # If the provided path is already absolute, it returns it as is.
    # Otherwise, it prefixes the path with the current working directory.
    #
    # @param file_path [String] The file path to process
    # @return [String] The absolute path
    #
    # Example usage:
    #   absolute_path('/absolute/path/to/file.txt') # => '/absolute/path/to/file.txt'
    #   absolute_path('relative/path/to/file.txt') # => '/current/working/directory/relative/path/to/file.txt'
    #
    def absolute_path(file_path)
      if File.absolute_path?(file_path)
        file_path
      else
        File.join(Dir.getwd, file_path)
      end
    end

    def add_back_option(menu_blocks:, source_id: '')
      append_chrome_block(
        menu_blocks: menu_blocks,
        menu_state: MenuState::BACK,
        source_id: source_id
      )
    end

    def add_exit_option(menu_blocks:, source_id: '')
      append_chrome_block(
        menu_blocks: menu_blocks,
        menu_state: MenuState::EXIT,
        source_id: source_id
      )
    end

    def add_inherited_lines(link_state:, menu_blocks:)
      append_inherited_lines(
        link_state: link_state,
        menu_blocks: menu_blocks
      )
    end

    # Modifies the provided menu blocks array by adding 'Back' and 'Exit' options,
    # along with initial and final dividers, based on the delegate object's configuration.
    #
    # @param menu_blocks [Array] The array of menu block elements to be modified.
    def add_menu_chrome_blocks!(link_state:, menu_blocks:, source_id: '')
      return unless @delegate_object[:menu_link_format].present?

      add_inherited_lines(
        link_state: link_state,
        menu_blocks: menu_blocks
      ) if @delegate_object[:menu_with_inherited_lines]

      # back before exit
      add_back_option(
        menu_blocks: menu_blocks,
        source_id: "#{source_id}.back"
      ) if should_add_back_option?

      # exit after other options

      add_exit_option(
        menu_blocks: menu_blocks,
        source_id: "#{source_id}.exit"
      ) if @delegate_object[:menu_with_exit]

      append_divider(
        menu_blocks: menu_blocks,
        position: :initial,
        source_id: "#{source_id}.init"
      )

      append_divider(
        menu_blocks: menu_blocks,
        position: :final,
        source_id: "#{source_id}.final"
      )
    end

    # Appends a chrome block, which is a menu option for Back or Exit
    #
    # @param all_blocks [Array] The current blocks in the menu
    # @param type [Symbol] The type of chrome block to add (:back or :exit)
    def append_chrome_block(menu_blocks:, menu_state:, source_id: '')
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
      chrome_block = persist_fcb(
        chrome: true,
        dname: HashDelegator.new(@delegate_object).string_send_color(
          formatted_name, :menu_chrome_color
        ),
        id: source_id.to_s,
        type: BlockType::CHROME,
        nickname: formatted_name,
        oname: formatted_name
      )

      if insert_at_top
        menu_blocks.unshift(chrome_block)
      else
        menu_blocks.push(chrome_block)
      end

      chrome_block
    end

    # Appends a formatted divider to the specified position in a menu block array.
    # The method checks for the presence of formatting options before appending.
    #
    # @param menu_blocks [Array] The array of menu block elements.
    # @param position [Symbol] The position to insert the divider (:initial or :final).
    def append_divider(menu_blocks:, position:, source_id: '')
      return unless divider_formatting_present?(position)

      divider = create_divider(position, source_id: source_id)
      position == :initial ? menu_blocks.unshift(divider) : menu_blocks.push(divider)
    end

    # Appends a formatted divider to the specified position in a menu block array.
    # The method checks for the presence of formatting options before appending.
    #
    # @param menu_blocks [Array] The array of menu block elements.
    # @param position [Symbol] The position to insert the divider (:initial or :final).
    def append_inherited_lines(link_state:, menu_blocks:, position: top)
      return unless link_state.inherited_lines_present?

      insert_at_top = @delegate_object[:menu_inherited_lines_at_top]
      chrome_blocks = link_state.inherited_lines_map do |line|
        formatted = format(@delegate_object[:menu_inherited_lines_format],
                           { line: line })
        persist_fcb(
          chrome: true,
          disabled: TtyMenu::DISABLE,
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

    # private

    # Applies shell color options to the given string if applicable.
    #
    # @param name [String] The name to potentially colorize.
    # @param block_type_color_option [Symbol, nil] The shell color option to apply.
    # @return [String] The colorized or original name string.
    def apply_block_type_color_option(name, block_type_color_option)
      if block_type_color_option && @delegate_object[block_type_color_option].present?
        string_send_color(name, block_type_color_option)
      else
        name
      end
    end

    def apply_tree_decorations(text, color_method, decor_patterns)
      tree = HierarchyString.new([{ text: text, color: color_method }])
      if color_method
        decor_patterns.each do |pc|
          analyzed_hierarchy = TextAnalyzer.analyze_hierarchy(
            tree.substrings, pc[:pattern],
            color_method, pc[:color_method]
          )
          tree = HierarchyString.new(analyzed_hierarchy)
        end
      end
      tree.decorate
    end

    def assign_key_value_in_bash(key, value)
      if value.to_s =~ /["$\\`]/
        # requiring ShellWords to write into Bash scripts
        "#{key}=#{Shellwords.escape(value)}"
      else
        "#{key}=\"#{value}\""
      end
    end

    # Iterates through nested files to collect various types
    #  of blocks, including dividers, tasks, and others.
    # The method categorizes blocks based on their type and processes them accordingly.
    #
    # @return [Array<FCB>] An array of FCB objects representing the blocks.
    def blocks_from_nested_files(
      link_state: @dml_link_state || LinkState.new,
      source_id: nil
    )
      register_console_attributes(@delegate_object)
      @decor_patterns_from_delegate_object_for_block_create = collect_line_decor_patterns(@delegate_object)

      count = 0
      blocks = []
      results = {}
      iter_blocks_from_nested_files do |btype, fcb|
        count += 1
        case btype
        when :blocks
          result = SuccessResult.instance
          if @delegate_object[:bash]
            begin
              mf = MenuFilter.new(@delegate_object)
              if fcb.body.count > 1 && mf.fcb_in_menu?(fcb) && fcb.is_split_displayed?(@delegate_object)
                # make multiple FCB blocks, one for each line; only the first is active
                id_prefix = "#{fcb.id}¤BlkFrmNstFls®block:#{count}©body:"
                fcb0 = fcb
                menu_lines = fcb.body
                menu_lines.each.with_index do |menu_line, index|
                  is_enabled_but_inactive = ((index + 1) % (@delegate_object[:select_page_height] / 2)).zero?
                  if index.zero?
                    # fcb.body = [menu_line]
                    # fcb.center = center
                    # fcb.collapse = collapse.nil? ? (line_obj[:collapse] == COLLAPSIBLE_TOKEN_COLLAPSE) : collapse
                    # fcb.disabled = disabled ? TtyMenu::DISABLE : nil
                    fcb.dname = fcb.indent + menu_line
                    fcb.id = "#{id_prefix}#{index}"
                    # fcb.indent = line_obj[:indent]
                    fcb.is_split_first = true # the first block in a split
                    fcb.is_split_rest = false
                    # fcb.level = level
                    # fcb.oname # computed
                    # fcb.s0indent = indent
                    fcb.s0printable = menu_line
                    fcb.s1decorated = menu_line
                    fcb.text = menu_line
                    # fcb.token = line_obj[:collapse]
                    # fcb.type = type
                  else
                    fcb = persist_fcb(
                      body: fcb0.body,
                      center: fcb0.center,
                      chrome: true,
                      collapse: false,
                      disabled: is_enabled_but_inactive ? TtyMenu::ENABLE : TtyMenu::DISABLE,
                      dname: fcb0.indent + menu_line,
                      id: "#{id_prefix}#{index}",
                      indent: fcb0.indent,
                      is_enabled_but_inactive: is_enabled_but_inactive,
                      is_split_first: false,
                      is_split_rest: true, # subsequent blocks in a split
                      level: fcb0.level,
                      s0indent: fcb0.s0indent,
                      s0printable: menu_line,
                      s1decorated: menu_line,
                      start_line: fcb0.start_line,
                      text: menu_line,
                      # token: ,
                      type: fcb0.type
                    )
                  end

                  result = fcb.for_menu!(
                    block_calls_scan: @delegate_object[:block_calls_scan],
                    block_name_match: @delegate_object[:block_name_match],
                    block_name_nick_match: @delegate_object[:block_name_nick_match],
                    id: fcb.id,
                    menu_format: @delegate_object[:menu_ux_row_format],
                    prompt: @delegate_object[:prompt_ux_enter_a_value],
                    table_center: @delegate_object[:table_center]
                  ) do |oname, color|
                    apply_block_type_color_option(oname, color)
                  end

                  results[fcb.id] = result if result.failure?
                  blocks << fcb unless result.failure?
                end
              else
                # prepare block for menu, may fail and call HashDelegator.error_handler
                result = fcb.for_menu!(
                  block_calls_scan: @delegate_object[:block_calls_scan],
                  block_name_match: @delegate_object[:block_name_match],
                  block_name_nick_match: @delegate_object[:block_name_nick_match],
                  id: fcb.id,
                  menu_format: @delegate_object[:menu_ux_row_format],
                  prompt: @delegate_object[:prompt_ux_enter_a_value],
                  table_center: @delegate_object[:table_center]
                ) do |oname, color|
                  # decorate the displayed line
                  apply_block_type_color_option(oname, color)
                end
                results[fcb.id] = result if result.failure?
                blocks << fcb unless result.failure?
              end
            rescue StandardError
              # ww $@, $!
              HashDelegator.error_handler('blocks_from_nested_files',
                                          { abort: true })
            end
          else
            expand_references!(fcb, link_state)
            blocks << fcb unless result.failure?
          end
        when :filter # types accepted
          %i[blocks line]
        when :line
          unless @delegate_object[:no_chrome]
            # expand references only if block is recognized (not a comment)
            create_and_add_chrome_blocks(
              blocks, fcb, id: "#{source_id}¤BlkFrmNstFls:#{count}®line", init_ids: init_ids
            ) do
              # expand references only if block is recognized (not a comment)
              expand_references!(fcb, link_state)
            end
          end
        end
      end
      OpenStruct.new(blocks: blocks, results: results)
    rescue StandardError
      # ww $@, $!
      HashDelegator.error_handler('blocks_from_nested_files')
    end

    def build_menu_options(exit_option, display_mode_option,
                           menu_entries, display_format)
      [exit_option,
       display_mode_option,
       *menu_entries.map(&display_format)].compact
    end

    def build_replacement_dictionary(
      commands, link_state,
      initial_code_required: false,
      occurrence_expressions: nil
    )
      evaluate_shell_expressions(
        (link_state&.inherited_lines_block || ''),
        commands,
        initial_code_required: initial_code_required,
        occurrence_expressions: occurrence_expressions
      )
    end

    def calc_logged_stdout_filename(block_name:)
      return unless @delegate_object[:saved_stdout_folder]

      @delegate_object[:logged_stdout_filename] =
        SavedAsset.new(
          blockname: block_name,
          filename: @delegate_object[:filename],
          prefix: @delegate_object[:logged_stdout_filename_prefix],
          time: Time.now.utc,
          exts: '.out.txt',
          saved_asset_format:
            shell_escape_asset_format(
              code_lines: @dml_link_state.inherited_lines,
              shell: ShellType::BASH
            )
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

    def chrome_block_criteria
      [
        { center: :table_center,         format: :menu_note_format,
          match: :menu_table_rows_match, type: BlockType::TEXT },
        { case_conversion: :upcase,      center: :heading1_center,
          collapse: :heading1_collapse,  collapsible: :heading1_collapsible,
          color: :menu_heading1_color,   format: :menu_heading1_format,      level: 1,
          match: :heading1_match,        type: BlockType::HEADING,           wrap: true },
        { center: :heading2_center,
          collapse: :heading2_collapse,  collapsible: :heading2_collapsible,
          color: :menu_heading2_color,   format: :menu_heading2_format,      level: 2,
          match: :heading2_match,        type: BlockType::HEADING,           wrap: true },
        { case_conversion: :downcase,    center: :heading3_center,
          collapse: :heading3_collapse,  collapsible: :heading3_collapsible,
          color: :menu_heading3_color,   format: :menu_heading3_format,      level: 3,
          match: :heading3_match,        type: BlockType::HEADING,           wrap: true },
        { center: :divider4_center,
          collapse: :divider4_collapse, collapsible: :divider4_collapsible,
          color: :menu_divider_color,    format: :menu_divider_format, level: 4,
          match: :divider_match,         type: BlockType::DIVIDER                       },
        { color: :menu_note_color,       format: :menu_note_format,
          match: :menu_note_match,       type: BlockType::TEXT,              wrap: true },
        { color: :menu_task_color,       format: :menu_task_format,
          match: :menu_task_match,       type: BlockType::TEXT,              wrap: true }
      ]
    end

    def code_from_automatic_ux_blocks(
      all_blocks,
      mdoc
    )
      unless @ux_most_recent_filename != @delegate_object[:filename]
        return
      end

      blocks = select_automatic_ux_blocks(
        all_blocks.reject(&:is_split_rest?)
      )
      return if blocks.empty?

      @ux_most_recent_filename = @delegate_object[:filename]

      (blocks.each.with_object([]) do |block, merged_options|
        command_result_w_e_t_nl = code_from_ux_block_to_set_environment_variables(
          block,
          mdoc,
          force: @delegate_object[:ux_auto_load_force_default],
          only_default: true
        )
        if command_result_w_e_t_nl.failure?
          merged_options
        else
          merged_options.push(command_result_w_e_t_nl.stdout)
        end
      end).to_a
    end

    # parse YAML body defining the UX for a single variable
    # set ENV value for the variable and return code lines for the same
    def code_from_ux_block_to_set_environment_variables(
      selected, mdoc, inherited_code: nil, force: true, only_default: false
    )
      exit_prompt = @delegate_object[:prompt_filespec_back]

      required = mdoc.collect_recursively_required_code(
        anyname: selected.pub_name,
        label_format_above: @delegate_object[:shell_code_label_format_above],
        label_format_below: @delegate_object[:shell_code_label_format_below],
        block_source: block_source
      )

      # process each ux block in sequence, setting ENV and collecting lines
      required_lines = []
      required[:blocks].each do |block|
        next unless block.type == BlockType::UX

        case data = YAML.load(block.body.join("\n"))
        when Hash
          export = parse_yaml_of_ux_block(
            data,
            prompt: @delegate_object[:prompt_ux_enter_a_value],
            validate: '^(?<name>[^ ].*)$'
          )
          block.export = export
          block.export_act = FCB.act_source(export)
          block.export_init = FCB.init_source(export)

          # required are variable names that must be set before the UX block is executed.
          # if any precondition is not set, the sequence is aborted.
          required_variables = []
          export.required&.each do |precondition|
            required_variables.push "[[ -z $#{precondition} ]] && exit #{EXIT_STATUS_REQUIRED_EMPTY}"
          end

          eval_code = join_array_of_arrays(
            inherited_code, # inherited code
            required_lines, # current block requirements
            required_variables, # test conditions
            required[:code] # current block code
          )
          if only_default
            command_result_w_e_t_nl =
              ux_block_export_automatic(eval_code, export)
            # do not display warnings on initializing call
            return command_result_w_e_t_nl if command_result_w_e_t_nl.failure?

          else
            command_result_w_e_t_nl =
              ux_block_export_activated(eval_code, export, exit_prompt)
            if command_result_w_e_t_nl.failure?
              warn command_result_w_e_t_nl.warning if command_result_w_e_t_nl.warning&.present?
              return command_result_w_e_t_nl
            end
          end
          return command_result_w_e_t_nl if command_result_w_e_t_nl.failure?

          required_lines.concat(command_result_w_e_t_nl.new_lines)
          if SelectResponse.continue?(command_result_w_e_t_nl.stdout)
            if command_result_w_e_t_nl.transformable
              command_result_w_e_t_nl.stdout = transform_export_value(
                command_result_w_e_t_nl.stdout, export
              )
            end

            if command_result_w_e_t_nl.exportable
              ENV[export.name] = command_result_w_e_t_nl.stdout.to_s
              required_lines.push code_line_safe_assign(export.name, command_result_w_e_t_nl.stdout,
                                                        force: force)
            end
          end
        else
          raise "Invalid data type: #{data.inspect}"
        end
      end

      CommandResult.new(stdout: required_lines)
    end

    # sets ENV
    def code_from_vars_block_to_set_environment_variables(selected)
      code_lines = []
      case data = YAML.load(selected.body.join("\n"))
      when Hash
        data.each do |key, value|
          ENV[key] = value.to_s
          code_lines.push "#{key}=#{Shellwords.escape(value)}"

          next unless @delegate_object[:menu_vars_set_format].present?

          formatted_string = format(@delegate_object[:menu_vars_set_format],
                                    { key: key, value: value })
          print string_send_color(formatted_string, :menu_vars_set_color)
        end
      end
      code_lines
    end

    def code_line_safe_assign(name, value, force:)
      if force
        "#{name}=#{Shellwords.escape(value)}"
      else
        "[[ -z $#{name} ]] && #{name}=#{Shellwords.escape(value)}"
      end
    end

    def collect_line_decor_patterns(delegate_object)
      extract_patterns = lambda do |key|
        return [] unless delegate_object[key].present?

        HashDelegator.safeval(delegate_object[key]).map do |pc|
          {
            color_method: pc[:color_method].to_sym,
            pattern: Regexp.new(pc[:pattern])
          }
        end
      end

      %i[line_decor_pre line_decor_main line_decor_post].flat_map do |key|
        extract_patterns.call(key)
      end
    end

    def command_execute(
      command,
      erls:,
      shell:, args: []
    )
      @run_state.files = StreamsOut.new
      @run_state.options = @delegate_object
      @run_state.started_at = Time.now.utc

      if @delegate_object[:execute_in_own_window] &&
         @delegate_object[:execute_command_format].present? &&
         @run_state.saved_filespec.present?

        @run_state.in_own_window = true
        command_execute_in_own_window(
          args: args,
          erls: erls,
          script: @delegate_object[:execute_command_format]
        )

      else
        @run_state.in_own_window = false
        command_execute_in_process(
          args: args, command: command,
          erls: erls,
          filename: @delegate_object[:filename],
          shell: shell
        )
      end

      @run_state.completed_at = Time.now.utc
    rescue Errno::ENOENT
      report_error($ERROR_INFO)
    rescue SignalException => err
      # Handle SignalException
      @run_state.aborted_at = Time.now.utc
      @run_state.error_message = 'SIGTERM'
      @run_state.error = err
      @run_state.files.append_stream_line(ExecutionStreams::STD_ERR,
                                          @run_state.error_message)
      @fout.fout "Error ENOENT: #{err.inspect}"
    end

    def command_execute_in_own_window(
      args:,
      erls:,
      script:
    )
      system(
        format(
          script,
          command_execute_in_own_window_format_arguments(
            erls: erls,
            rest: args ? args.join(' ') : ''
          )
        )
      )
    end

    def command_execute_in_own_window_format_arguments(
      erls:, home: Dir.pwd, rest: ''
    )
      {
        batch_index: @run_state.batch_index,
        batch_random: @run_state.batch_random,
        block_name: @delegate_object[:block_name],
        document_filename: File.basename(@delegate_object[:filename]),
        document_filespec: @delegate_object[:filename],
        home: home,
        output_filename: File.basename(
          @delegate_object[:logged_stdout_filespec]
        ),
        output_filespec: @delegate_object[:logged_stdout_filespec],
        play_command: erls[:play_bin],
        rest: rest,
        script_filename: @run_state.saved_filespec,
        script_filespec: File.join(home, @run_state.saved_filespec),
        started_at: @run_state.started_at.strftime(
          @delegate_object[:execute_command_title_time_format]
        )
      }
    end

    def command_execute_in_process(
      args:, command:,
      erls:,
      filename:, shell:
    )
      execute_command_with_streams(
        [shell, '-c', command,
         @delegate_object[:filename],
         *args]
      )
    end

    # This method is responsible for handling the execution of
    #  generic blocks in a markdown document.
    # It collects the required code lines from the document and,
    #  depending on the configuration, may display the code for
    #  user approval before execution. It then executes the approved block.
    #
    # @param mdoc [Object] The markdown document object
    #  containing code blocks.
    # @param selected [Hash] The selected item from the menu
    #  to be executed.
    # @return [LoadFileLinkState] An object indicating whether to load
    #  the next block or reuse the current one.
    def compile_execute_and_trigger_reuse(
      mdoc:, selected:, block_source:, link_state:
    )
      # play_bin matches the name in mde.applescript, called by .mde.macos.yml
      bim = @delegate_object[:block_interactive_match]
      play_bin = if bim.present? && selected.start_line =~ Regexp.new(bim)
                   @delegate_object[:play_bin_interactive]
                 else
                   bbm = @delegate_object[:block_batch_match]
                   if bbm.present? && selected.start_line =~ Regexp.new(bbm)
                     @delegate_object[:play_bin_batch]
                   else
                     @delegate_object[:document_play_bin]
                   end
                 end

      required_lines = execute_block_type_port_code_lines(
        mdoc: mdoc, selected: selected,
        link_state: link_state, block_source: block_source
      )
      output_or_approval = @delegate_object[:output_script] ||
                           @delegate_object[:user_must_approve]
      if output_or_approval
        display_required_code(required_lines: required_lines)
      end
      allow_execution = if @delegate_object[:user_must_approve]
                          prompt_for_user_approval(
                            required_lines: required_lines,
                            selected: selected
                          )
                        else
                          true
                        end

      if allow_execution
        execute_required_lines(blockname: selected.pub_name,
                               erls: { play_bin: play_bin,
                                       shell: selected.shell },
                               required_lines: required_lines,
                               shell: selected.shell)
      end

      link_state.block_name = nil
    end

    # Check if the expression contains wildcard characters
    def contains_glob?(str)
      return false if str.nil?

      str.match?(/[\*\?\[\{\}]/)
    end

    def copy_to_clipboard(required_lines)
      text = required_lines.flatten.join($INPUT_RECORD_SEPARATOR)
      Clipboard.copy(text)
      @fout.fout "Clipboard updated: #{required_lines.count} blocks," \
                 " #{required_lines.flatten.count} lines," \
                 " #{text.length} characters"
    end

    # Counts the number of fenced code blocks in a file.
    # It reads lines from a file and counts occurrences of lines
    #  matching the fenced block regex.
    # Assumes that every fenced block starts and ends with a
    #  distinct line (hence divided by 2).
    #
    # @return [Integer] The count of fenced code blocks in the file.
    def count_blocks_in_filename
      regex = Regexp.new(@delegate_object[:fenced_start_and_end_regex])
      lines = cfile.readlines(
        @delegate_object[:filename],
        import_paths: @delegate_object[:import_paths]&.split(':')
      )
      HashDelegator.count_matches_in_lines(lines, regex) / 2
    end

    def count_named_group_occurrences(
      blocks, pattern, exclude_types: [BlockType::SHELL],
      group_name:
    )
      # Initialize a counter for named group occurrences
      occurrence_count = Hash.new(0)
      occurrence_expressions = {}
      return [occurrence_count,
              occurrence_expressions] if pattern.nil? || pattern == //

      blocks.each do |block|
        # Skip processing for shell-type blocks
        next if exclude_types.include?(block.type)

        # Scan each block name for matches of the pattern
        count_named_group_occurrences_block_body_fix_indent(block).scan(pattern) do |(_, _variable_name)|
          pattern.match($LAST_MATCH_INFO.to_s) # Reapply match for named groups
          id = $LAST_MATCH_INFO[group_name]
          occurrence_count[id] += 1
          occurrence_expressions[id] = $LAST_MATCH_INFO['expression']
        end
      end

      [occurrence_count, occurrence_expressions]
    end

    def count_named_group_occurrences_block_body_fix_indent(block)
      ### actually double the entries, but not a problem since it's used as a boolean
      ([block.oname || ''] + (block.body || [''])).join("\n")
    end

    ##
    # Creates and adds a formatted block to the blocks array
    #  based on the provided match and format options.
    # @param blocks [Array] The array of blocks to add the new block to.
    # @param match_data [MatchData] The match data containing named captures
    #  for formatting.
    # @param format_option [String] The format string to be used
    #  for the new block.
    # @param color_method [Symbol] The color method to apply
    #  to the block's display name.
    # return number of lines added
    def create_and_add_chrome_block(
      blocks:,
      case_conversion: nil,
      center: nil,
      collapse: nil,
      color_method:,
      decor_patterns: [],
      disabled: true,
      fcb: nil,
      format_option:,
      id: '',
      level: 0,
      match_data:,
      type: '',
      wrap: nil
    )
      line_cap = NamedCaptureExtractor.extract_named_group_match_data(match_data)
      # replace tabs in indent
      line_cap[:indent] ||= ''
      line_cap[:indent] = line_cap[:indent].dup if line_cap[:indent].frozen?
      line_cap[:indent].gsub!("\t", '    ') # TAB_SIZE = 4
      # replace tabs in text
      line_cap[:text] ||= ''
      line_cap[:text] = line_cap[:text].dup if line_cap[:text].frozen?
      line_cap[:text].gsub!("\t", '    ')
      # missing capture
      line_cap[:collapse] ||= ''
      line_cap[:line] ||= ''

      line_caps = [line_cap]

      # split text with newlines, from variable expansion
      if line_cap[:text].include?("\n")
        lines = line_cap[:text].split("\n")
        line_caps = lines.map do |line|
          line_cap.dup.merge(text: line)
        end.to_a
      end

      # wrap text on multiple lines to screen width, replacing line_caps
      if wrap
        line_caps = line_caps.flat_map do |line_cap|
          text = line_cap[:text]
          wrapper = StringWrapper.new(width: screen_width_for_wrapping - line_cap[:indent].length)

          if text.length > screen_width_for_wrapping
            # Wrap this text and create line_cap objects for each part
            wrapper.wrap(text).map do |wrapped_text|
              line_cap.dup.merge(text: wrapped_text)
            end
          else
            # No change needed for this line
            line_cap
          end
        end
      end

      if center
        line_caps.each do |line_obj|
          line_obj[:indent] =
            if line_obj[:text].length < screen_width_for_wrapping
              ' ' * ((screen_width_for_wrapping - line_obj[:text].length) / 2)
            else
              ''
            end
        end
      end

      use_fcb = !fcb.nil? # fcb only for the first record if any
      line_caps.each_with_index do |line_obj, index|
        next if line_obj[:text].nil?

        case case_conversion
        when :upcase
          line_obj[:text].upcase!
        when :downcase
          line_obj[:text].downcase!
        end

        # format expects :line to be text only
        line_obj[:line] = line_obj[:text]
        oname = if format_option
                  format(format_option, line_obj)
                else
                  line_obj[:line]
                end
        decorated = apply_tree_decorations(
          oname, color_method, decor_patterns
        )

        line_obj[:line] = line_obj[:indent] + line_obj[:text]

        if use_fcb
          fcb.center = center
          fcb.chrome = true
          fcb.collapse = collapse.nil? ? (line_obj[:collapse] == COLLAPSIBLE_TOKEN_COLLAPSE) : collapse
          fcb.disabled = disabled ? TtyMenu::DISABLE : nil
          fcb.dname = line_obj[:indent] + decorated
          fcb.id = "#{id}.#{index}"
          fcb.indent = line_obj[:indent]
          fcb.level = level
          fcb.oname = line_obj[:text]
          fcb.s0indent = indent
          fcb.s0printable = line_obj[:text]
          fcb.s1decorated = decorated
          fcb.text = line_obj[:text]
          fcb.token = line_obj[:collapse]
          fcb.type = type
          use_fcb = false # next line is new record
        else
          fcb = persist_fcb(
            center: center,
            chrome: true,
            collapse: collapse.nil? ? (line_obj[:collapse] == COLLAPSIBLE_TOKEN_COLLAPSE) : collapse,
            disabled: disabled ? TtyMenu::DISABLE : nil,
            dname: line_obj[:indent] + decorated,
            id: "#{id}.#{index}",
            indent: line_obj[:indent],
            level: level,
            oname: line_obj[:text],
            s0indent: indent,
            s0printable: line_obj[:text],
            s1decorated: decorated,
            text: line_obj[:text],
            token: line_obj[:collapse],
            type: type
          )
        end

        blocks.push fcb
      end
      line_caps.count
    end

    ##
    # Processes lines within the file and converts them into
    #  blocks if they match certain criteria.
    # @param blocks [Array] The array to append new blocks to.
    # @param fcb [FCB] The file control block being processed.
    # @param opts [Hash] Options containing configuration for line processing.
    # @param use_chrome [Boolean] Indicates if the chrome styling should
    #  be applied.
    def create_and_add_chrome_blocks(blocks, fcb, id: '', init_ids: false)
      chrome_block_criteria.each_with_index do |criteria, index|
        unless @delegate_object[criteria[:match]].present? &&
               (mbody = fcb.body[0].match @delegate_object[criteria[:match]])
          next
        end

        if block_given?
          # expand references only if block is recognized (not a comment)
          yield if block_given?

          # parse multiline to capture output of variable expansion
          mbody = fcb.body[0].match Regexp.new(
            @delegate_object[criteria[:match]], Regexp::MULTILINE
          )
        end

        create_and_add_chrome_block(
          blocks: blocks,
          case_conversion: criteria[:case_conversion],
          center: criteria[:center] &&
                  @delegate_object[criteria[:center]],

          collapse: case fcb.collapse_token
                    when COLLAPSIBLE_TOKEN_COLLAPSE
                      true
                    when COLLAPSIBLE_TOKEN_EXPAND
                      false
                    else
                      false
                    end,

          color_method: criteria[:color] &&
                        @delegate_object[criteria[:color]].to_sym,
          decor_patterns:
            @decor_patterns_from_delegate_object_for_block_create,
          disabled: !(criteria[:collapsible] && @delegate_object[criteria[:collapsible]]),
          fcb: fcb,
          id: "#{id}.#{index}",
          format_option: criteria[:format] &&
                         @delegate_object[criteria[:format]],
          level: criteria[:level],
          match_data: mbody,
          type: criteria[:type],
          wrap: criteria[:wrap]
        )
        break
      end
    end

    def create_divider(position, source_id: '')
      divider_key = if position == :initial
                      :menu_initial_divider
                    else
                      :menu_final_divider
                    end
      oname = format(@delegate_object[:menu_divider_format],
                     HashDelegator.safeval(@delegate_object[divider_key]))

      persist_fcb(
        chrome: true,
        disabled: TtyMenu::DISABLE,
        dname: string_send_color(oname, :menu_divider_color),
        id: source_id,
        oname: oname
      )
    end

    # Prompts user if named block is the same as the prior execution.
    #
    # @return [Boolean] Execute the named block.
    def debounce_allows
      return true unless @delegate_object[:debounce_execution]

      # filter block if selected in menu
      return true if @run_state.source.block_name_from_cli

      # return false if @prior_execution_block == @delegate_object[:block_name]
      if @prior_execution_block == @delegate_object[:block_name]
        return @allowed_execution_block == @prior_execution_block ||
               prompt_approve_repeat
      end

      @prior_execution_block = @delegate_object[:block_name]
      @allowed_execution_block = nil
      true
    end

    def debounce_reset
      @prior_execution_block = nil
    end

    # Determines the state of a selected block in the menu based
    #  on the selected option.
    # It categorizes the selected option into either EXIT, BACK,
    #  or CONTINUE state.
    #
    # @param selected_option [Hash] The selected menu option.
    # @return [SelectedBlockMenuState] An object representing
    #  the state of the selected block.
    def determine_block_state(selected_option)
      return if selected_option.nil?

      option_name = selected_option[:oname]
      if option_name == menu_chrome_formatted_option(:menu_option_exit_name)
        return SelectedBlockMenuState.new(nil,
                                          OpenStruct.new,
                                          MenuState::EXIT)
      end
      if option_name == menu_chrome_formatted_option(:menu_option_back_name)
        return SelectedBlockMenuState.new(selected_option,
                                          OpenStruct.new,
                                          MenuState::BACK)
      end

      SelectedBlockMenuState.new(selected_option,
                                 OpenStruct.new,
                                 MenuState::CONTINUE)
    end

    # Displays the required lines of code with color formatting
    #  for the preview section.
    # It wraps the code lines between a formatted header and
    #  tail.
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
      divider_key = if position == :initial
                      :menu_initial_divider
                    else
                      :menu_final_divider
                    end
      @delegate_object[:menu_divider_format].present? &&
        @delegate_object[divider_key].present?
    end

    def dml_menu_append_chrome_item(
      name, count, type,
      always_create: true,
      always_enable: true,
      menu_state: MenuState::LOAD,
      source_id: ''
    )
      raise unless name.present?
      raise if @dml_menu_blocks.nil?

      item = @dml_menu_blocks.find { |block| block.oname == name }

      # create menu item when it is needed (count > 0)
      #
      if item.nil? && (always_create || count.positive?)
        item = append_chrome_block(source_id: source_id,
                                   menu_blocks: @dml_menu_blocks,
                                   menu_state: menu_state)
      end

      # update item if it exists
      #
      return unless item

      item.dname = type.present? ? "#{name} (#{count} #{type})" : name
      if always_enable || count.positive?
        item.delete(:disabled)
      else
        item[:disabled] = TtyMenu::DISABLE
      end
    end

    def do_save_execution_output
      return unless @delegate_object[:save_execution_output]
      return if @run_state.in_own_window

      @run_state.files.write_execution_output_to_file(
        @delegate_object[:logged_stdout_filespec]
      )
    end

    # remove leading "./"
    # replace characters: / : . * (space) with: (underscore)
    def document_name_in_glob_as_file_name(
      document_filename: @dml_link_state.document_filename,
      format_glob: @delegate_object[:document_saved_lines_glob],
      remove_regexp: %r{^\./},
      subst_regexp: /[\/:\.\* ]/,
      subst_string: '_'
    )
      if document_filename.nil? || document_filename.empty?
        return document_filename
      end

      format(
        format_glob,
        { document_filename:
           document_filename.gsub(remove_regexp, '')
                            .gsub(subst_regexp, subst_string) }
      )
    end

    def dump_and_warn_block_state(name:, selected:)
      if selected.nil?
        Exceptions.warn_format("Block not found -- name: #{name}",
                               { abort: true })
      end

      return unless @delegate_object[:dump_selected_block]

      warn selected.to_yaml.sub(/^(?:---\n)?/, "Block:\n")
    end

    # Outputs warnings based on the delegate object's configuration
    #
    # @param delegate_object [Hash] The delegate object containing
    #  configuration flags.
    # @param blocks_in_file [Hash] Hash of blocks present in
    #  the file.
    # @param menu_blocks [Hash] Hash of menu blocks.
    # @param link_state [LinkState] Current state of the link.
    def dump_delobj(blocks_in_file, menu_blocks, link_state)
      if @delegate_object[:dump_delegate_object]
        warn format_and_highlight_hash(@delegate_object,
                                       label: '@delegate_object')
      end

      if @delegate_object[:dump_blocks_in_file]
        warn format_and_highlight_dependencies(
          compact_and_index_hash(blocks_in_file),
          label: 'blocks_in_file'
        )
      end

      if @delegate_object[:dump_menu_blocks]
        warn format_and_highlight_dependencies(
          compact_and_index_hash(menu_blocks),
          label: 'menu_blocks'
        )
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

    # Opens text in an editor for user modification and
    #  returns the modified text.
    #
    # This method reads the provided text, opens it in the default editor,
    # and allows the user to modify it. If the user makes changes, the
    # modified text is returned. If the user exits the editor without
    # making changes or the editor is closed abruptly, appropriate messages
    # are displayed.
    #
    # @param [String] initial_text The initial text to be edited.
    # @param [String] temp_name The base name for the temporary file
    #  (default: 'edit_text').
    # @return [String, nil] The modified text, or nil if no changes
    #  were made or the editor was closed abruptly.
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

    # Execute a code block after approval and provide user interaction options.
    #
    # This method displays required code blocks, asks for user approval, and
    # executes the code block if approved. It also allows users to copy the
    # code to the clipboard or save it to a file.
    #
    # @param opts [Hash] Options hash containing configuration settings.
    # @param mdoc [YourMDocClass] An instance of the MDoc class.
    #
    def execute_block_by_type_for_lfls(
      selected:, mdoc:, block_source:, link_state: LinkState.new
    )
      # order should not be important other than else clause
      if selected.type == BlockType::TEXT && !selected.truncated_table_cell.nil?
        debounce_reset
        $table_cell_truncate = !$table_cell_truncate

        LoadFileLinkState.new(LoadFile::REUSE, link_state)

      elsif selected.type == BlockType::EDIT
        debounce_reset
        vux_edit_inherited
        return :break if pause_user_exit

        next_state_append_code(selected, link_state, [])

      elsif selected.type == BlockType::HISTORY
        debounce_reset
        return :break if execute_block_type_history_ux(
          selected: selected,
          link_state: link_state
        ) == :no_history

        LoadFileLinkState.new(LoadFile::REUSE, link_state)

      elsif selected.type == BlockType::LINK
        debounce_reset
        execute_block_type_link_with_state(link_block_body: selected.body,
                                           mdoc: mdoc,
                                           selected: selected,
                                           link_state: link_state,
                                           block_source: block_source)

      elsif selected.type == BlockType::LOAD
        debounce_reset
        code_lines = execute_block_type_load_code_lines(selected)
        next_state_append_code(selected, link_state, code_lines)

      elsif selected.type == BlockType::SAVE
        debounce_reset

        execute_block_type_save(
          code_lines: link_state&.inherited_lines,
          selected: selected
        )

        LoadFileLinkState.new(LoadFile::REUSE, link_state)

      elsif selected.type == BlockType::VIEW
        debounce_reset
        vux_view_inherited(stream: $stderr)
        return :break if pause_user_exit

        LoadFileLinkState.new(LoadFile::REUSE, link_state)

      # from CLI
      elsif selected.nickname == @delegate_object[:menu_option_exit_name][:line]
        debounce_reset
        LoadFileLinkState.new(LoadFile::EXIT, link_state)

      elsif @menu_user_clicked_back_link
        debounce_reset
        LoadFileLinkState.new(
          LoadFile::LOAD,
          pop_link_history_new_state
        )

      elsif selected.type == BlockType::OPTS
        debounce_reset
        code_lines = []
        options_state = read_show_options_and_trigger_reuse(
          link_state: link_state,
          mdoc: @dml_mdoc,
          selected: selected
        )
        update_menu_base(options_state.options)

        link_state = LinkState.new
        next_state_append_code(selected, link_state, code_lines)

      elsif selected.type == BlockType::PORT
        debounce_reset
        required_lines = execute_block_type_port_code_lines(
          mdoc: @dml_mdoc,
          selected: selected,
          link_state: link_state,
          block_source: block_source
        )
        next_state_set_code(selected, link_state, required_lines)

      elsif selected.type == BlockType::UX
        debounce_reset
        command_result_w_e_t_nl = code_from_ux_block_to_set_environment_variables(
          selected,
          @dml_mdoc,
          inherited_code: @dml_link_state.inherited_lines
        )
        ### TBD if command_result_w_e_t_nl.failure?
        next_state_append_code(
          selected,
          link_state,
          command_result_w_e_t_nl.failure? ? [] : command_result_w_e_t_nl.stdout
        )

      elsif selected.type == BlockType::VARS
        debounce_reset
        next_state_append_code(selected, link_state,
                               code_from_vars_block_to_set_environment_variables(selected))

      elsif COLLAPSIBLE_TYPES.include?(selected.type)
        debounce_reset
        menu_toggle_collapsible_block(selected)
        LoadFileLinkState.new(LoadFile::REUSE, link_state)

      elsif debounce_allows
        compile_execute_and_trigger_reuse(mdoc: mdoc,
                                          selected: selected,
                                          link_state: link_state,
                                          block_source: block_source)
        LoadFileLinkState.new(LoadFile::REUSE, link_state)

      else
        LoadFileLinkState.new(LoadFile::REUSE, link_state)
      end
    end

    def execute_block_for_state_and_name(
      selected:, mdoc:, link_state:, block_source: {}
    )
      lfls = execute_block_by_type_for_lfls(
        selected: selected,
        mdoc: mdoc,
        link_state: link_state,
        block_source: block_source
      )

      # dname is not fixed for some block types, use block id
      if lfls.load_file != LoadFile::LOAD
        block_selection = BlockSelection.new(selected.id)
      end

      { link_state: lfls.link_state,
        block_selection: block_selection,
        quit: lfls.load_file == LoadFile::EXIT }
    end

    def execute_block_in_state(block_name)
      @dml_block_state = find_block_state_by_name(block_name)
      dump_and_warn_block_state(name: block_name,
                                selected: @dml_block_state.block)
      if @dml_block_state.block.fetch(:is_enabled_but_inactive, false)
        @dml_block_selection = BlockSelection.new(@dml_block_state.block.id)
        return # do nothing
      end

      next_block_state =
        execute_block_for_state_and_name(
          selected: @dml_block_state.block,
          mdoc: @dml_mdoc,
          link_state: @dml_link_state,
          block_source: {
            document_filename: @delegate_object[:filename],
            time_now_date: Time.now.utc.strftime(
              @delegate_object[:shell_code_label_time_format]
            )
          }
        )

      @dml_link_state = next_block_state[:link_state]
      @dml_block_selection = next_block_state[:block_selection]
      :break if next_block_state[:quit]
    end

    def execute_block_type_history_ux(
      directory: @delegate_object[:document_configurations_directory],
      filename: '*',
      form: '%{line}',
      link_state:,
      regexp: '^(?<line>.*)$',
      selected:
    )
      block_data = HashDelegator.parse_yaml_data_from_body(selected.body)
      files_table_rows = read_saved_assets_for_history_table(
        filename: filename,
        form: form,
        path: block_data['directory'] || directory,
        regexp: regexp
      )
      return :no_history unless files_table_rows

      execute_history_select(files_table_rows, stream: $stderr)
    end

    # Handles the processing of a link block in Markdown Execution.
    # It loads YAML data from the link_block_body content,
    #  pushes the state to history, sets environment variables,
    #  and decides on the next block to load.
    #
    # @param link_block_body [Array<String>]
    #  The body content as an array of strings.
    # @param mdoc [Object] Markdown document object.
    # @param selected [FCB] Selected code block.
    # @return [LoadFileLinkState] Object indicating the next
    #  action for file loading.
    def execute_block_type_link_with_state(
      link_block_body: [], mdoc: nil, selected: FCB.new,
      link_state: LinkState.new, block_source: {}
    )
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
          begin
            code_lines += File.readlines(load_filespec,
                                         chomp: true)
          rescue Errno::ENOENT
            report_error($ERROR_INFO)
          end
        end
      end

      # if an eval link block, evaluate code_lines and return its standard output
      #
      if link_block_data.fetch(LinkKeys::EVAL,
                               false) || link_block_data.fetch(LinkKeys::EXEC,
                                                               false)
        code_lines = link_block_data_eval(
          link_state, code_lines, selected, link_block_data,
          block_source: block_source,
          shell: @delegate_object[:block_type_default]
        )
      end

      # config next state
      #
      next_document_filename = write_inherited_lines_to_file(link_state,
                                                             link_block_data)
      next_block_name = link_block_data.fetch(
        LinkKeys::NEXT_BLOCK,
        nil
      ) || link_block_data.fetch(LinkKeys::BLOCK, nil) || ''

      if link_block_data[LinkKeys::RETURN]
        pop_add_current_code_to_head_and_trigger_load(
          link_state, block_names, code_lines,
          dependencies, selected, next_block_name: next_block_name
        )

      else
        next_keep_code = link_state&.keep_code || link_block_data.fetch('keep', false) #/*LinkKeys::KEEP*/
        link_history_push_and_next(
          curr_block_name: selected.pub_name,
          curr_document_filename: @delegate_object[:filename],
          inherited_block_names:
           ((link_state&.inherited_block_names || []) + block_names).sort.uniq,
          inherited_dependencies:
           (link_state&.inherited_dependencies || {}).merge(dependencies || {}), ### merge, not replace, key data
          inherited_lines: HashDelegator.code_merge(
            link_state&.inherited_lines, code_lines
          ),
          keep_code: link_state&.keep_code,
          next_block_name: next_block_name,
          next_document_filename: next_document_filename,
          next_keep_code: next_keep_code,
          next_load_file: next_document_filename == @delegate_object[:filename] ? LoadFile::REUSE : LoadFile::LOAD
        )
      end
    end

    def execute_block_type_load_code_lines(
      selected,
      directory: @delegate_object[:document_configurations_directory],
      exit_prompt: @delegate_object[:prompt_filespec_back],
      filename_pattern: @delegate_object[:vars_block_filename_pattern],
      glob: @delegate_object[:document_configurations_glob],
      menu_options: HashDelegator.options_for_tty_menu(@delegate_object),
      view: @delegate_object[:vars_block_filename_view]
    )
      block_data = HashDelegator.parse_yaml_data_from_body(selected.body)

      dirs = Dir.glob(
        File.join(
          Dir.pwd,
          block_data['directory'] || directory,
          block_data['glob'] || glob
        )
      )
      dirs.sort_by! { |f| File.mtime(f) }.reverse!

      if !contains_glob?(block_data['directory']) &&
         !contains_glob?(block_data['glob'])
        if dirs[0]
          File.readlines(dirs[0], chomp: true)
        else
          warn 'No matching file found.'
        end
      elsif (selected_option = select_option_with_metadata(
        prompt_title,
        [exit_prompt] + dirs.map do |file| # tty_menu_items
          { name:
              format(
                block_data['view'] || view,
                NamedCaptureExtractor.extract_named_group_match_data(
                  file.match(
                    Regexp.new(block_data['filename_pattern'] || filename_pattern)
                  )
                )
              ),
            oname: file }
        end,
        menu_options.merge(
          cycle: true,
          match_dml: false
        )
      ))
        if selected_option.dname != exit_prompt
          File.readlines(selected_option.oname, chomp: true)
        end
      else
        warn 'No matching files found.'
      end
    end

    # Collects required code lines based on the selected block and
    #  the delegate object's configuration.
    # If the block type is VARS, it also sets environment variables
    #  based on the block's content.
    #
    # @param mdoc [YourMDocClass] An instance of the MDoc class.
    # @param selected [Hash] The selected block.
    # @return [Array<String>] Required code blocks as an array of lines.
    def execute_block_type_port_code_lines(mdoc:, selected:, block_source:,
                                           link_state: LinkState.new)
      required = mdoc.collect_recursively_required_code(
        anyname: selected.pub_name,
        label_format_above: @delegate_object[:shell_code_label_format_above],
        label_format_below: @delegate_object[:shell_code_label_format_below],
        block_source: block_source
      ) # !!t 'required'
      dependencies = (
        link_state&.inherited_dependencies || {}
      ).merge(required[:dependencies] || {})
      required[:unmet_dependencies] = (
        required[:unmet_dependencies] || []
      ) - (link_state&.inherited_block_names || [])
      if required[:unmet_dependencies].present?
        ### filter against link_state.inherited_block_names

        warn format_and_highlight_dependencies(
          dependencies, highlight: required[:unmet_dependencies]
        )
        runtime_exception(
          :runtime_exception_error_level,
          'unmet_dependencies, flag: runtime_exception_error_level',
          required[:unmet_dependencies]
        )
      elsif @delegate_object[:dump_dependencies]
        warn format_and_highlight_dependencies(
          dependencies,
          highlight: [@delegate_object[:block_name]]
        )
      end

      if selected[:type] == BlockType::OPTS
        # body of blocks is returned as a list of lines to be read an YAML
        HashDelegator.code_merge(required[:blocks].map(&:body).flatten(1))
      else
        code_lines = if selected.type == BlockType::VARS
                       code_from_vars_block_to_set_environment_variables(selected)
                     else
                       []
                     end
        HashDelegator.code_merge(link_state&.inherited_lines,
                                 required[:code] + code_lines)
      end
    end

    def execute_block_type_save(code_lines:, selected:)
      block_data = HashDelegator.parse_yaml_data_from_body(selected.body)
      directory_glob = if block_data['directory']
                         File.join(
                           block_data['directory'],
                           block_data['glob'] ||
                            @delegate_object[:document_saved_lines_glob].split('/').last
                         )
                       else
                         @delegate_object[:document_saved_lines_glob]
                       end

      save_filespec_from_expression(directory_glob).tap do |save_filespec|
        if save_filespec && save_filespec != exit_prompt
          begin
            File.write(save_filespec,
                       HashDelegator.join_code_lines(code_lines))
          rescue Errno::ENOENT
            report_error($ERROR_INFO)
          end
        end
      end
    end

    # Executes a given command and processes its
    #  input, output, and error streams.
    #
    # @param [Array<String>] command the command to
    #  execute along with its arguments.
    # @yield [stdin, stdout, stderr, thread] if a block is provided, it
    #  yields input, output, error lines, and the execution thread.
    # @return [Integer] the exit status of the executed command (0 to 255).
    #
    # @example
    #   status = execute_command_with_streams(['ls', '-la']) \
    #    do |stdin, stdout, stderr, thread|
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

    def execute_history_select(
      files_table_rows,
      exit_prompt: @delegate_object[:prompt_filespec_back],
      pause_refresh: false,
      stream:
    )
      # repeat select+display until user exits

      interactive_menu_with_display_modes(
        files_table_rows,
        display_formats: %i[row file],
        display_mode_option: @delegate_object[:prompt_filespec_facet],
        exit_option: exit_prompt,
        menu_title: @delegate_object[:prompt_select_history_file],
        pause_after_selection: pause_refresh
      ) do |file|
        info = file_info(file.file)
        stream.puts "#{file.file} - #{info[:lines]} lines / " \
                    "#{info[:size]} bytes"
        stream.puts(
          File.readlines(file.file,
                         chomp: false).map.with_index do |line, ind|
            format(' %s.  %s',
                   AnsiString.new(format('% 4d', ind + 1)).send(:violet),
                   line)
          end
        )
      end
    end

    def execute_inherited_save(
      code_lines: @dml_link_state.inherited_lines
    )
      return unless (save_filespec = save_filespec_from_expression(
        document_name_in_glob_as_file_name
      ))

      unless write_file_with_directory_creation(
        content: HashDelegator.join_code_lines(code_lines),
        filespec: save_filespec
      )
        :break
      end
    end

    def execute_navigate_back
      @menu_user_clicked_back_link = true

      keep_code = @dml_link_state.keep_code
      inherited_lines = keep_code ? @dml_link_state.inherited_lines_block : nil

      @dml_link_state = pop_link_history_new_state

      {
        block_name: @dml_link_state.block_name,
        document_filename: @dml_link_state.document_filename,
        inherited_lines: inherited_lines,
        keep_code: keep_code
      }
    end

    # Executes a block of code that has been approved for execution.
    # It sets the script block name, writes command files if
    #  required,
    #  and handles the execution
    # including output formatting and summarization.
    #
    # @param required_lines [Array<String>] The lines of code to be executed.
    # @param selected [FCB] The selected functional code block object.
    def execute_required_lines(
      blockname: '',
      erls: {},
      required_lines: [],
      shell:
    )
      if @delegate_object[:save_executed_script]
        write_command_file(blockname: blockname,
                           required_lines: required_lines,
                           shell: shell)
      end
      if @dml_block_state
        calc_logged_stdout_filename(block_name: @dml_block_state.block.oname)
      end
      format_and_execute_command(
        code_lines: required_lines,
        erls: erls,
        shell: shell
      )
      post_execution_process
    end

    def expand_blocks_with_replacements(
      menu_blocks, replacements, exclude_types: [BlockType::SHELL]
    )
      # update blocks
      #
      Regexp.union(replacements.keys.map do |word|
                     # match multiline text from variable expansion
                     Regexp.new(Regexp.escape(word), Regexp::MULTILINE)
                   end).tap do |pattern|
        menu_blocks.each do |block|
          next if exclude_types.include?(block.type)

          block.expand_variables_in_attributes!(pattern, replacements)
        end
      end
    end

    def expand_references!(fcb, link_state)
      expand_variable_references!(
        blocks: [fcb],
        echo_formatter: method(:format_echo_command),
        group_name: :payload,
        initial_code_required: false,
        link_state: link_state,
        pattern: @delegate_object[:option_expansion_expression_regexp].present? &&
          Regexp.new(@delegate_object[:option_expansion_expression_regexp])
      )

      # variable expansions
      expand_variable_references!(
        blocks: [fcb],
        echo_formatter: lambda do |variable|
          %(echo "$#{variable}")
        end,
        group_name: @delegate_object[:variable_expansion_name_capture_group]&.to_sym,
        initial_code_required: false,
        link_state: link_state,
        pattern: options_variable_expansion_regexp
      )

      # command substitutions
      expand_variable_references!(
        blocks: [fcb],
        echo_formatter: lambda { |command| command },
        group_name: @delegate_object[:command_substitution_name_capture_group]&.to_sym,
        initial_code_required: false,
        link_state: link_state,
        pattern: options_command_substitution_regexp
      )
    end

    def expand_variable_references!(
      blocks:,
      echo_formatter:,
      group_name:,
      initial_code_required: false,
      link_state:,
      pattern:
    )
      variable_counts, occurrence_expressions = count_named_group_occurrences(
        blocks, pattern, group_name: group_name
      )
      return if variable_counts.nil? || variable_counts == {}

      echo_commands = generate_echo_commands(
        variable_counts, formatter: echo_formatter
      )

      replacements = build_replacement_dictionary(
        echo_commands, link_state,
        initial_code_required: initial_code_required,
        occurrence_expressions: occurrence_expressions
      )

      return if replacements.nil?
      return if replacements == EvaluateShellExpression::StatusFail

      expand_blocks_with_replacements(blocks, replacements)
    end

    def export_echo_with_code(
      bash_script_lines, export, force:
    )
      exportable = true
      command_result = nil
      new_lines = []
      case export.echo
      when String, Integer, Float, TrueClass, FalseClass
        command_result = output_from_adhoc_bash_script_file(
          join_array_of_arrays(
            bash_script_lines,
            %(printf '%s' "#{export.echo}")
          )
        )
        if command_result.exit_status == EXIT_STATUS_REQUIRED_EMPTY
          exportable = false
          command_result.warning = warning_required_empty(export)
        end

      when Hash
        # each item in the hash is a variable name and value
        export.echo.each do |name, expression|
          command_result = output_from_adhoc_bash_script_file(
            join_array_of_arrays(
              bash_script_lines,
              %(printf '%s' "#{expression}")
            )
          )
          if command_result.exit_status == EXIT_STATUS_REQUIRED_EMPTY
            command_result.warning = warning_required_empty(export)
          else
            ENV[name] = command_result.stdout.to_s
            new_lines << code_line_safe_assign(name, command_result.stdout,
                                               force: force)
          end
        end

        # individual items have been exported, none remain
        exportable = false
      end

      [command_result, exportable, new_lines]
    end

    # Retrieves a specific data symbol from the delegate object,
    # converts it to a string, and applies a color style
    # based on the specified color symbol.
    #
    # @param default [String] The default value
    #  if the data symbol is not found.
    # @param data_sym [Symbol] The symbol key to
    #  fetch data from the delegate object.
    # @param color_sym [Symbol] The symbol key to
    #  fetch the color option for styling.
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

    # Search in @dml_blocks_in_file first,
    # fallback to @dml_menu_blocks if not found.
    def find_block_by_name(blocks, block_name)
      match_block = ->(item) do
        [item.pub_name, item.nickname,
         item.oname, item.s2title].include?(block_name)
      end

      @dml_blocks_in_file.find(&match_block) ||
        @dml_menu_blocks.find(&match_block)
    end

    # find a block by its original (undecorated) name or nickname (not visible in menu)
    # if matched, the block returned has properties that it is from cli and not ui
    def find_block_state_by_name(block_name)
      SelectedBlockMenuState.new(
        find_block_by_name(@dml_blocks_in_file, block_name),
        OpenStruct.new(
          block_name_from_cli: true,
          block_name_from_ui: false
        ),
        MenuState::CONTINUE
      )
    end

    def find_option_by_name(name)
      name_sym = name.to_sym
      @menu_from_yaml.find do |option|
        option[:opt_name] == name_sym
      end
    end

    def format_and_execute_command(
      code_lines:,
      erls:,
      shell:
    )
      formatted_command = code_lines.flatten.join("\n")
      @fout.fout fetch_color(data_sym: :script_execution_head,
                             color_sym: :script_execution_frame_color)

      command_execute(
        formatted_command,
        args: @pass_args,
        erls: erls,
        shell: shell
      )
      @fout.fout fetch_color(data_sym: :script_execution_tail,
                             color_sym: :script_execution_frame_color)
    end

    def format_echo_command(payload)
      payload_match = payload.match(@delegate_object[:option_expansion_payload_regexp])
      variable = payload_match[:option]
      property = payload_match[:property]

      echo_value = case property
                   when 'default', 'description'
                     item = find_option_by_name(variable)
                     item ? item[property.to_sym] : ''
                   when 'length'
                     @delegate_object[variable.to_sym].to_s.length
                   else
                     @delegate_object[variable.to_sym]
                   end

      "echo #{Shellwords.escape(echo_value)}"
    end

    # Format expression using environment variables and run state
    def format_expression(expr)
      data = link_load_format_data
      ENV.each { |key, value| data[key.to_sym] = value }
      format(expr, data)
    end

    # Formats a string based on a given context and
    #  applies color styling to it.
    # It retrieves format and color information from
    #  the delegate object and processes accordingly.
    #
    # @param default [String] The default value if the format symbol
    #  is not found (unused in current implementation).
    # @param context [Hash] Contextual data used for string formatting.
    # @param format_sym [Symbol] Symbol key to fetch the format string
    #  from the delegate object.
    # @param color_sym [Symbol] Symbol key to fetch the color option
    #  for string styling.
    # @return [String] The formatted and color-styled string.
    def format_references_send_color(
      color_sym: :execution_report_preview_frame_color,
      context: {},
      default: '',
      format_sym: :output_execution_label_format
    )
      formatted_string = format(@delegate_object.fetch(format_sym, ''),
                                context).to_s
      string_send_color(formatted_string, color_sym)
    end

    # Expand expression if it contains format specifiers
    def formatted_expression(expr)
      expr.include?('%{') ? format_expression(expr) : expr
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

    def generate_echo_commands(variable_counts, formatter: nil)
      # commands to echo variables
      #
      commands = {}
      variable_counts.each_key do |variable|
        commands[variable] = formatter.call(variable)
      end
      commands
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

    # Updates the delegate object's state based on the provided block state.
    # It sets the block name and determines
    #  if the user clicked the back link in the menu.
    #
    # @param block_state [Object] An object representing the
    #  state of a block in the menu.
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
            if @run_state.files.streams
              @run_state.files.append_stream_line(file_type, line)
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

    def history_files(
      direction: :reverse,
      filename: nil,
      home: Dir.pwd,
      order: :chronological,
      path: ''
    )
      files = Dir.glob(
        File.join(home, path, filename)
      )
      sorted_files = case order
                     when :alphabetical
                       files.sort
                     when :chronological
                       files.sort_by { |file| File.mtime(file) }
                     else
                       raise ArgumentError, "Invalid order: #{order}"
                     end

      direction == :reverse ? sorted_files.reverse : sorted_files
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
        fcb: persist_fcb(id: 'INIT'),
        in_fenced_block: false,
        headings: []
      }
    end

    def interactive_menu_with_display_modes(
      menu_entries,
      display_formats:,
      display_mode_option:,
      exit_option:,
      menu_title:,
      pause_after_selection:
    )
      pause_menu = false
      current_display_format = display_formats.first

      loop do
        break if pause_menu && (prompt_select_continue == MenuState::EXIT)

        menu_options = build_menu_options(
          exit_option, display_mode_option,
          menu_entries, current_display_format
        )

        selection = prompt_select_from_list(
          menu_options,
          string: menu_title,
          color_sym: :prompt_color_after_script_execution
        )

        case selection
        when exit_option
          break
        when display_mode_option
          current_display_format = next_item(
            display_formats, current_display_format
          )
          pause_menu = false
        else
          handle_selection(menu_entries, selection,
                           current_display_format) do |item|
            yield item if block_given?
          end
          pause_menu = pause_after_selection
        end
      end
    end

    def handle_selection(menu_entries, selection, current_display_format)
      selected_item = menu_entries.find do |entry|
        entry.send(current_display_format) == selection
      end
      yield selected_item if selected_item
    end

    # Iterates through blocks in a file, applying the provided block to each line.
    # The iteration only occurs if the file exists.
    # @yield [Symbol] :filter Yields to obtain selected messages for processing.
    def iter_blocks_from_nested_files(&block)
      return unless check_file_existence(@delegate_object[:filename])

      state = initial_state
      selected_types = yield :filter
      cfile.readlines(
        @delegate_object[:filename],
        import_paths: options_import_paths
      ).each_with_index do |nested_line, index|
        next unless nested_line

        update_line_and_block_state(
          nested_line, state, selected_types,
          source_id: "#{@delegate_object[:filename]}¤ItrBlkFrmNstFls:#{index}",
          &block
        )
      end
    end

    def iter_source_blocks(source, source_id: nil, &block)
      case source
      when 1
        blocks_from_nested_files(source_id: source_id).blocks.each(&block)
      when 2
        @dml_blocks_in_file.each(&block)
      when 3
        @dml_menu_blocks.each(&block)
      else
        iter_blocks_from_nested_files do |btype, fcb|
          case btype
          when :blocks
            yield fcb
          when :filter
            %i[blocks]
          end
        end
      end
    end

    # join a list of arrays into a single array
    # convert single items to arrays
    def join_array_of_arrays(*args)
      args.map do |item|
        item.is_a?(Array) ? item : [item]
      end.compact.flatten(1)
    end

    def link_block_data_eval(link_state, code_lines, selected, link_block_data,
                             block_source:, shell:)
      all_code = HashDelegator.code_merge(link_state&.inherited_lines,
                                          code_lines)
      output_lines = []

      Tempfile.open do |file|
        cmd = "#{shell} #{file.path}"
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
            format1: @delegate_object.fetch(:output_assignment_format, nil),
            name: ''
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

      ([
        if label_format_above.present?
          format(
            label_format_above,
            block_source.merge({ block_name: selected.pub_name })
          )
        else
          nil
        end
      ] +
      output_lines.map do |line|
        re = Regexp.new(link_block_data.fetch('pattern', '(?<line>.*)'))
        next unless re =~ line

        re.gsub_format(
          line,
          link_block_data.fetch('format', '%{line}')
        )
      end +
      [
        if label_format_below.present?
          format(
            label_format_below,
            block_source.merge({ block_name: selected.pub_name })
          )
        else
          nil
        end
      ]).compact
    end

    def link_history_push_and_next(
      curr_block_name:, curr_document_filename:,
      inherited_block_names:, inherited_dependencies:, inherited_lines:,
      keep_code:,
      next_block_name:, next_document_filename:,
      next_keep_code:,
      next_load_file:
    )
      @link_history.push(
        LinkState.new(
          block_name: curr_block_name,
          document_filename: curr_document_filename,
          inherited_block_names: inherited_block_names,
          inherited_dependencies: inherited_dependencies,
          inherited_lines: inherited_lines,
          keep_code: keep_code
        )
      )
      LoadFileLinkState.new(
        next_load_file,
        LinkState.new(
          block_name: next_block_name,
          document_filename: next_document_filename,
          inherited_block_names: inherited_block_names,
          inherited_dependencies: inherited_dependencies,
          inherited_lines: inherited_lines,
          keep_code: next_keep_code
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
        started_at: Time.now.utc.strftime(
          @delegate_object[:execute_command_title_time_format]
        )
      }
    end

    def list_blocks(source_id: nil)
      message = @delegate_object[:list_blocks_message]
      block_eval = @delegate_object[:list_blocks_eval]

      list = []
      iter_source_blocks(
        @delegate_object[:list_blocks_type],
        source_id: source_id
      ) do |block|
        list << (block_eval.present? ? eval(block_eval) : block.send(message))
      end
      list.compact!

      @fout.fout_list(list)
    end

    # Loads and updates auto options for document blocks if the current filename has changed.
    #
    # This method checks if the delegate object specifies a document load options block name and if the filename
    # has been updated. It then selects the appropriate blocks, collects their dependencies, processes their
    # options, and updates the menu base with the merged options.
    #
    # @param all_blocks [Array] An array of all block elements.
    # @param mdoc [Object] The document object managing dependencies and options.
    # @return [Boolean, nil] Returns true if options were updated; nil otherwise.
    def load_auto_opts_block(all_blocks, mdoc:)
      opts_block_name = @delegate_object[:document_load_opts_block_name]
      current_filename = @delegate_object[:filename]

      return unless opts_block_name.present? &&
                    @opts_most_recent_filename != current_filename

      selected_blocks = HashDelegator.block_select(all_blocks, :oname,
                                                   opts_block_name)
      return if selected_blocks.empty?

      dependency_map = {}
      selected_blocks.each do |block|
        mdoc.collect_dependencies(memo: dependency_map, block: block)
      end

      collected_options =
        dependency_map.each.with_object({}) do |(block_id, _), merged_options|
          matching_block = HashDelegator.block_find(all_blocks, :id, block_id)
          options_state = read_show_options_and_trigger_reuse(
            mdoc: mdoc, selected: matching_block
          )
          merged_options.merge!(options_state.options)
        end

      update_menu_base(collected_options)
      @opts_most_recent_filename = current_filename
      true
    end

    def load_auto_vars_block(
      all_blocks,
      block_name: @delegate_object[:document_load_vars_block_name]
    )
      unless block_name.present? &&
             @vars_most_recent_filename != @delegate_object[:filename]
        return
      end

      blocks = HashDelegator.block_select(all_blocks, :oname, block_name)
      return if blocks.empty?

      @vars_most_recent_filename = @delegate_object[:filename]

      (blocks.each.with_object([]) do |block, merged_options|
        merged_options.push(
          code_from_vars_block_to_set_environment_variables(block)
        )
      end).to_a
    end

    def load_cli_or_user_selected_block(all_blocks: [], menu_blocks: [],
                                        prior_answer: nil)
      if @delegate_object[:block_name].present?
        block = all_blocks.find do |item|
          item.pub_name == @delegate_object[:block_name]
        end
        source = OpenStruct.new(block_name_from_ui: false)
      else
        block_state = wait_for_user_selected_block(all_blocks, menu_blocks,
                                                   prior_answer)
        return if block_state.nil?

        block = block_state.block
        source = OpenStruct.new(block_name_from_ui: true)
        state = block_state.state
      end

      SelectedBlockMenuState.new(block, source, state)
    end

    def load_document_shell_block(all_blocks, mdoc: nil)
      block_name = @delegate_object[:document_load_shell_block_name]
      unless block_name.present? &&
             @shell_most_recent_filename != @delegate_object[:filename]
        return
      end

      fcb = HashDelegator.block_find(all_blocks, :oname, block_name)
      return unless fcb

      @shell_most_recent_filename = @delegate_object[:filename]

      if mdoc
        mdoc.collect_recursively_required_code(
          anyname: fcb.pub_name,
          label_format_above: @delegate_object[:shell_code_label_format_above],
          label_format_below: @delegate_object[:shell_code_label_format_below],
          block_source: block_source
        )[:code]
      else
        fcb.body
      end
    end

    # format + glob + select for file in load block
    # name has references to ENV vars and doc and batch vars
    #  incl. timestamp
    def load_filespec_from_expression(expression)
      # Process expression with embedded formatting
      expanded_expression = formatted_expression(expression)

      # Handle wildcards or direct file specification
      if contains_glob?(expanded_expression)
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
        case (name = prompt_select_from_list(
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

    def manage_cli_selection_state(block_name_from_cli:, now_using_cli:,
                                   link_state:)
      if block_name_from_cli &&
         @cli_block_name == @menu_base_options[:menu_persist_block_name]
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

    def mdoc_and_blocks_from_nested_files(source_id: nil)
      blocks_results = blocks_from_nested_files(source_id: source_id)

      blocks_results.results.select do |_id, result|
        result.failure?
      end.each do |id, result|
        HashDelegator.error_handler("#{id} - #{result.to_yaml}")
      end

      mdoc = MDoc.new(blocks_results.blocks) do |nopts|
        @delegate_object.merge!(nopts)
      end

      [blocks_results.blocks, mdoc]
    end

    ## Handles the file loading and returns the blocks
    #  in the file and MDoc instance
    #
    def mdoc_menu_and_blocks_from_nested_files(link_state, source_id: '')
      # read blocks, load document opts block, and re-process blocks
      #
      reload_blocks = false

      all_blocks, mdoc = mdoc_and_blocks_from_nested_files(source_id: source_id)
      if load_auto_opts_block(all_blocks, mdoc: mdoc)
        reload_blocks = true
      end

      # load document shell block
      #
      if (code_lines = load_document_shell_block(all_blocks, mdoc: mdoc))
        next_state_set_code(nil, link_state, code_lines)
        link_state.inherited_lines = code_lines
        reload_blocks = true
      end

      # load document ux block
      #
      if (code_lines = code_from_automatic_ux_blocks(all_blocks, mdoc))
        new_code = HashDelegator.code_merge(link_state.inherited_lines,
                                            code_lines)
        next_state_set_code(nil, link_state, new_code)
        link_state.inherited_lines = new_code
        reload_blocks = true
      end

      # load document vars block
      #
      if (code_lines = load_auto_vars_block(all_blocks))
        new_code = HashDelegator.code_merge(link_state.inherited_lines,
                                            code_lines)
        next_state_set_code(nil, link_state, new_code)
        link_state.inherited_lines = new_code
        reload_blocks = true
      end

      if reload_blocks
        all_blocks, mdoc = mdoc_and_blocks_from_nested_files(source_id: source_id)
      end

      # filter by name, collapsed
      #
      menu_blocks = mdoc.fcbs_per_options(
        @delegate_object.merge!(compressed_ids: @compressed_ids,
                                expanded_ids: @expanded_ids)
      )

      # restore pre-expansion (raw) values
      #
      menu_blocks.each do |fcb|
        fcb.dname = fcb.raw_dname unless fcb.raw_dname.nil?
        fcb.s0printable = fcb.raw_s0printable unless fcb.raw_s0printable.nil?
        fcb.s1decorated = fcb.raw_s1decorated unless fcb.raw_s1decorated.nil?
        fcb.body = fcb.raw_body unless fcb.raw_body.nil?
      end

      # re-expand blocks
      #
      menu_blocks.each do |fcb|
        fcb.body = fcb.raw_body || fcb.body || []
        fcb.name_in_menu!(fcb.raw_dname || fcb.dname)
        fcb.s0printable = fcb.raw_s0printable || fcb.s0printable
        fcb.s1decorated = fcb.raw_s1decorated || fcb.s1decorated
        expand_references!(fcb, link_state)
      end

      # chrome for menu
      #
      add_menu_chrome_blocks!(
        link_state: link_state,
        menu_blocks: menu_blocks,
        source_id: source_id
      )

      HashDelegator.delete_consecutive_blank_lines!(menu_blocks)
      begin
        HashDelegator.tables_into_columns!(menu_blocks, @delegate_object,
                                           screen_width_for_table)
      rescue NoMethodError
        # an invalid table format
      end
      handle_consecutive_inactive_items!(menu_blocks)

      [all_blocks, menu_blocks, mdoc]
    end

    def handle_consecutive_inactive_items!(menu_blocks)
      consecutive_inactive_count = 0
      menu_blocks.each do |fcb|
        unless fcb.is_disabled?
          consecutive_inactive_count = 0
        else
          consecutive_inactive_count += 1
          if (consecutive_inactive_count % (@delegate_object[:select_page_height] / 3)).zero?
            fcb.disabled = TtyMenu::ENABLE
            fcb.is_enabled_but_inactive = true
          end
        end
      end
    end

    def menu_add_disabled_option(document_glob)
      raise unless document_glob.present?
      raise if @dml_menu_blocks.nil?

      block = @dml_menu_blocks.find { |item| item.oname == document_glob }

      # create menu item when it is needed (count > 0)
      #
      return unless block.nil?

      chrome_block = persist_fcb(
        chrome: true,
        disabled: TtyMenu::DISABLE,
        dname: HashDelegator.new(@delegate_object).string_send_color(
          document_glob, :menu_inherited_lines_color
        ),
        # 2025-01-03 menu item is disabled ∴ does not need a recall id
        oname: formatted_name
      )

      if insert_at_top
        @dml_menu_blocks.unshift(chrome_block)
      else
        @dml_menu_blocks.push(chrome_block)
      end
    end

    # Formats and optionally colors a menu option based on delegate
    #  object's configuration.
    # @param option_symbol [Symbol] The symbol key for the menu option
    #  in the delegate object.
    # @return [String] The formatted and possibly colored value
    #  of the menu option.
    def menu_chrome_colored_option(option_symbol = :menu_option_back_name)
      formatted_option = menu_chrome_formatted_option(option_symbol)
      return formatted_option unless @delegate_object[:menu_chrome_color]

      string_send_color(formatted_option, :menu_chrome_color)
    end

    # Formats a menu option based on the delegate object's configuration.
    # It safely evaluates the value of the option and optionally formats it.
    # @param option_symbol [Symbol] The symbol key for the menu option in
    #  the delegate object.
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

    def menu_from_list_with_back(list)
      case (name = prompt_select_from_list(
        [@delegate_object[:prompt_filespec_back]] + list,
        string: @delegate_object[:prompt_select_code_file],
        color_sym: :prompt_color_after_script_execution
      ))
      when @delegate_object[:prompt_filespec_back]
        SelectResponse::BACK
      else
        name
      end
    end

    def menu_toggle_collapsible_block(selected)
      # return true if @compress_ids.key?(fcb.id) && !!@compress_ids[fcb.id]
      # return false if @expand_ids.key?(fcb.id) && !!@expand_ids[fcb.id]
      if @compressed_ids.key?(selected.id) && !!@compressed_ids[selected.id]
        @compressed_ids.delete(selected.id)
        @expanded_ids[selected.id] = selected.level
      else # @expand_ids.key?(fcb.id) && !!@expand_ids[fcb.id]
        @compressed_ids[selected.id] = selected.level
        @expanded_ids.delete(selected.id)
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

    def next_item(list, current_item)
      index = list.index(current_item)
      return nil unless index # Return nil if the item is not in the list

      list[(index + 1) % list.size] # Get the next item, wrap around if at the end
    end

    def next_state_append_code(selected, link_state, code_lines)
      next_state_set_code(
        selected,
        link_state,
        HashDelegator.code_merge(
          link_state&.inherited_lines,
          code_lines.is_a?(Array) ? code_lines : [] # no code for :ux_exec_prohibited
        )
      )
    end

    def next_state_set_code(selected, link_state, code_lines)
      block_names = []
      dependencies = {}
      link_history_push_and_next(
        curr_block_name: selected&.pub_name,
        curr_document_filename: @delegate_object[:filename],
        inherited_block_names:
          ((link_state&.inherited_block_names || []) + block_names).sort.uniq,
        inherited_dependencies:
          (link_state&.inherited_dependencies || {}).merge(dependencies || {}), ### merge, not replace, key data
        inherited_lines: HashDelegator.code_merge(code_lines),
        keep_code: link_state&.keep_code,
        next_block_name: '',
        next_document_filename: @delegate_object[:filename],
        next_keep_code: false,
        next_load_file: LoadFile::REUSE
      )
    end

    def options_command_substitution_regexp
      Regexp.new(@delegate_object[:command_substitution_regexp] || '')
    end

    def options_import_paths
      @delegate_object[:import_paths]&.split(':') || ''
    end

    def options_variable_expansion_regexp
      @delegate_object[:variable_expansion_regexp].present? &&
        Regexp.new(@delegate_object[:variable_expansion_regexp])
    end

    def output_color_formatted(data_sym, color_sym)
      formatted_string = string_send_color(@delegate_object[data_sym],
                                           color_sym)
      @fout.fout formatted_string
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

    def output_from_adhoc_bash_script_file(bash_script_lines)
      Tempfile.create('script_exec') do |temp_file|
        temp_file.write(HashDelegator.join_code_lines(bash_script_lines))
        temp_file.flush
        File.chmod(0o755, temp_file.path)

        output = `#{temp_file.path}`

        CommandResult.new(stdout: output, exit_status: $?.exitstatus)
      end
    rescue StandardError => err
      warn "Error executing script: #{err.message}"
      nil
    end

    def output_labeled_value(label, value, level)
      @fout.lout format_references_send_color(
        context: {
          name: string_send_color(label, :output_execution_label_name_color),
          value: string_send_color(value.to_s,
                                   :output_execution_label_value_color)
        },
        format_sym: :output_execution_label_format
      ), level: level
    end

    def pause_user_exit
      @delegate_object[:pause_after_script_execution] &&
        prompt_select_continue == MenuState::EXIT
    end

    def persist_fcb(options)
      HashDelegator.persist_fcb_self(@fcb_store, options)
    end

    def pop_add_current_code_to_head_and_trigger_load(
      link_state, block_names, code_lines,
      dependencies, selected, next_block_name: nil
    )
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
        # no history exists; must have been called independently
        #  => retain script
        link_history_push_and_next(
          curr_block_name: selected.pub_name,
          curr_document_filename: @delegate_object[:filename],
          inherited_block_names:
           ((link_state&.inherited_block_names || []) + block_names).sort.uniq,
          inherited_dependencies:
           (link_state&.inherited_dependencies || {}).merge(dependencies || {}), ### merge, not replace, key data
          inherited_lines:
           HashDelegator.code_merge(link_state&.inherited_lines, code_lines),
          keep_code: link_state&.keep_code,
          next_block_name: next_block_name,
          next_document_filename: @delegate_object[:filename], # not next_document_filename
          next_keep_code: false,
          next_load_file: LoadFile::REUSE # not next_document_filename == @delegate_object[:filename] ? LoadFile::REUSE : LoadFile::LOAD
        )
        # LoadFileLinkState.new(LoadFile::REUSE, link_state)
      end
    end

    # This method handles the back-link operation in the Markdown execution context.
    # It updates the history state for the next block.
    #
    # @return [LinkState] An object indicating the state for
    #  the next block.
    def pop_link_history_new_state
      pop = @link_history.pop
      peek = @link_history.peek
      LinkState.new(
        document_filename: pop.document_filename,
        inherited_block_names: peek.inherited_block_names,
        inherited_dependencies: peek.inherited_dependencies,
        inherited_lines: peek.inherited_lines
      )
    end

    def post_execution_process
      do_save_execution_output
      output_execution_summary
      fout_execution_report if @delegate_object[:output_execution_report]
    end

    # all UX blocks are automatic for the document
    def select_automatic_ux_blocks(blocks)
      blocks.select { |item| item.type == 'ux' }
    end

    # Filter blocks per block_name_include_match, block_name_wrapper_match.
    #
    # @param all_blocks [Array<Hash>] The list of blocks from the file.
    def select_blocks(menu_blocks)
      menu_blocks.reject do |fcb|
        Filter.prepared_not_in_menu?(
          @delegate_object,
          fcb,
          %i[block_name_include_match block_name_wrapper_match]
        )
      end
    end

    # Filter blocks per block_name_include_match, block_name_wrapper_match.
    # Set name displayed by tty-prompt.
    #
    # @param all_blocks [Array<Hash>] The list of blocks from the file.
    # @param opts [Hash] The options hash.
    # @return [Array<Hash>] The updated blocks menu.
    def blocks_as_menu_items(menu_blocks)
      # prefix first active line, inactive for rest
      active = @delegate_object[:prompt_margin_left_text]
      inactive = ' ' * active.length

      select_blocks(menu_blocks).map do |fcb|
        multiline = fcb.indented_decorated ||
                    (fcb.indent + (fcb.s1decorated || fcb.dname))

        fcb.name = multiline.each_line.with_index.map do |line, index|
          if fcb.fetch(:disabled, nil).nil?
            index.zero? ? active : inactive
          else
            inactive
          end + line.chomp
        end.join("\n")

        fcb.value = fcb.id || fcb.name.split("\n").first

        fcb.to_h
      end
    end

    def print_formatted_option(key, value)
      formatted_str = format(@delegate_object[:menu_opts_set_format],
                             { key: key, value: value })
      print string_send_color(formatted_str, :menu_opts_set_color)
    end

    # private

    def process_string_array(arr, begin_pattern: nil, end_pattern: nil, scan1: nil,
                             format1: nil, name: '')
      in_block = !begin_pattern.present?
      collected_lines = []

      arr.each do |line|
        if in_block
          if end_pattern.present? && line.match?(end_pattern)
            in_block = false
          elsif scan1.present?
            if format1.present?
              caps = NamedCaptureExtractor.extract_named_groups(line, scan1)
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
          elsif format1.present?
            formatted = format(format1, { value: line })
            collected_lines << formatted
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
    end

    def prompt_for_command(prompt)
      print prompt

      gets.chomp
    rescue Interrupt
      nil
    end

    # Prompts the user to enter a path or name to substitute
    #  into the wildcard expression.
    # If interrupted by the user (e.g., pressing Ctrl-C), it
    #  returns nil.
    #
    # @param filespec [String] the wildcard expression to be
    #  substituted
    # @return [String, nil] the resolved path or substituted
    #  expression, or nil if interrupted
    def prompt_for_filespec_with_wildcard(filespec)
      puts format(@delegate_object[:prompt_show_expr_format],
                  { expr: filespec })
      puts @delegate_object[:prompt_enter_filespec]

      begin
        input = $stdin.gets.chomp
        PathUtils.resolve_path_or_substitute(input, filespec)
      rescue Interrupt
        puts "\nOperation interrupted. Returning nil."
        nil
      end
    end

    ##
    # Presents a menu to the user for approving an action
    #  and performs additional tasks based on the selection.
    # The function provides options for approval, rejection,
    #  copying data to clipboard, or saving data to a file.
    #
    # @param opts [Hash] A hash containing various options for the menu.
    # @param required_lines [Array<String>] Lines of text or
    #  code that are subject to user approval.
    #
    # @option opts [String] :prompt_approve_block
    #  Prompt text for the approval menu.
    # @option opts [String] :prompt_yes
    #  Text for the 'Yes' choice in the menu.
    # @option opts [String] :prompt_no
    #  Text for the 'No' choice in the menu.
    # @option opts [String] :prompt_script_to_clipboard Text
    #  for the 'Copy to Clipboard' choice in the menu.
    # @option opts [String] :prompt_save_script Text for the
    #  'Save to File' choice in the menu.
    #
    # @return [Boolean] Returns true if the user approves (selects 'Yes'),
    #  false otherwise.
    ##
    def prompt_for_user_approval(required_lines:, selected:)
      # Present a selection menu for user approval.
      sel = @prompt.select(
        string_send_color(@delegate_object[:prompt_approve_block],
                          :prompt_color_after_script_execution),
        filter: true
      ) do |menu|
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
        save_to_file(
          required_lines: required_lines, selected: selected,
          shell: selected.shell
        )
      end

      sel == MenuOptions::YES
    end

    def prompt_margin_left_text
      @delegate_object[:prompt_margin_left_text]
    end

    def prompt_margin_left_width
      prompt_margin_left_text.length
    end

    def prompt_margin_right_width
      0
    end

    def prompt_select_continue(filter: true, quiet: true)
      sel = @prompt.select(
        string_send_color(@delegate_object[:prompt_after_script_execution],
                          :prompt_color_after_script_execution),
        filter: filter,
        quiet: quiet
      ) do |menu|
        menu.choice @delegate_object[:prompt_yes]
        menu.choice @delegate_object[:prompt_exit]
      end
      sel == @delegate_object[:prompt_exit] ? MenuState::EXIT : MenuState::CONTINUE
    end

    # public

    def prompt_select_from_list(
      filenames,
      color_sym: :prompt_color_after_script_execution,
      cycle: true,
      enum: false,
      quiet: true,
      string: @delegate_object[:prompt_select_code_file]
    )
      @prompt.select(
        string_send_color(string, color_sym),
        cycle: cycle,
        filter: !enum,
        per_page: @delegate_object[:select_page_height],
        quiet: quiet
      ) do |menu|
        menu.enum '.' if enum
        filenames.each.with_index do |filename, ind|
          if enum
            menu.choice filename, ind + 1
          else
            menu.choice filename
          end
        end
      end
    end

    # user prompt to exit if the menu will be displayed again
    #
    def prompt_user_exit(block_name_from_cli:, selected:)
      selected.type == BlockType::SHELL &&
        @delegate_object[:pause_after_script_execution] &&
        prompt_select_continue == MenuState::EXIT
    end

    def publish_for_external_automation(message:)
      return if @delegate_object[:publish_document_file_name].empty?

      pipe_path = absolute_path(@delegate_object[:publish_document_file_name])

      case @delegate_object[:publish_document_file_mode]
      when 'append'
        File.write(pipe_path, "#{message}\n", mode: 'a')
      when 'fifo'
        unless @vux_pipe_open
          unless File.exist?(pipe_path)
            File.mkfifo(pipe_path)
            @vux_pipe_created = pipe_path
          end
          @vux_pipe_open = File.open(pipe_path, 'w')
        end
        @vux_pipe_open.puts("#{message}\n")
        @vux_pipe_open.flush
      when 'write'
        File.write(pipe_path, message)
      else
        raise 'Invalid publish_document_file_mode:' \
              " #{@delegate_object[:publish_document_file_mode]}"
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

    def read_saved_assets_for_history_table(
      asset: nil,
      filename: nil,
      form: @delegate_object[:saved_history_format],
      path: @delegate_object[:saved_script_folder],
      regexp: @delegate_object[:saved_asset_match]
    )
      history_files(
        filename:
          if asset.present?
            saved_asset_filename(asset, @dml_link_state)
          else
            filename
          end,
        path: path
      )&.map do |file|
        unless Regexp.new(regexp) =~ file
          warn "Cannot parse name: #{file}"
          next
        end

        saved_asset = saved_asset_for_history(
          file: file,
          form: form,
          match_info: $LAST_MATCH_INFO
        )
        saved_asset == :break ? nil : saved_asset
      end&.compact
    end

    # Processes YAML data from the selected menu item, updating delegate
    #  objects and optionally printing formatted output.
    # @param selected [Hash] Selected item from the menu containing a YAML body.
    # @param tgt2 [Hash, nil] An optional target hash to update with YAML data.
    # @return [LoadFileLinkState] An instance indicating the
    #  next action for loading files.
    def read_show_options_and_trigger_reuse(selected:,
                                            mdoc:, link_state: LinkState.new)
      obj = {}

      # concatenated body of all required blocks loaded a YAML
      data = (YAML.load(
        execute_block_type_port_code_lines(
          mdoc: mdoc, selected: selected,
          link_state: link_state, block_source: {}
        ).join("\n")
      ) || {}).transform_keys(&:to_sym)

      if selected.type == BlockType::OPTS
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
    # @param opts [Hash] a hash containing various options
    #  for the console settings.
    #   - :console_width [Integer, nil] The width of the console. If not
    #      provided or if the terminal is resized, it will be set to the
    #      current console width.
    #   - :console_height [Integer, nil] The height of the console.
    #      If not provided or if the terminal is resized, it will be set
    #      to the current console height.
    #   - :console_winsize [Array<Integer>, nil] The dimensions of the
    #      console [height, width]. If not provided or if the terminal
    #      is resized, it will be set to the current console dimensions.
    #   - :select_page_height [Integer, nil] The height of the page for
    #      selection. If not provided or if not positive, it
    #      will be set to the maximum of (console height - 3) or 4.
    #   - :per_page [Integer, nil] The number of items per page. If
    #      :select_page_height is not provided or if not positive, it
    #      will be set to the maximum of (console height - 3) or 4.
    #
    # @raise [StandardError] If an error occurs during the process, it
    #  will be caught and handled by calling HashDelegator.error_handler
    #  with 'register_console_attributes' and { abort: true }.
    #
    # @example
    #   opts = { console_width: nil, console_height: nil, select_page_height: nil }
    #   register_console_attributes(opts)
    #   # opts will be updated with the current console dimensions
    #   #  and pagination settings.
    def register_console_attributes(opts)
      return unless IO.console

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

    # private

    def replace_keys_in_lines(replacement_dictionary, lines)
      # Create a regex pattern that matches any key in the replacement dictionary
      pattern = Regexp.union(replacement_dictionary.keys.map do |key|
                               "%<#{key}>"
                             end)

      # Iterate over each line and apply gsub with the replacement hash
      lines.map do |line|
        line.gsub(pattern) { |match| replacement_dictionary[match] }
      end
    end

    def report_error(err)
      # Handle ENOENT error
      @run_state.aborted_at = Time.now.utc
      @run_state.error_message = err.message
      @run_state.error = err
      @run_state.files.append_stream_line(ExecutionStreams::STD_ERR,
                                          @run_state.error_message)
      @fout.fout err.inspect
    end

    # Check if the delegate object responds to a given method.
    # @param method_name [Symbol] The name of the method to check.
    # @param include_private [Boolean]
    #  Whether to include private methods in the check.
    # @return [Boolean] true if the delegate object responds
    #  to the method, false otherwise.
    def respond_to?(method_name, include_private = false)
      if super
        true
      elsif @delegate_object.respond_to?(method_name, include_private)
        true
      elsif method_name.to_s.end_with?('=') &&
            @delegate_object.respond_to?(:[]=, include_private)
        true
      else
        @delegate_object.respond_to?(method_name, include_private)
      end
    end

    def runtime_exception(exception_sym, name, items)
      if @delegate_object[exception_sym] != 0
        data = { name: name, detail: items.join(', ') }
        warn(
          AnsiString.new(
            format(
              @delegate_object.fetch(:exception_format_name, "\n%{name}"),
              data
            )
          ).send(@delegate_object.fetch(:exception_color_name, :red)) +
          AnsiString.new(
            format(
              @delegate_object.fetch(:exception_format_detail,
                                     " - %{detail}\n"),
              data
            )
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
      if contains_glob?(formatted)
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
        case (name = prompt_select_from_list(
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

    def save_to_file(
      erls:,
      required_lines:, selected:, shell:
    )
      write_command_file(
        required_lines: required_lines, blockname: selected.pub_name, shell: shell
      )
      @fout.fout "File saved: #{@run_state.saved_filespec}"
    end

    def saved_asset_filename(filename, link_state = LinkState.new)
      SavedAsset.new(
        filename: filename,
        saved_asset_format:
          shell_escape_asset_format(
            code_lines: link_state&.inherited_lines,
            shell: shell
          )
      ).generate_name
    end

    def saved_asset_for_history(
      file:, form:, match_info:
    )
      OpenStruct.new(
        file: file[(Dir.pwd.length + 1)..-1],
        full: file,
        row: format(
          form,
          # default '*' so unknown parameters are given a wildcard
          match_info.names.each_with_object(Hash.new('*')) do |name, hash|
            hash[name.to_sym] = match_info[name]
          end
        )
      )
    rescue KeyError
      # pp $!, $@
      warn "Cannot format with: #{@delegate_object[:saved_history_format]}"
      error_handler('saved_history_format')
      :break
    end

    def screen_width
      width = @delegate_object[:screen_width]
      if width&.positive?
        width
      else
        @delegate_object[:console_width]
      end
    end

    def screen_width_for_table
      # menu adds newline after some lines if sized to the edge
      screen_width - prompt_margin_left_width - prompt_margin_right_width - 3 # menu prompt symbol (1) + space (1) + gap (1)
    end

    def screen_width_for_wrapping
      screen_width_for_table
    end

    def select_document_if_multiple(options, files, prompt:)
      return files if files.instance_of?(String)
      return files[0] if (count = files.count) == 1

      return unless count >= 2

      opts = options.dup
      select_option_or_exit(
        string_send_color(
          prompt,
          :prompt_color_after_script_execution
        ),
        files,
        opts.merge(per_page: opts[:select_page_height])
      )
    end

    # Presents a TTY prompt to select an option or exit,
    #  returns metadata including option and selected
    def select_option_with_metadata(
      prompt_text, tty_menu_items, opts = {}, menu_blocks: nil
    )
      @dml_menu_blocks = menu_blocks if menu_blocks

      ## configure to environment
      #
      register_console_attributes(opts)

      active_color_pastel = Pastel.new
      active_color_pastel = opts[:menu_active_color_pastel_messages]
                            .inject(active_color_pastel) do |p, message|
                              p.send(message)
                            end

      begin
        props = {
          active_color: active_color_pastel.detach,
          # activate dynamic list searching on letter/number key presses
          cycle: true,
          filter: true,
          per_page: @delegate_object[:select_page_height]
        }.freeze

        if tty_menu_items.all? do |item|
          !item.is_a?(String) && item[:disabled]
        end
          tty_menu_items.each do |prompt_item|
            puts prompt_item[:dname]
          end
          return
        end

        # crashes if all menu options are disabled
        # crashes if default is not an existing item
        #
        selection = @prompt.select(prompt_text,
                                   tty_menu_items,
                                   opts.merge(props))
      rescue TTY::Prompt::ConfigurationError
        # prompt fails when collapsible block name has changed; clear default
        selection = @prompt.select(prompt_text,
                                   tty_menu_items,
                                   opts.merge(props).merge(default: nil))
      rescue NoMethodError
        # no enabled options in page
        return
      end

      menu_list = opts.fetch(:match_dml, true) ? @dml_menu_blocks : menu_items
      menu_list ||= tty_menu_items
      selected = menu_list.find do |item|
        if item.instance_of?(Hash)
          [item[:id], item[:name], item[:dname]].include?(selection)
        elsif item.instance_of?(MarkdownExec::FCB)
          item.id == selection
        else
          item == selection
        end
      end

      # new FCB if selected is not an object
      if selected.instance_of?(String)
        selected = FCB.new(dname: selected)
      elsif selected.instance_of?(Hash)
        selected = FCB.new(selected)
      end

      unless selected
        report_and_reraise('menu item not found')
        HashDelegator.error_handler('select_option_with_metadata',
                                    error: 'menu item not found')
        exit 1
      end

      if selection == menu_chrome_colored_option(:menu_option_back_name)
        selected.option = selection
        selected.type = BlockType::LINK
      elsif selection == menu_chrome_colored_option(:menu_option_exit_name)
        selected.option = selection
      else
        selected.selected = selection
      end

      selected
    end

    def shell
      @delegate_object[:shell]
    end

    def shell=(value)
      @delegate_object[:shell] = value
    end

    def shell_escape_asset_format(
      code_lines:,
      enable: @delegate_object[:shell_parameter_expansion],
      raw: @delegate_object[:saved_asset_format],
      shell:
    )
      return raw unless enable

      # unchanged if no parameter expansion takes place
      return raw unless /$/ =~ raw

      filespec = generate_temp_filename
      cmd = [shell, '-c', filespec].join(' ')

      marker = Random.new.rand.to_s

      code = (code_lines || []) + ["echo -n \"#{marker}#{raw}\""]
      # !!t code
      File.write filespec, HashDelegator.join_code_lines(code)
      File.chmod 0o755, filespec

      out = `#{cmd}`.sub(/.*?#{marker}/m, '')
      File.delete filespec
      out
    end

    def should_add_back_option?(
      menu_with_back: @delegate_object[:menu_with_back]
    )
      menu_with_back && @link_history.prior_state_exist?
    end

    def simple_menu_options; end

    # Initializes a new fenced code block (FCB) object based
    #  on the provided line and heading information.
    # @param line [String] The line initiating the fenced block.
    # @param headings [Array<String>] Current headings hierarchy.
    # @param fenced_start_extended_regex [Regexp]
    #  Regular expression to identify fenced block start.
    # @return [MarkdownExec::FCB] A new FCB instance with the parsed attributes.
    def start_fenced_block(
      line, headings, fenced_start_extended_regex, source_id: nil
    )
      fcb_title_groups = NamedCaptureExtractor.extract_named_groups(
        line, fenced_start_extended_regex
      )

      rest = fcb_title_groups.fetch(:rest, '')
      reqs, wraps =
        ArrayUtil.partition_by_predicate(rest.scan(/\+[^\s]+/).map do |req|
                                           req[1..-1]
                                         end) do |name|
        !name.match(Regexp.new(@delegate_object[:block_name_wrapper_match]))
      end

      # adjust captured type
      if fcb_title_groups[:type].present?
        case fcb_title_groups[:type]
        when *ShellType::ALL
          # convert type to shell
          fcb_title_groups[:shell] = fcb_title_groups[:type]
          fcb_title_groups[:type] = BlockType::SHELL
        end
      else
        # treat as the default shell
        fcb_title_groups[:shell] = @delegate_object[:block_type_default]
        fcb_title_groups[:type] = BlockType::SHELL
      end

      dname = oname = title = ''
      nickname = nil
      if @delegate_object[:block_name_nick_match].present? &&
         oname =~ Regexp.new(@delegate_object[:block_name_nick_match])
        nickname = $~[0]
      else
        dname = oname = title = fcb_title_groups.fetch(:name, '')
      end

      # disable fcb for data blocks
      disabled = if fcb_title_groups.fetch(:type, '') == BlockType::YAML
                   TtyMenu::DISABLE
                 else
                   TtyMenu::ENABLE
                 end

      persist_fcb(
        body: [],
        call: rest.match(
          Regexp.new(@delegate_object[:block_calls_scan])
        )&.to_a&.first,
        disabled: disabled,
        dname: dname,
        headings: headings,
        id: source_id.to_s,
        indent: fcb_title_groups.fetch(:indent, ''),
        nickname: nickname,
        oname: oname,
        reqs: reqs,
        shell: fcb_title_groups.fetch(:shell, ''),
        start_line: line,
        stdin: if (tn = rest.match(/<(?<type>\$)?(?<name>[A-Za-z_-]\S+)/))
                 NamedCaptureExtractor.extract_named_group_match_data(tn)
               end,
        stdout: if (tn = rest.match(/>(?<type>\$)?(?<name>[\w.\-]+)/))
                  NamedCaptureExtractor.extract_named_group_match_data(tn)
                end,
        title: title,
        type: fcb_title_groups.fetch(:type, ''),
        wraps: wraps
      )
    end

    # Applies a color method to a string based on the provided color symbol.
    # The color method is fetched from @delegate_object and applied to the string.
    # @param string [String] The string to which the color will be applied.
    # @param color_sym [Symbol] The symbol representing the color method.
    # @param default [String] Default color method to use if
    #  color_sym is not found in @delegate_object.
    # @return [String] The string with the applied color method.
    def string_send_color(string, color_sym)
      HashDelegator.apply_color_from_hash(string, @delegate_object, color_sym)
    end

    def transform_export_value(value, export)
      return value unless export.transform.present?

      if export.transform.is_a? Symbol
        value.send(export.transform)
      else
        format(
          export.transform,
          NamedCaptureExtractor.extract_named_groups(
            value, export.validate
          )
        )
      end
    end

    ##
    # Processes an individual line within a loop, updating headings
    #  and handling fenced code blocks.
    # This function is designed to be called within a loop that iterates
    #  through each line of a document.
    #
    # @param line [String] The current line being processed.
    # @param state [Hash] The current state of the parser, including flags
    #  and data related to the processing.
    # @param opts [Hash] A hash containing various options for line
    #  and block processing.
    # @param selected_types [Array<String>] Accumulator for lines
    #  or messages that are subject to further processing.
    # @param block [Proc] An optional block for further processing
    #  or transformation of lines.
    #
    # @option state [Array<String>] :headings Current headings
    #  to be updated based on the line.
    # @option state [Regexp] :fenced_start_and_end_regex Regular expression
    #  to match the start and end of a fenced block.
    # @option state [Boolean] :in_fenced_block Flag indicating whether
    #  the current line is inside a fenced block.
    # @option state [Object] :fcb An object representing
    # the current fenced code block being processed.
    #
    # @option opts [Boolean] :menu_blocks_with_headings Flag
    #  indicating whether to update headings while processing.
    #
    # @return [Void] The function modifies the `state`
    #  and `selected_types` arguments in place.
    ##
    def update_line_and_block_state(
      nested_line, state, selected_types,
      source_id:,
      &block
    )
      line = nested_line.to_s
      if line.match(@delegate_object[:fenced_start_and_end_regex])
        if state[:in_fenced_block]
          ## end of code block
          #
          HashDelegator.update_menu_attrib_yield_selected(
            fcb: state[:fcb],
            messages: selected_types,
            configuration: @delegate_object,
            &block
          )
          state[:in_fenced_block] = false
        else
          ## start of code block
          #
          state[:fcb] = start_fenced_block(
            line, state[:headings],
            @delegate_object[:fenced_start_extended_regex],
            source_id: source_id
          )
          state[:fcb][:depth] = nested_line[:depth]
          state[:fcb][:indention] = nested_line[:indention]
          state[:in_fenced_block] = true
        end
      elsif state[:in_fenced_block] && state[:fcb].body
        ## add line to fenced code block
        # remove fcb indent if possible
        #
        state[:fcb].body += [
          line.chomp.sub(/^#{state[:fcb].indent}/, '')
        ]
      elsif nested_line[:depth].zero? ||
            @delegate_object[:menu_include_imported_notes]
        # add line if it is depth 0 or option allows it
        #
        HashDelegator.yield_line_if_selected(
          line, selected_types,
          all_fcbs: @fcb_store,
          source_id: source_id, &block
        )
      end
    end

    ## apply options to current state
    #
    def update_menu_base(options)
      # under simple uses, @menu_base_options may be nil
      @menu_base_options&.merge!(options)
      @delegate_object.merge!(options)
    end

    def ux_block_export_activated(
      bash_script_lines, export, exit_prompt
    )
      exportable = true
      transformable = true
      new_lines = []
      command_result = nil

      case as = FCB.act_source(export)####
      when false, UxActSource::FALSE
        raise 'Should not be reached.'

      when ':allow', UxActSource::ALLOW
        raise unless export.allow.present?

        case export.allow
        when :echo, ExportValueSource::ECHO
          command_result, exportable, new_lines = export_echo_with_code(
            bash_script_lines,
            export,
            force: true
          )
          if command_result.failure?
            command_result
          else
            command_result = CommandResult.new(
              stdout: menu_from_list_with_back(command_result.stdout.split("\n"))
            )
          end

        when ':exec', UxActSource::EXEC
          command_result = output_from_adhoc_bash_script_file(
            join_array_of_arrays(bash_script_lines, export.exec)
          )

          if command_result.exit_status == EXIT_STATUS_REQUIRED_EMPTY
            command_result
          else
            command_result = CommandResult.new(
              stdout: menu_from_list_with_back(
                command_result.stdout.split("\n")
              )
            )
          end

        else
          command_result = CommandResult.new(
            stdout: menu_from_list_with_back(export.allow)
          )
        end

      when ':echo', UxActSource::ECHO
        command_result, exportable, new_lines = export_echo_with_code(
          bash_script_lines,
          export,
          force: true
        )

        command_result

      when ':edit', UxActSource::EDIT
        output = nil
        begin
          loop do
            print "#{export.prompt} [#{export.default}]: "
            output = gets.chomp
            output = export.default.to_s if output.empty?
            caps = NamedCaptureExtractor.extract_named_groups(output,
                                                              export.validate)
            break if caps

            # invalid input, retry
          end
        rescue Interrupt
          exportable = false
          transformable = false
        end

        command_result = CommandResult.new(stdout: output)

      when ':exec', UxActSource::EXEC
        command_result = output_from_adhoc_bash_script_file(
          join_array_of_arrays(bash_script_lines, export.exec)
        )

        command_result

      else
        transformable = false
        command_result = CommandResult.new(stdout: export.default.to_s)
      end

      # add message for required variables
      if command_result.exit_status == EXIT_STATUS_REQUIRED_EMPTY
        command_result.warning = warning_required_empty(export)
        # warn command_result.warning
      end

      command_result.exportable = exportable
      command_result.transformable = transformable
      command_result.new_lines = new_lines
      command_result
    end

    def ux_block_export_automatic(bash_script_lines, export)
      transformable = true
      exportable = true
      new_lines = []
      command_result = nil

      case FCB.init_source(export)
      when false, UxActSource::FALSE
        exportable = false
        transformable = false
        command_result = CommandResult.new

      when ':allow', UxActSource::ALLOW
        raise unless export.allow.present?

        case export.allow
        when :echo, ExportValueSource::ECHO
          command_result, exportable, new_lines = export_echo_with_code(
            bash_script_lines,
            export,
            force: false
          )
          unless command_result.failure?
            command_result.stdout = (exportable && command_result.stdout.split("\n").first) || ''
          end

        when :exec, ExportValueSource::EXEC
          command_result = output_from_adhoc_bash_script_file(
            join_array_of_arrays(bash_script_lines, export.exec)
          )
          unless command_result.failure?
            command_result.stdout = command_result.stdout.split("\n").first
          end

        else
          # must be a list
          command_result = CommandResult.new(stdout: export.allow.first)
        end

      when ':default', UxActSource::DEFAULT
        transformable = false
        command_result = CommandResult.new(stdout: export.default.to_s)

      when ':echo', UxActSource::ECHO
        raise unless export.echo.present?

        command_result, exportable, new_lines = export_echo_with_code(
          bash_script_lines,
          export,
          force: false
        )

      when ':exec', UxActSource::EXEC
        raise unless export.exec.present?

        command_result = output_from_adhoc_bash_script_file(
          join_array_of_arrays(bash_script_lines, export.exec)
        )

      else
        command_result = CommandResult.new(stdout: export.init.to_s)
        # raise "Unknown FCB.init_source(export) #{FCB.init_source(export)}"
      end

      # add message for required variables
      if command_result.exit_status == EXIT_STATUS_REQUIRED_EMPTY
        command_result.warning = warning_required_empty(export)
        warn command_result.warning
      end

      command_result.exportable = exportable
      command_result.transformable = transformable
      command_result.new_lines = new_lines
      command_result
    end

    def warning_required_empty(export)
      "A value must exist for: #{export.required.join(', ')}"
    end

    def vux_await_user_selection(prior_answer: @dml_block_selection)
      @dml_block_state = load_cli_or_user_selected_block(
        all_blocks: @dml_blocks_in_file,
        menu_blocks: @dml_menu_blocks,
        prior_answer: prior_answer
      )
      if !@dml_block_state
        # HashDelegator.error_handler('block_state missing', { abort: true })
        # document has no enabled items
        :break
      elsif @dml_block_state.state == MenuState::EXIT
        :break
      end
    end

    def vux_clear_menu_state
      @dml_block_state = SelectedBlockMenuState.new
      @delegate_object[:block_name] = nil
    end

    def vux_edit_inherited
      edited = edit_text(@dml_link_state.inherited_lines_block)
      @dml_link_state.inherited_lines = edited.split("\n") if edited
    end

    def vux_execute_and_prompt(block_name)
      @dml_block_state = find_block_state_by_name(block_name)
      if @dml_block_state.block &&
         @dml_block_state.block.type == BlockType::OPTS
        debounce_reset
        link_state = LinkState.new
        options_state = read_show_options_and_trigger_reuse(
          link_state: link_state,
          mdoc: @dml_mdoc,
          selected: @dml_block_state.block
        )

        update_menu_base(options_state.options)
        options_state.load_file_link_state.link_state
        return
      end

      return :break if execute_block_in_state(block_name) == :break

      if prompt_user_exit(
        block_name_from_cli: @run_state.source.block_name_from_cli,
        selected: @dml_block_state.block
      )
        return :break
      end

      ## order of block name processing: link block, cli, from
      #  user
      #
      @dml_link_state.block_name,
       @run_state.source.block_name_from_cli, cli_break =
        HashDelegator.next_link_state(
          block_name: @dml_link_state.block_name,
          block_name_from_cli: @dml_now_using_cli,
          block_state: @dml_block_state,
          was_using_cli: @dml_now_using_cli
        )

      !@dml_block_state.source.block_name_from_ui && cli_break && :break
    end

    def vux_execute_block_per_type(block_name, formatted_choice_ostructs)
      case block_name
      when formatted_choice_ostructs[:back].pub_name
        debounce_reset
        vux_navigate_back_for_ls

      when formatted_choice_ostructs[:edit].pub_name
        debounce_reset
        vux_edit_inherited
        return :break if pause_user_exit

        InputSequencer.next_link_state(prior_block_was_link: true)

      when formatted_choice_ostructs[:history].pub_name
        debounce_reset
        return :break unless (files_table_rows = vux_history_files_table_rows)

        execute_history_select(files_table_rows, stream: $stderr)
        return :break if pause_user_exit

        InputSequencer.next_link_state(prior_block_was_link: true)

      when formatted_choice_ostructs[:load].pub_name
        debounce_reset
        vux_load_inherited
        return :break if pause_user_exit

        InputSequencer.next_link_state(prior_block_was_link: true)

      when formatted_choice_ostructs[:save].pub_name
        debounce_reset
        return :break if execute_inherited_save == :break

        InputSequencer.next_link_state(prior_block_was_link: true)

      when formatted_choice_ostructs[:shell].pub_name
        debounce_reset
        vux_input_and_execute_shell_commands(stream: $stderr, shell: shell)
        return :break if pause_user_exit

        InputSequencer.next_link_state(prior_block_was_link: true)

      when formatted_choice_ostructs[:view].pub_name
        debounce_reset
        vux_view_inherited(stream: $stderr)
        return :break if pause_user_exit

        InputSequencer.next_link_state(prior_block_was_link: true)

      else
        return :break if vux_execute_and_prompt(block_name) == :break

        InputSequencer.next_link_state(
          block_name: @dml_link_state.block_name,
          prior_block_was_link: @dml_block_state.block.type != BlockType::SHELL
        )
      end
    end

    def vux_formatted_names_for_state_chrome_blocks(
      names: %w[back edit history load save shell view]
    )
      names.each_with_object({}) do |name, result|
        do_key = :"menu_option_#{name}_name"
        oname = HashDelegator.safeval(@delegate_object[do_key])
        dname = format(@delegate_object[:menu_link_format], oname)
        result[name.to_sym] = OpenStruct.new(
          dname: dname,
          name: dname,
          oname: dname,
          pub_name: dname.pub_name
        )
      end
    end

    def vux_history_files_table_rows
      read_saved_assets_for_history_table(
        asset: @delegate_object[:filename],
        form: @delegate_object[:saved_history_format]
      )
    end

    def vux_init
      @menu_base_options = @delegate_object
      @dml_link_state = LinkState.new(
        block_name: @delegate_object[:block_name],
        document_filename: @delegate_object[:filename]
      )
      @run_state.source.block_name_from_cli =
        @dml_link_state.block_name.present?
      @cli_block_name = @dml_link_state.block_name
      @dml_now_using_cli = @run_state.source.block_name_from_cli
      @dml_block_selection = nil
      @dml_block_state = SelectedBlockMenuState.new
      @doc_saved_lines_files = []

      @run_state.batch_random = Random.new.rand
      @run_state.batch_index = 0

      @run_state.files = StreamsOut.new
    end

    def vux_input_and_execute_shell_commands(stream:, shell:)
      loop do
        command = prompt_for_command(
          AnsiString.new(":MDE #{Time.now.strftime('%FT%TZ')}> ").send(:bgreen)
        )
        break if !command.present? || command == 'exit'

        exit_status = execute_command_with_streams(
          [shell, '-c', command]
        )
        case exit_status
        when 0
          stream.puts "#{AnsiString.new('OK').green} #{exit_status}"
        else
          stream.puts "#{AnsiString.new('ERR').bred} #{exit_status}"
        end
      end
    end

    ## load file with code lines per options
    #
    def vux_load_code_files_into_state
      return unless @menu_base_options[:load_code].present?

      @dml_link_state.inherited_lines =
        @menu_base_options[:load_code].split(':').map do |path|
          File.readlines(path, chomp: true)
        end.flatten(1)

      inherited_block_names = []
      inherited_dependencies = {}
      selected = persist_fcb(oname: 'load_code')

      pop_add_current_code_to_head_and_trigger_load(
        @dml_link_state, inherited_block_names,
        code_lines, inherited_dependencies, selected
      )
    end

    def vux_load_inherited
      return unless (filespec = load_filespec_from_expression(
        document_name_in_glob_as_file_name
      ))

      @dml_link_state.inherited_lines_append(
        File.readlines(filespec, chomp: true)
      )
    end

    # Select and execute a code block from a Markdown document.
    #
    # This method allows the user to interactively select a code block from a
    # Markdown document, obtain approval, and execute the chosen block of code.
    #
    # @return [Nil] Returns nil if no code block is selected
    #  or an error occurs.
    def vux_main_loop(menu_from_yaml: nil)
      @menu_from_yaml = menu_from_yaml
      vux_init
      vux_load_code_files_into_state
      formatted_choice_ostructs = vux_formatted_names_for_state_chrome_blocks

      block_list = [@delegate_object[:block_name]].select(&:present?).compact +
                   @delegate_object[:input_cli_rest]

      @delegate_object[:block_name] = nil

      process_commands(
        arguments: @p_all_arguments,
        named_procs: yield(:command_names, @delegate_object),
        options_parsed: @p_options_parsed,
        rest: @p_rest,
        enable_search: @delegate_object[:default_find_select_open]
      ) do |type, data|
        case type
        when ArgPro::ActSetBlockName
          @delegate_object[:block_name] = data
          @delegate_object[:input_cli_rest] = ''
        when ArgPro::ConvertValue
          # call for side effects, output, or exit
          data[0].call(data[1])
        when ArgPro::ActFileIsMissing
          raise FileMissingError, data, caller
        when ArgPro::ActFind
          find_value(data, execute_chosen_found: true)
        when ArgPro::ActSetFileName
          @delegate_object[:filename] = data
        when ArgPro::ActSetPath
          @delegate_object[:path] = data
        when ArgPro::CallProcess
          yield :call_proc, [@delegate_object, data]
        when ArgPro::ActSetOption
          @delegate_object[data[0]] = data[1]
        else
          raise
        end
      end

      count = 0
      InputSequencer.new(
        @delegate_object[:filename],
        block_list
      ).run do |msg, data|
        count += 1
        case msg
        when :parse_document # once for each menu
          count = 0
          vux_parse_document(source_id: "#{@delegate_object[:filename]}¤VuxMainLoop®PrsDoc")
          vux_menu_append_history_files(
            formatted_choice_ostructs,
            source_id: "#{@delegate_object[:filename]}¤VuxMainLoop®HstFls"
          )
          vux_publish_document_file_name_for_external_automation

        when :display_menu
          # does not display
          vux_clear_menu_state

        when :end_of_cli
          # yield :end_of_cli, @delegate_object

          if @delegate_object[:list_blocks]
            list_blocks(source_id: "#{@delegate_object[:filename]}¤VuxMainLoop®EndCLI")
            :exit
          end

        when :user_choice
          vux_user_selected_block_name

        when :execute_block
          ret = vux_execute_block_per_type(data, formatted_choice_ostructs)
          vux_publish_block_name_for_external_automation(data)
          ret

        when :close_ux
          if @vux_pipe_open.present? && File.exist?(@vux_pipe_open)
            @vux_pipe_open.close
            @vux_pipe_open = nil
          end
          if @vux_pipe_created.present? && File.exist?(@vux_pipe_created)
            File.delete(@vux_pipe_created)
            @vux_pipe_created = nil
          end

        when :exit?
          data == $texit

        when :stay?
          data == $stay

        else
          raise "Invalid message: #{msg}"

        end
      end
    end

    def vux_menu_append_history_files(
      formatted_choice_ostructs, source_id: ''
    )
      if @delegate_object[:menu_for_history]
        history_files(
          filename: saved_asset_filename(@delegate_object[:filename],
                                         @dml_link_state),
          path: @delegate_object[:saved_script_folder]
        ).tap do |files|
          if files.count.positive?
            dml_menu_append_chrome_item(
              formatted_choice_ostructs[:history].oname, files.count,
              'files',
              menu_state: MenuState::HISTORY,
              source_id: source_id
            )
          end
        end
      end

      return unless @delegate_object[:menu_for_saved_lines] &&
                    @delegate_object[:document_saved_lines_glob].present?

      document_glob = document_name_in_glob_as_file_name
      files = document_glob ? Dir.glob(document_glob) : []
      @doc_saved_lines_files = files.count.positive? ? files : []

      lines_count = @dml_link_state.inherited_lines_count

      # add menu items (glob, load, save) and enable selectively
      if files.count.positive? || lines_count.positive?
        menu_add_disabled_option(document_glob)
      end
      if files.count.positive?
        dml_menu_append_chrome_item(
          formatted_choice_ostructs[:load].dname, files.count, 'files',
          menu_state: MenuState::LOAD,
          source_id: "#{source_id}_vmahf_load"
        )
      end
      if @delegate_object[:menu_inherited_lines_edit_always] ||
         lines_count.positive?
        dml_menu_append_chrome_item(
          formatted_choice_ostructs[:edit].dname, lines_count, 'lines',
          menu_state: MenuState::EDIT,
          source_id: "#{source_id}_vmahf_edit"
        )
      end
      if lines_count.positive?
        dml_menu_append_chrome_item(
          formatted_choice_ostructs[:save].dname, 1, '',
          menu_state: MenuState::SAVE,
          source_id: "#{source_id}_vmahf_save"
        )
      end
      if lines_count.positive?
        dml_menu_append_chrome_item(
          formatted_choice_ostructs[:view].dname, 1, '',
          menu_state: MenuState::VIEW,
          source_id: "#{source_id}_vmahf_view"
        )
      end
      # rubocop:disable Style/GuardClause
      if @delegate_object[:menu_with_shell]
        dml_menu_append_chrome_item(
          formatted_choice_ostructs[:shell].dname, 1, '',
          menu_state: MenuState::SHELL,
          source_id: "#{source_id}_vmahf_shell"
        )
      end
      # rubocop:enable Style/GuardClause

      # # reflect new menu items
      # @dml_mdoc = MDoc.new(@dml_menu_blocks)
    end

    def vux_navigate_back_for_ls
      InputSequencer.merge_link_state(
        @dml_link_state,
        InputSequencer.next_link_state(
          **execute_navigate_back.merge(prior_block_was_link: true)
        )
      )
    end

    def vux_parse_document(source_id: '')
      @run_state.batch_index += 1
      @run_state.in_own_window = false

      @run_state.source.block_name_from_cli, @dml_now_using_cli =
        manage_cli_selection_state(
          block_name_from_cli: @run_state.source.block_name_from_cli,
          now_using_cli: @dml_now_using_cli,
          link_state: @dml_link_state
        )

      @delegate_object[:filename] = @dml_link_state.document_filename
      @dml_link_state.block_name = @delegate_object[:block_name] =
        if @run_state.source.block_name_from_cli
          @cli_block_name
        else
          @dml_link_state.block_name
        end

      # update @delegate_object and @menu_base_options in auto_load
      #
      @dml_blocks_in_file, @dml_menu_blocks, @dml_mdoc =
        mdoc_menu_and_blocks_from_nested_files(
          @dml_link_state, source_id: source_id
        )
      dump_delobj(@dml_blocks_in_file, @dml_menu_blocks, @dml_link_state)
    end

    def vux_publish_block_name_for_external_automation(block_name)
      publish_for_external_automation(
        message: format(
          @delegate_object[:publish_block_name_format],
          { block: block_name,
            document: @delegate_object[:filename],
            time: Time.now.utc.strftime(
              @delegate_object[:publish_time_format]
            ) }
        )
      )
    end

    def vux_publish_document_file_name_for_external_automation
      return unless @delegate_object[:publish_document_file_name].present?

      publish_for_external_automation(
        message: format(
          @delegate_object[:publish_document_name_format],
          { document: @delegate_object[:filename],
            time: Time.now.utc.strftime(
              @delegate_object[:publish_time_format]
            ) }
        )
      )
    end

    # return :break to break from loop
    def vux_user_selected_block_name
      if @dml_link_state.block_name.present?
        # @prior_block_was_link = true
        @dml_block_state.block = find_block_by_name(
          @dml_blocks_in_file,
          @dml_link_state.block_name
        )
        @dml_link_state.block_name = nil
      else
        # puts "? - Select a block to execute (or type #{$texit}
        #  to exit):"
        return :break if vux_await_user_selection(
          prior_answer: @dml_block_selection
        ) == :break
        return :break if @dml_block_state.block.nil? # no block matched
      end
      # puts "! - Executing block: #{data}"
      @dml_block_state.block&.pub_name
    end

    def vux_view_inherited(stream:)
      stream.puts @dml_link_state.inherited_lines_block
    end

    def wait_for_stream_processing
      @process_mutex.synchronize do
        @process_cv.wait(@process_mutex)
      end
    rescue Interrupt
      # user interrupts process
    end

    def wait_for_user_selected_block(all_blocks, menu_blocks, prior_answer)
      block_state = wait_for_user_selection(all_blocks, menu_blocks,
                                            prior_answer)
      handle_back_or_continue(block_state)
      block_state
    end

    def wait_for_user_selection(_all_blocks, menu_blocks, prior_answer)
      if @delegate_object[:clear_screen_for_select_block]
        printf("\e[1;1H\e[2J")
      end

      prompt_title = string_send_color(
        @delegate_object[:prompt_select_block].to_s,
        :prompt_color_after_script_execution
      )

      tty_menu_items = blocks_as_menu_items(menu_blocks)
      if tty_menu_items.empty?
        return SelectedBlockMenuState.new(nil, OpenStruct.new,
                                          MenuState::EXIT)
      end

      selected_answer = case prior_answer
                        when nil
                          nil
                        when String
                          menu_blocks.find do |block|
                            block.dname.include?(prior_answer)
                          end&.name
                        when Struct, MarkdownExec::FCB
                          if prior_answer.id
                            # when switching documents, the prior answer will not be found
                            (menu_blocks.find_index do |block|
                              block[:id] == prior_answer.id
                            end || 0) + 1
                          else
                            prior_answer.index || prior_answer.name
                          end
                        end

      # prior_answer value may not match if color is different from
      # originating menu (opts changed while processing)
      selection_opts = if selected_answer
                         @delegate_object.merge(default: selected_answer)
                       else
                         @delegate_object
                       end

      selection_opts.merge!(
        { cycle: @delegate_object[:select_page_cycle],
          per_page: @delegate_object[:select_page_height] }
      )
      selected_option = select_option_with_metadata(
        prompt_title, tty_menu_items, selection_opts
      )
      determine_block_state(selected_option)
    end

    # Handles the core logic for generating the command
    # file's metadata and content.
    def write_command_file(required_lines:, blockname:, shell: nil)
      return unless @delegate_object[:save_executed_script]

      time_now = Time.now.utc
      @run_state.saved_script_filename =
        SavedAsset.new(
          blockname: blockname,
          exts: '.sh',
          filename: @delegate_object[:filename],
          prefix: @delegate_object[:saved_script_filename_prefix],
          saved_asset_format:
            shell_escape_asset_format(
              code_lines: @dml_link_state.inherited_lines,
              shell: shell
            ),
          time: time_now
        ).generate_name
      @run_state.saved_filespec =
        File.join(@delegate_object[:saved_script_folder],
                  @run_state.saved_script_filename)

      shebang = if @delegate_object[:shebang]&.present?
                  "#{@delegate_object[:shebang]} #{shell}\n"
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
    def write_file_with_directory_creation(content:, filespec:)
      directory = File.dirname(filespec)

      begin
        FileUtils.mkdir_p(directory)
        File.write(filespec, content)
      rescue Errno::EACCES
        warn "Permission denied: Unable to write to file '#{filespec}'"
        nil
      rescue Errno::EROFS
        warn 'Read-only file system: Unable to write to file ' \
             "'#{filespec}'"
        nil
      rescue StandardError => err
        warn 'An error occurred while writing to file ' \
             "'#{filespec}': #{err.message}"
        nil
      end
    end

    # return next document file name
    def write_inherited_lines_to_file(link_state, link_block_data)
      save_expr = link_block_data.fetch(LinkKeys::SAVE, '')
      if save_expr.present?
        save_filespec = save_filespec_from_expression(save_expr)
        if save_filespec.present?
          File.write(save_filespec,
                     HashDelegator.join_code_lines(link_state&.inherited_lines))
          @delegate_object[:filename]
        else
          link_block_data[LinkKeys::FILE] || @delegate_object[:filename]
        end
      else
        link_block_data[LinkKeys::FILE] || @delegate_object[:filename]
      end
    end
  end

  class HashDelegator < HashDelegatorParent
    include ::ErrorReporting

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

    # Recursively cleans the given hash or struct from unwanted values.
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

    def self.options_for_tty_menu(options)
      options.slice(:menu_active_color_pastel_messages, :select_page_height)
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
      @hd.next_link_state(
        block_name_from_cli: nil, was_using_cli: nil,
        block_state: nil, block_name: nil
      )
    end
  end

  class TestHashDelegator < Minitest::Test
    def setup
      @hd = HashDelegator.new
      @mdoc = mock('MarkdownDocument')
    end

    def test_execute_required_lines_with_argument_args_value
      # calling execute required lines
      # calls command execute with argument args value
      pigeon = 'E'
      obj = {
        output_execution_label_format: '',
        output_execution_label_name_color: 'plain',
        output_execution_label_value_color: 'plain'
      }

      c = MarkdownExec::HashDelegator.new(obj)
      c.pass_args = pigeon

      # Expect that method opts_command_execute is
      # called with argument args having value pigeon
      c.expects(:command_execute).with(
        '',
        args: pigeon,
        erls: {},
        shell: ShellType::BASH
      )

      # Call method opts_execute_required_lines
      c.execute_required_lines(shell: ShellType::BASH)
    end

    # Test case for empty body
    def test_execute_block_type_link_with_state_with_empty_body
      assert_equal LoadFile::REUSE,
                   @hd.execute_block_type_link_with_state.load_file
    end

    # Test case for non-empty body without 'file' key
    def test_execute_block_type_link_with_state_without_file_key
      body = ["vars:\n  KEY: VALUE"]
      assert_equal LoadFile::REUSE,
                   @hd.execute_block_type_link_with_state(
                     link_block_body: body
                   ).load_file
    end

    # Test case for non-empty body with 'file' key
    def test_execute_block_type_link_with_state_with_file_key
      body = ["file: sample_file\nblock: sample_block\nvars:\n  KEY: VALUE"]
      expected_result = LoadFileLinkState.new(
        LoadFile::LOAD,
        LinkState.new(block_name: 'sample_block',
                      document_filename: 'sample_file',
                      inherited_dependencies: {},
                      inherited_lines: ['# ', 'KEY="VALUE"'])
      )
      assert_equal expected_result,
                   @hd.execute_block_type_link_with_state(
                     link_block_body: body,
                     selected: FCB.new(block_name: 'sample_block',
                                       filename: 'sample_file')
                   )
    end

    def test_indent_all_lines_with_indent
      body = "Line 1\nLine 2"
      indent = '  ' # Two spaces
      expected_result = "  Line 1\n  Line 2"
      assert_equal expected_result,
                   HashDelegator.indent_all_lines(body, indent)
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
      # sample input and output data for
      # testing default_block_title_from_body method
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
          output: "def add(x, y)\n    x + y\n  end"
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
        title = HashDelegator.default_block_title_from_body(input)
        assert_equal output, title
      end
    end
  end

  class TestHashDelegatorAppendDivider < Minitest::Test
    def setup
      @hd = HashDelegator.new(
        menu_divider_color: :color,
        menu_divider_format: 'Format',
        menu_final_divider: 'Final Divider',
        menu_initial_divider: 'Initial Divider'
      )
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
      @hd = HashDelegator.new
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
      result = HashDelegator.block_find(blocks, :text, 'missing_value',
                                        'default')
      assert_equal 'default', result
    end
  end

  class TestHashDelegatorBlocksFromNestedFiles < Minitest::Test
    def setup
      @hd = HashDelegator.new
      @hd.stubs(:iter_blocks_from_nested_files).yields(:blocks, FCB.new)
      @hd.stubs(:create_and_add_chrome_blocks)
      HashDelegator.stubs(:error_handler)
    end

    def test_blocks_from_nested_files
      result = @hd.blocks_from_nested_files.blocks
      assert_kind_of Array, result
      assert_kind_of FCB, result.first
    end

    def test_blocks_from_nested_files_with_no_chrome
      @hd = HashDelegator.new(no_chrome: true)
      @hd.expects(:create_and_add_chrome_blocks).never

      result = @hd.blocks_from_nested_files.blocks

      assert_kind_of Array, result
    end
  end

  class TestHashDelegatorCollectRequiredCodeLines < Minitest::Test
    def setup
      @hd = HashDelegator.new
      @mdoc = mock('YourMDocClass')
      @selected = FCB.new(
        body: ['key: value'],
        type: BlockType::VARS
      )
      HashDelegator.stubs(:read_required_blocks_from_temp_file).returns([])
      @hd.stubs(:string_send_color)
      @hd.stubs(:print)
    end

    def test_execute_block_type_port_code_lines_with_vars
      YAML.stubs(:load).returns({ 'key' => 'value' })
      @mdoc.stubs(:collect_recursively_required_code)
           .returns({ code: ['code line'] })
      result = @hd.execute_block_type_port_code_lines(
        mdoc: @mdoc, selected: @selected, block_source: {}
      )

      assert_equal ['code line', 'key=value'], result
    end
  end

  class TestHashDelegatorCommandOrUserSelectedBlock < Minitest::Test
    def setup
      @hd = HashDelegator.new
      HashDelegator.stubs(:error_handler)
      @hd.stubs(:wait_for_user_selected_block)
    end

    def test_command_selected_block
      all_blocks = [{ oname: 'block1' }, { oname: 'block2' }]
      @hd = HashDelegator.new(block_name: 'block1')

      result = @hd.load_cli_or_user_selected_block(all_blocks: all_blocks)

      assert_equal all_blocks.first,
                   result.block
      assert_equal OpenStruct.new(block_name_from_ui: false),
                   result.source
      assert_nil result.state
    end

    def test_user_selected_block
      block_state = SelectedBlockMenuState.new(
        { oname: 'block2' }, OpenStruct.new, :some_state
      )
      @hd.stubs(:wait_for_user_selected_block).returns(block_state)

      result = @hd.load_cli_or_user_selected_block

      assert_equal block_state.block,
                   result.block
      assert_equal OpenStruct.new(block_name_from_ui: true),
                   result.source
      assert_equal :some_state, result.state
    end
  end

  class TestHashDelegatorCountBlockInFilename < Minitest::Test
    def setup
      @hd = HashDelegator.new(
        fenced_start_and_end_regex: '^```',
        filename: '/path/to/file'
      )
      @hd.stubs(:cfile).returns(mock('cfile'))
    end

    def test_count_blocks_in_filename
      file_content = ["```ruby\n", "puts 'Hello'\n", "```\n",
                      "```python\n", "print('Hello')\n", "```\n"]
      @hd.cfile.stubs(:readlines)
         .with('/path/to/file', import_paths: nil).returns(file_content)

      count = @hd.count_blocks_in_filename

      assert_equal 2, count
    end

    def test_count_blocks_in_filename_with_no_matches
      file_content = ["puts 'Hello'\n", "print('Hello')\n"]
      @hd.cfile.stubs(:readlines)
         .with('/path/to/file', import_paths: nil).returns(file_content)

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

      HashDelegator.create_file_and_write_string_with_permissions(
        file_path, content, chmod_value
      )

      assert true # Placeholder for actual test assertions
    end

    def test_create_and_write_file_without_chmod
      file_path = '/path/to/file'
      content = 'sample content'
      chmod_value = 0

      FileUtils.expects(:mkdir_p).with('/path/to').once
      File.expects(:write).with(file_path, content).once
      File.expects(:chmod).never

      HashDelegator.create_file_and_write_string_with_permissions(
        file_path, content, chmod_value
      )

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
      @hd.stubs(:menu_chrome_formatted_option)
         .with(:menu_option_exit_name).returns('Formatted Option')

      result = @hd.determine_block_state(selected_option)

      assert_equal MenuState::EXIT, result.state
      assert_nil result.block
    end

    def test_determine_block_state_back
      selected_option = FCB.new(oname: 'Formatted Back Option')
      @hd.stubs(:menu_chrome_formatted_option)
         .with(:menu_option_back_name).returns('Formatted Back Option')
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
      @hd.stubs(:string_send_color)
    end

    def test_display_required_code
      required_lines = %w[line1 line2]
      @hd.instance_variable_get(:@delegate_object)
         .stubs(:[]).with(:script_preview_head).returns('Header')
      @hd.instance_variable_get(:@delegate_object)
         .stubs(:[]).with(:script_preview_tail).returns('Footer')
      @hd.instance_variable_get(:@fout).expects(:fout).times(4)

      @hd.display_required_code(required_lines: required_lines)

      # Verifying that fout is called for each line and for header & footer
      assert true # Placeholder for actual test assertions
    end
  end

  class TestHashDelegatorFetchColor < Minitest::Test
    def setup
      @hd = HashDelegator.new
    end

    def test_fetch_color_with_valid_data
      @hd.instance_variable_get(:@delegate_object).stubs(:fetch).with(
        :execution_report_preview_head, ''
      ).returns('Data String')
      @hd.stubs(:string_send_color)
         .with('Data String', :execution_report_preview_frame_color)
         .returns('Colored Data String')

      result = @hd.fetch_color

      assert_equal 'Colored Data String', result
    end

    def test_fetch_color_with_missing_data
      @hd.instance_variable_get(:@delegate_object).stubs(:fetch).with(
        :execution_report_preview_head, ''
      ).returns('')
      @hd.stubs(:string_send_color)
         .with('', :execution_report_preview_frame_color)
         .returns('Default Colored String')

      result = @hd.fetch_color

      assert_equal 'Default Colored String', result
    end
  end

  class TestHashDelegatorFormatReferencesSendColor < Minitest::Test
    def setup
      @hd = HashDelegator.new
    end

    def test_format_references_send_color_with_valid_data
      @hd.instance_variable_get(:@delegate_object).stubs(:fetch).with(
        :output_execution_label_format, ''
      ).returns('Formatted: %{key}')
      @hd.stubs(:string_send_color).returns('Colored String')

      result = @hd.format_references_send_color(
        context: { key: 'value' },
        color_sym: :execution_report_preview_frame_color
      )

      assert_equal 'Colored String', result
    end

    def test_format_references_send_color_with_missing_format
      @hd.instance_variable_get(:@delegate_object).stubs(:fetch).with(
        :output_execution_label_format, ''
      ).returns('')
      @hd.stubs(:string_send_color).returns('Default Colored String')

      result = @hd.format_references_send_color(
        context: { key: 'value' },
        color_sym: :execution_report_preview_frame_color
      )

      assert_equal 'Default Colored String', result
    end
  end

  class TestHashDelegatorFormatExecutionStreams < Minitest::Test
    def setup
      @hd = HashDelegator.new
      @hd.instance_variable_set(:@run_state, mock('run_state'))
    end

    # def test_format_execution_stream_with_valid_key
    #   result = HashDelegator.format_execution_stream(
    #     { stdout: %w[output1 output2] },
    #     ExecutionStreams::STD_OUT
    #   )

    #   assert_equal "output1\noutput2", result
    # end

    # def test_format_execution_stream_with_empty_key
    #   @hd.instance_variable_get(:@run_state).stubs(:files).returns({})

    #   result = HashDelegator.format_execution_stream(
    #              nil, ExecutionStreams::STD_ERR)

    #   assert_equal '', result
    # end

    # def test_format_execution_stream_with_nil_files
    #   @hd.instance_variable_get(:@run_state).stubs(:files).returns(nil)

    #   result = HashDelegator.format_execution_stream(nil, :stdin)

    #   assert_equal '', result
    # end
  end

  class TestHashDelegatorHandleBackLink < Minitest::Test
    def setup
      @hd = HashDelegator.new
      @hd.stubs(:history_state_pop)
    end

    def test_pop_link_history_new_state
      # Verifying that history_state_pop is called
      # @hd.expects(:history_state_pop).once

      result = @hd.pop_link_history_new_state

      # Asserting the result is an instance of LinkState
      assert_nil result.block_name
    end
  end

  class TestHashDelegatorBlockType < Minitest::Test
    def setup
      @hd = HashDelegator.new
    end

    # def execute_block_type_history_ux(
    #   directory: @delegate_object[:document_configurations_directory],
    #   filename: '*',
    #   form: '%{line}',
    #   link_state:,
    #   regexp: "^(?<line>.*)$",
    #   selected:
    # )

    # def read_saved_assets_for_history_table(
    #   asset: nil,
    #   filename: nil,
    #   form: @delegate_object[:saved_history_format],
    #   path: @delegate_object[:saved_script_folder],
    #   regexp: @delegate_object[:saved_asset_match]
    # )

    # def history_files(
    #   direction: :reverse,
    #   filename: nil,
    #   home: Dir.pwd,
    #   order: :chronological,
    #   path: ''
    # )

    def test_call
      @hd.expects(:history_files).with(filename: '*', path: nil).once
      @hd.execute_block_type_history_ux(
        filename: '*', link_state: LinkState.new, selected: FCB.new(body: [])
      )
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

  # class TestHashDelegatorHandleGenericBlock < Minitest::Test
  #   def setup
  #     @hd = HashDelegator.new
  #     @mock_document = mock('MarkdownDocument')
  #     @selected_item = mock('FCB')
  #   end

  #   def test_compile_execute_and_trigger_reuse_without_user_approval
  #     # Mock the delegate object configuration
  #     @hd.instance_variable_set(:@delegate_object,
  #                               { output_script: false,
  #                                 user_must_approve: false })

  #     # Test the method without user approval
  #     # Expectations and assertions go here
  #   end

  #   def test_compile_execute_and_trigger_reuse_with_user_approval
  #     # Mock the delegate object configuration
  #     @hd.instance_variable_set(:@delegate_object,
  #                               { output_script: false,
  #                                 user_must_approve: true })

  #     # Test the method with user approval
  #     # Expectations and assertions go here
  #   end

  #   def test_compile_execute_and_trigger_reuse_with_output_script
  #     # Mock the delegate object configuration
  #     @hd.instance_variable_set(:@delegate_object,
  #                               { output_script: true,
  #                                 user_must_approve: false })

  #     # Test the method with output script option
  #     # Expectations and assertions go here
  #   end
  # end

  # require 'stringio'

  class TestHashDelegatorHandleStream < Minitest::Test
    def setup
      @hd = HashDelegator.new(output_stdout: true)
      @hd.instance_variable_set(:@run_state,
                                OpenStruct.new(files: StreamsOut.new))
    end

    def test_handle_stream
      stream = StringIO.new("line 1\nline 2\n")
      file_type = ExecutionStreams::STD_OUT

      Thread.new { @hd.handle_stream(stream: stream, file_type: file_type) }

      @hd.wait_for_stream_processing
      assert_equal ["line 1\n", "line 2\n"],
                   @hd.instance_variable_get(:@run_state)
                      .files.stream_lines(ExecutionStreams::STD_OUT)
    end

    def test_handle_stream_with_io_error
      stream = StringIO.new("line 1\nline 2\n")
      file_type = ExecutionStreams::STD_OUT
      stream.stubs(:each_line).raises(IOError)

      Thread.new { @hd.handle_stream(stream: stream, file_type: file_type) }

      @hd.wait_for_stream_processing

      assert_equal [],
                   @hd.instance_variable_get(:@run_state)
                      .files.stream_lines(ExecutionStreams::STD_OUT)
    end
  end

  class TestHashDelegatorIterBlocksFromNestedFiles < Minitest::Test
    def setup
      @hd = HashDelegator.new(filename: 'test.md')
      @hd.stubs(:check_file_existence).with('test.md').returns(true)
      @hd.stubs(:initial_state).returns({})
      @hd.stubs(:cfile).returns(Minitest::Mock.new)
      @hd.stubs(:update_line_and_block_state)
    end

    def test_iter_blocks_from_nested_files
      @hd.cfile.expect(:readlines, ['line 1', 'line 2'], ['test.md'],
                       import_paths: '')
      selected_types = ['filtered message']

      result = @hd.iter_blocks_from_nested_files { selected_types }
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
      @hd = HashDelegator.new(
        menu_chrome_color: :red,
        menu_chrome_format: '-- %s --',
        menu_option_back_name: 'Back'
      )
      @hd.stubs(:menu_chrome_formatted_option)
         .with(:menu_option_back_name).returns('-- Back --')
      @hd.stubs(:string_send_color)
         .with('-- Back --', :menu_chrome_color)
         .returns(AnsiString.new('-- Back --').red)
    end

    def test_menu_chrome_colored_option_with_color
      assert_equal AnsiString.new('-- Back --').red,
                   @hd.menu_chrome_colored_option(:menu_option_back_name)
    end

    def test_menu_chrome_colored_option_without_color
      @hd = HashDelegator.new(menu_option_back_name: 'Back')
      @hd.stubs(:menu_chrome_formatted_option)
         .with(:menu_option_back_name).returns('-- Back --')
      assert_equal '-- Back --',
                   @hd.menu_chrome_colored_option(:menu_option_back_name)
    end
  end

  class TestHashDelegatorMenuChromeOption < Minitest::Test
    def setup
      @hd = HashDelegator.new(
        menu_chrome_format: '-- %s --',
        menu_option_back_name: "'Back'"
      )
      HashDelegator.stubs(:safeval).with("'Back'").returns('Back')
    end

    def test_menu_chrome_formatted_option_with_format
      assert_equal '-- Back --',
                   @hd.menu_chrome_formatted_option(:menu_option_back_name)
    end

    def test_menu_chrome_formatted_option_without_format
      @hd = HashDelegator.new(menu_option_back_name: "'Back'")
      assert_equal 'Back',
                   @hd.menu_chrome_formatted_option(:menu_option_back_name)
    end
  end

  class TestHashDelegatorStartFencedBlock < Minitest::Test
    def setup
      @hd = HashDelegator.new(
        {
          block_calls_scan: 'CALLS_REGEX',
          block_name_wrapper_match: 'WRAPPER_REGEX'
        }
      )
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
      @hd = HashDelegator.new(red: 'red', green: 'green')
    end

    def test_string_send_color
      assert_equal AnsiString.new('Hello').red,
                   @hd.string_send_color('Hello', :red)
      assert_equal AnsiString.new('World').green,
                   @hd.string_send_color('World', :green)
      assert_equal AnsiString.new('Default').plain,
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
  # end

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
      mock_block_state = Struct.new(:state, :block)
                               .new(MenuState::BACK, { oname: 'back_block' })
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
      def $stdin.gets; raise Interrupt; end
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
