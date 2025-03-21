#!/usr/bin/env -S bundle exec ruby
# frozen_string_literal: true

# encoding=utf-8

require 'find'
require_relative 'constants'

def format_and_highlight_hash(
  data,
  highlight_color_sym: :exception_color_detail,
  plain_color_sym: :menu_chrome_color,
  label: 'Data:',
  highlight: [],
  line_prefix: '  ',
  line_postfix: '',
  key_has_value: ': '
)
  formatted_deps = data&.map do |key, value|
    color_sym = highlight.include?(key) ? highlight_color_sym : plain_color_sym
    dkey = string_send_color(key, color_sym)

    "#{line_prefix}#{dkey}#{key_has_value}" \
     "#{string_send_color(value,
                          highlight.include?(value) ? highlight_color_sym : plain_color_sym)}: " \
     "#{formatted_sub_items}#{line_postfix}"
  end

  "#{line_prefix}#{string_send_color(label,
                                     highlight_color_sym)}#{line_postfix}\n" + formatted_deps.join("\n")
end

# Formats and highlights a list of dependencies. Dependencies are presented with indentation,
# and specific items can be highlighted in a specified color, while others are shown in a plain color.
#
# @param dependencies [Hash] A hash of dependencies, where each key is a dependency name,
#        and its value is an array of sub-items.
# @param highlight_color_sym [Symbol] The color method to apply to highlighted items.
#        Default is :exception_color_detail.
# @param plain_color_sym [Symbol] The color method for non-highlighted items.
#        Default is :menu_chrome_color.
# @param label [String] The label to prefix the list of dependencies with.
#        Default is 'Dependencies:'.
# @param highlight [Array] An array of items to highlight. Each item in this array will be
#        formatted with the specified highlight color.
# @param line_prefix [String] Prefix for each line. Default is '  '.
# @param line_postfix [String] Postfix for each line. Default is ''.
# @param detail_sep [String] Separator for items in the sub-list. Default is '  '.
# @return [String] A formatted string representation of the dependencies with highlighted items.
def format_and_highlight_dependencies(
  dependencies,
  highlight_color_sym: :exception_color_detail,
  plain_color_sym: :menu_chrome_color,
  label: 'Dependencies:',
  highlight: [],
  line_prefix: '  ',
  line_postfix: '',
  detail_sep: '  '
)
  formatted_deps = dependencies&.map do |dep_name, sub_items|
    formatted_sub_items = sub_items.map do |item|
      color_sym = highlight.include?(item) ? highlight_color_sym : plain_color_sym
      string_send_color(item, color_sym)
    end.join(detail_sep)

    "#{line_prefix}- #{string_send_color(dep_name,
                                         highlight.include?(dep_name) ? highlight_color_sym : plain_color_sym)}: #{formatted_sub_items}#{line_postfix}"
  end || []

  "#{line_prefix}#{string_send_color(label,
                                     highlight_color_sym)}#{line_postfix}\n" + formatted_deps.join("\n")
end
# warn menu_blocks.to_yaml.sub(/^(?:---\n)?/, "MenuBlocks:\n")

def format_and_highlight_lines(
  lines,
  highlight_color_sym: :exception_color_detail,
  plain_color_sym: :menu_chrome_color,
  label: 'Dependencies:',
  highlight: [],
  line_prefix: '  ',
  line_postfix: ''
)
  formatted_deps = lines&.map do |item|
    "#{line_prefix}- #{string_send_color(dep_name,
                                         highlight.include?(dep_name) ? highlight_color_sym : plain_color_sym)}: #{item}#{line_postfix}"
  end || []

  "#{line_prefix}#{string_send_color(label,
                                     highlight_color_sym)}#{line_postfix}\n" + formatted_deps.join("\n")
end

