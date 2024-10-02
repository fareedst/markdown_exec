# frozen_string_literal: true

class TableExtractor
  # Extract tables from an array of text lines formatted in Markdown style
  # @param [Array<String>] lines The array of text lines
  # @return [Array<Hash>] An array of tables with row count,
  #                       column count, and start index
  def self.extract_tables(lines, regexp:)
    tables = []
    inside_table = false
    table_start = nil
    row_count = 0
    column_count = 0

    lines.each_with_index do |line, index|
      # Match line separators with at least 2 columns
      if line.strip.match?(regexp)
        if inside_table
          # Add the current table before starting a new one
          tables << {
            rows: row_count,
            columns: column_count,
            start_index: table_start
          }
        end
        # Start a new table
        table_start = index - 1 if table_start.nil?
        column_count = line.split('|').count - 1
        row_count = 2 # Reset to 2 to account for the header and separator rows
        inside_table = true
      elsif inside_table && (line.strip.start_with?('|') || line.include?('|'))
        row_count += 1
      elsif inside_table
        # Add the current table and reset the state
        tables << {
          rows: row_count,
          columns: column_count,
          start_index: table_start
        }
        inside_table = false
        table_start = nil
        row_count = 0
        column_count = 0
      end
    end

    # Handle case where table ends at the last line
    if inside_table
      tables << {
        rows: row_count,
        columns: column_count,
        start_index: table_start
      }
    end

    tables
  end
end

return if $PROGRAM_NAME != __FILE__

require 'minitest/autorun'

class TestTableExtractor < Minitest::Test
  @@regexp = /^[ \t]*\|? *(?::?-+:?) *( *\| *(?::?-+:?) *)*\|? *$/

  def test_single_table
    lines = [
      '| Species| Genus| Family',
      '|-|-|-',
      '| Pongo tapanuliensis| Pongo| Hominidae',
      '| | Histiophryne| Antennariidae'
    ]
    expected = [{ rows: 4, columns: 3, start_index: 0 }]
    assert_equal expected, TableExtractor.extract_tables(lines, regexp: @@regexp)
  end

  def test_indented_table
    lines = [
      "\t | Species| Genus| Family",
      "\t |-|-|-",
      "\t | Pongo tapanuliensis| Pongo| Hominidae",
      "\t | | Histiophryne| Antennariidae"
    ]
    expected = [{ rows: 4, columns: 3, start_index: 0 }]
    assert_equal expected, TableExtractor.extract_tables(lines, regexp: @@regexp)
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
      { rows: 4, columns: 3, start_index: 0 },
      { rows: 3, columns: 2, start_index: 5 }
    ]
    assert_equal expected, TableExtractor.extract_tables(lines, regexp: @@regexp)
  end

  def test_no_tables
    lines = [
      'This is a regular line.',
      'Another regular line.'
    ]
    expected = []
    assert_equal expected, TableExtractor.extract_tables(lines, regexp: @@regexp)
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
    # number of columns determined from row of dividers
    expected = [{ rows: 4, columns: 2, start_index: 0 },
                { rows: 3, columns: 3, start_index: 5 }]
    assert_equal expected, TableExtractor.extract_tables(lines, regexp: @@regexp)
  end

  def test_table_at_end_of_lines
    lines = [
      'Some introductory text.',
      '| Species| Genus| Family',
      '|-|-|-',
      '| Pongo tapanuliensis| Pongo| Hominidae',
      '| | Histiophryne| Antennariidae'
    ]
    expected = [{ rows: 4, columns: 3, start_index: 1 }]
    assert_equal expected, TableExtractor.extract_tables(lines, regexp: @@regexp)
  end

  def test_table_without_starting_pipe
    lines = [
      'Some introductory text.',
      'Platform| Target Environment| Command',
      '|-|-|-',
      '| Pongo tapanuliensis| Pongo| Hominidae',
      '| | Histiophryne| Antennariidae'
    ]
    expected = [{ rows: 4, columns: 3, start_index: 1 }]
    assert_equal expected, TableExtractor.extract_tables(lines, regexp: @@regexp)
  end

  def test_table_with_colon_hyphens
    lines = [
      '| Name| Age| City',
      '|:-:|:-|:-:',
      '| John Doe| 30| New York',
      '| Jane Doe| 25| Los Angeles'
    ]
    expected = [{ rows: 4, columns: 3, start_index: 0 }]
    assert_equal expected, TableExtractor.extract_tables(lines, regexp: @@regexp)
  end
end
