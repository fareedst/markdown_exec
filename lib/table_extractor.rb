# frozen_string_literal: true

# Extracts Markdown-style tables from text lines and returns metadata about each table
#
# This class analyzes an array of text lines to identify tables formatted in Markdown style.
# It supports both multi-line tables (using | delimiters) and single-line tables (using ! delimiters).
# For each table found, it returns metadata including row count, column count, and position.
#
# @example
#   lines = [
#     '| Name | Age | City',
#     '|------|-----|-----',
#     '| John | 30  | NYC'
#   ]
#   tables = TableExtractor.extract_tables(lines, regexp: /^[ \t]*\|? *(?::?-+:?) *( *\| *(?::?-+:?) *)*\|? *$/)
#   # Returns: [{ column_offset: 1, columns: 3, delimiter: '|', rows: 3, start_index: 0 }]
class TableExtractor
  # Extract tables from an array of text lines formatted in Markdown style
  #
  # @param lines [Array<String>] The array of text lines to analyze
  # @param regexp [Regexp] Regular expression to match table separator rows (e.g., |---|---|)
  # @param multi_line_delimiter [String] Delimiter character for multi-line tables (default: '|')
  # @param single_line_delimiter [String] Delimiter character for single-line tables (default: '!')
  # @return [Array<Hash>] Array of table metadata hashes with keys:
  #   - column_offset: Always 1 (for compatibility)
  #   - columns: Number of columns in the table
  #   - delimiter: The delimiter character used ('|' or '!')
  #   - rows: Number of rows in the table
  #   - start_index: Index of the first line of the table in the input array
  def self.extract_tables(
    lines,
    multi_line_delimiter: '|',
    regexp:,
    single_line_delimiter: '!'
  )
    current_column_count = 0
    current_row_count = 0
    extracted_tables = []
    inside_multi_line_table = false
    table_start_index = nil

    # Regex patterns for single-line table row parsing
    single_line_start_pattern = /^\s*#{single_line_delimiter}/
    single_line_content_pattern = /(?:^|(?<=#{single_line_delimiter}))\s*([^#{single_line_delimiter}]*)\s*(?=#{single_line_delimiter}|$)/

    # Helper method to add the current table to results and reset state
    add_current_table = lambda do |delimiter|
      extracted_tables << {
        column_offset: 1,
        columns: current_column_count,
        delimiter: delimiter,
        rows: current_row_count,
        start_index: table_start_index
      }
      current_column_count = 0
      current_row_count = 0
      inside_multi_line_table = false
      table_start_index = nil
    end

    lines.each_with_index do |line, line_index|
      # Detect single-line tables (e.g., !Name!Age!City!)
      if !inside_multi_line_table && line =~ single_line_start_pattern
        current_row_count = 1
        extracted_columns = line.scan(single_line_content_pattern).flatten
        table_start_index = line_index

        current_column_count = extracted_columns.count - 1
        add_current_table.call(single_line_delimiter)

      # Detect multi-line table separator rows (e.g., |---|---|)
      elsif line.strip.match?(regexp)
        if inside_multi_line_table
          # Add the current table before starting a new one
          add_current_table.call(multi_line_delimiter)
        end
        # Start a new multi-line table
        current_column_count = line.split(multi_line_delimiter).count - 1
        current_row_count = 2 # Account for header and separator rows
        inside_multi_line_table = true
        table_start_index = line_index - 1 if table_start_index.nil?

      # Continue multi-line table with data rows
      elsif inside_multi_line_table &&
            (line.strip.start_with?(multi_line_delimiter) ||
             line.include?(multi_line_delimiter))
        current_row_count += 1

      # End multi-line table when we encounter a non-table line
      elsif inside_multi_line_table
        add_current_table.call(multi_line_delimiter)
      end
    end

    # Handle table that ends at the last line
    if inside_multi_line_table
      add_current_table.call(multi_line_delimiter)
    end

    extracted_tables
  end
end

return if $PROGRAM_NAME != __FILE__

# # for ww
# require 'bundler/setup'
# Bundler.require(:default)

require 'minitest/autorun'

class TestTableExtractor < Minitest::Test
  # Regex pattern to match table separator rows with optional colons and hyphens
  @@table_separator_regexp = /^[ \t]*\|? *(?::?-+:?) *( *\| *(?::?-+:?) *)*\|? *$/
  @@multi_line_delimiter = '|'
  @@single_line_delimiter = '!'

  def test_single_table
    lines = [
      '| Species| Genus| Family',
      '|-|-|-',
      '| Pongo tapanuliensis| Pongo| Hominidae',
      '| | Histiophryne| Antennariidae'
    ]
    expected = [{ column_offset: 1, columns: 3, delimiter: @@multi_line_delimiter, rows: 4,
                  start_index: 0 }]
    assert_equal expected,
                 TableExtractor.extract_tables(
                   lines,
                   regexp: @@table_separator_regexp,
                   multi_line_delimiter: @@multi_line_delimiter,
                   single_line_delimiter: @@single_line_delimiter
                 )
  end

  def test_indented_table
    lines = [
      "\t | Species| Genus| Family",
      "\t |-|-|-",
      "\t | Pongo tapanuliensis| Pongo| Hominidae",
      "\t | | Histiophryne| Antennariidae"
    ]
    expected = [{ column_offset: 1, columns: 3, delimiter: @@multi_line_delimiter, rows: 4,
                  start_index: 0 }]
    assert_equal expected,
                 TableExtractor.extract_tables(
                   lines,
                   regexp: @@table_separator_regexp,
                   multi_line_delimiter: @@multi_line_delimiter,
                   single_line_delimiter: @@single_line_delimiter
                 )
  end

  def test_multiple_tables
    lines = [
      '| Species| Genus| Family',
      '|-|-|-',
      '| Pongo tapanuliensis| Pongo| Hominidae',
      '| | Histiophryne| Antennariidae',
      '',
      '| Name| Species',
      '|-|-',
      '| Tapanuli Orangutan| Pongo tapanuliensis'
    ]
    expected = [
      { column_offset: 1, columns: 3, delimiter: @@multi_line_delimiter,
        rows: 4, start_index: 0 },
      { column_offset: 1, columns: 2, delimiter: @@multi_line_delimiter,
        rows: 3, start_index: 5 }
    ]
    assert_equal expected,
                 TableExtractor.extract_tables(
                   lines,
                   regexp: @@table_separator_regexp,
                   multi_line_delimiter: @@multi_line_delimiter,
                   single_line_delimiter: @@single_line_delimiter
                 )
  end

  def test_no_tables
    lines = [
      'This is a regular line.',
      'Another regular line.'
    ]
    expected = []
    assert_equal expected,
                 TableExtractor.extract_tables(
                   lines,
                   regexp: @@table_separator_regexp
                 )
  end

  def test_inconsistent_columns
    lines = [
      '| Species| Genus| Family',
      '|-|-',
      '| Pongo tapanuliensis| Pongo| Hominidae',
      '| | Histiophryne| Antennariidae',
      '',
      '| Name| Species',
      '|-|-|-',
      '| Tapanuli Orangutan| Pongo tapanuliensis'
    ]
    # Number of columns determined from row of dividers
    expected = [
      { column_offset: 1, columns: 2, delimiter: @@multi_line_delimiter,
        rows: 4, start_index: 0 },
      { column_offset: 1, columns: 3, delimiter: @@multi_line_delimiter,
        rows: 3, start_index: 5 }
    ]
    assert_equal expected,
                 TableExtractor.extract_tables(
                   lines,
                   regexp: @@table_separator_regexp,
                   multi_line_delimiter: @@multi_line_delimiter,
                   single_line_delimiter: @@single_line_delimiter
                 )
  end

  def test_table_at_end_of_lines
    lines = [
      'Some introductory text.',
      '| Species| Genus| Family',
      '|-|-|-',
      '| Pongo tapanuliensis| Pongo| Hominidae',
      '| | Histiophryne| Antennariidae'
    ]
    expected = [
      { column_offset: 1, columns: 3, delimiter: @@multi_line_delimiter,
        rows: 4, start_index: 1 }
    ]
    assert_equal expected,
                 TableExtractor.extract_tables(
                   lines,
                   regexp: @@table_separator_regexp,
                   multi_line_delimiter: @@multi_line_delimiter,
                   single_line_delimiter: @@single_line_delimiter
                 )
  end

  def test_table_without_starting_pipe
    lines = [
      'Some introductory text.',
      'Platform| Target Environment| Command',
      '|-|-|-',
      '| Pongo tapanuliensis| Pongo| Hominidae',
      '| | Histiophryne| Antennariidae'
    ]
    expected = [
      { column_offset: 1, columns: 3, delimiter: @@multi_line_delimiter,
        rows: 4, start_index: 1 }
    ]
    assert_equal expected,
                 TableExtractor.extract_tables(
                   lines,
                   regexp: @@table_separator_regexp,
                   multi_line_delimiter: @@multi_line_delimiter,
                   single_line_delimiter: @@single_line_delimiter
                 )
  end

  def test_table_with_colon_hyphens
    lines = [
      '| Name| Age| City',
      '|:-:|:-|:-:',
      '| John Doe| 30| New York',
      '| Jane Doe| 25| Los Angeles'
    ]
    expected = [
      { column_offset: 1, columns: 3, delimiter: @@multi_line_delimiter,
        rows: 4, start_index: 0 }
    ]
    assert_equal expected,
                 TableExtractor.extract_tables(
                   lines,
                   regexp: @@table_separator_regexp,
                   multi_line_delimiter: @@multi_line_delimiter,
                   single_line_delimiter: @@single_line_delimiter
                 )
  end
end