# Class DirectorySearcher
# This class provides methods to search for a specified pattern
# in directory names, file names, and contents of files within given paths.
class DirectorySearcher
  attr_reader :pattern, :paths, :include_subdirectories, :filename_glob

  # Constructor
  # @param pattern [Regexp] The regular expression pattern to search for.
  # @param paths [Array<String>] List of directories to search in.
  # @param include_subdirectories [Boolean] Whether to search in subdirectories.
  # @param filename_glob [String, nil] Glob pattern for file names.
  def initialize(pattern, paths, include_subdirectories: true, filename_glob: '*.[Mm][Dd]') #'*.md'
    @pattern = Regexp.new(pattern, Regexp::IGNORECASE)
    @paths = paths
    @include_subdirectories = include_subdirectories
    @filename_glob = filename_glob
  end

  # Searches for the pattern in directory names.
  # @return [Array<String>] List of matching directory names.
  def find_directory_names
    match_dirs = []
    @paths.each do |path|
      Find.find(path) do |p|
        # Find.prune unless @include_subdirectories || path == p
        match_dirs << p if File.directory?(p) && p.match?(@pattern)
      end
    end
    match_dirs
  end

  # Searches for the pattern in file names.
  # @return [Array<String>] List of matching file names.
  def find_file_names
    match_files = []
    @paths.each do |path|
      Find.find(path) do |p|
        # Find.prune unless @include_subdirectories || path == p
        next unless File.file?(p)

        file_name = File.basename(p)
        next if @filename_glob && !File.fnmatch(@filename_glob, file_name)

        begin
          match_files << p if file_name.encode('UTF-8', invalid: :replace, undef: :replace,
                                                        replace: '').match?(@pattern)
        rescue EncodingError
          # Optionally log the file with encoding issues
          # puts "Encoding error in file: #{p}"
        end
      end
    end
    match_files
  end

  # Searches for the pattern in the contents of the files and returns matches along with their file paths and line numbers.
  # @return [Hash] A hash where each key is a file path and each value is an array of hashes with :line_number and :line keys.
  def find_file_contents
    match_details = {}

    @paths.each do |path|
      Find.find(path) do |p|
        Find.prune unless @include_subdirectories || path == p
        next unless File.file?(p)

        next if @filename_glob && !File.fnmatch(@filename_glob,
                                                File.basename(p))

        begin
          File.foreach(p).with_index(1) do |line, line_num| # Index starts from 1 for line numbers
            line_utf8 = line.encode('UTF-8', invalid: :replace,
                                             undef: :replace, replace: '')

            line_utf8 = yield(line_utf8) if block_given?

            if line_utf8&.match?(@pattern)
              match_details[p] ||= []
              match_details[p] << IndexedLine.new(line_num, line_utf8.chomp)
            end
          end
        rescue EncodingError
          # Optionally log the file with encoding issues
          # puts "Encoding error in file: #{p}"
        end
      end
    end

    match_details
  end

  # # Searches for the pattern in the contents of the files.
  # # @return [Array<String>] List of matching lines from files.
  # def find_file_contents
  #   match_lines = []
  #   @paths.each do |path|
  #     Find.find(path) do |p|
  #       Find.prune unless @include_subdirectories || path == p
  #       next unless File.file?(p)

  #       next if @filename_glob && !File.fnmatch(@filename_glob, File.basename(p))

  #       begin
  #         File.foreach(p).with_index do |line, _line_num|
  #           line_utf8 = line.encode('UTF-8', invalid: :replace, undef: :replace, replace: '')
  #           match_lines << line_utf8.chomp if line_utf8.match?(@pattern)
  #         end
  #       rescue EncodingError
  #         # Optionally log the file with encoding issues
  #         # puts "Encoding error in file: #{p}"
  #       end
  #     end
  #   end
  #   match_lines
  # end
end

if $PROGRAM_NAME == __FILE__
  require 'bundler/setup'
  Bundler.require(:default)

  require 'minitest/autorun'
  # require 'mocha/minitest'
  # require_relative 'directory_searcher'

  # Test class for DirectorySearcher
  class DirectorySearcherTest < Minitest::Test
    # Setup method to initialize common test data
    def setup
      @pattern = /test_pattern/
      @paths = ['./spec']
      @searcher = DirectorySearcher.new(@pattern, @paths)
    end

    # Test find_directory_names method
    def test_find_directory_names
      # Add assertions based on your test directory structure and expected results
      assert_equal [], @searcher.find_directory_names
    end

    # Test find_file_names method
    def test_find_file_names
      # Add assertions based on your test directory structure and expected results
      assert_equal [], @searcher.find_file_names
    end

    # Test find_file_contents method
    def test_find_file_contents
      # Add assertions based on your test directory structure and expected results
      assert_equal ({}), @searcher.find_file_contents
    end
  end

  # Test class for DirectorySearcher
  class DirectorySearcherTest2 < Minitest::Test
    # Setup method to initialize common test data
    def setup
      @pattern_spec = /spec/
      @paths = ['./spec']
      @filename_glob = nil
      @searcher_spec = DirectorySearcher.new(@pattern_spec, @paths,
                                             filename_glob: @filename_glob)
    end

    # Test find_directory_names method for 'spec'
    def test_find_directory_names_for_spec
      # Replace with actual expected directory names containing 'spec'
      expected_dirs = ['./spec']
      assert_equal expected_dirs, @searcher_spec.find_directory_names
    end

    # Test find_file_names method for 'spec'
    def test_find_file_names_for_spec
      # Replace with actual expected file names containing 'spec'
      expected_files = ['./spec/cli_spec.rb', './spec/env_spec.rb',
                        './spec/markdown_exec_spec.rb', './spec/tap_spec.rb']
      assert_equal expected_files, @searcher_spec.find_file_names
    end

    # # Test find_file_contents method for 'spec'
    # def test_find_file_contents_for_spec
    #   # Replace with actual expected lines containing 'spec'
    #   expected_lines = {['Line with spec 1', 'Line with spec 2']}
    #   assert_equal expected_lines, @searcher_spec.find_file_contents
    # end
  end

end
