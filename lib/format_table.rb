# frozen_string_literal: true

def format_table(lines, columns)
  # Split Lines into Cells
  dividers_row_ind = nil
  rows = lines.map.with_index do |line, row_ind|
    line += '|' unless line.end_with?('|')

    # match indented (spaces or tabs) dividers with `|`, `-` and `:` chars
    if dividers_row_ind.nil? && line =~ /^[ \t]*\| *[:\-][:\- |]*$/
      dividers_row_ind = row_ind
    end

    cells = line.split('|').map(&:strip)[1..-1]
    cells&.fill('', cells.length...columns)
    cells
  end

  # Calculate Column Widths
  column_align = Array.new(columns, :left)
  column_widths = Array.new(columns, 0)
  rows.each.with_index do |row, row_ind|
    next if row.nil?

    row.each_with_index do |cell, i|
      column_widths[i] = [column_widths[i], cell.length].max

      if row_ind == dividers_row_ind
        if cell =~ /^-+:$/
          column_align[i] = :right
          dividers_row_ind = row_ind
        elsif cell =~ /^:-+:$/
          column_align[i] = :center
          dividers_row_ind = row_ind
        else
          column_align[i] = :left
          dividers_row_ind = row_ind
        end
      end
    end
  end

  # Format Rows
  rows.map.with_index do |row, row_ind|
    if row.nil?
      ''
    else
      '| ' + row.map.with_index do |cell, i|
        # if cell =~ /^:?-+:?$/
        if row_ind == dividers_row_ind
          '-' * column_widths[i]
        else
          # cell.ljust(column_widths[i])
          case column_align[i]
          when :center
pp [__LINE__]
            cell.center(column_widths[i])
          when :right
            cell.rjust(column_widths[i])
          else
            cell.ljust(column_widths[i])
          end
        end
      end.join(' | ')
    end
  end
end

return if $PROGRAM_NAME != __FILE__

require 'minitest/autorun'

class TestFormatTable < Minitest::Test
  def test_basic_formatting
    lines = [
      '| Species| Genus| Family',
      '|-|-|-',
      '| Pongo tapanuliensis| Pongo| Hominidae',
      '| | Histiophryne| Antennariidae'
    ]
    columns = 3
    expected = [
      '| Species             | Genus        | Family       ',
      '| ------------------- | ------------ | -------------',
      '| Pongo tapanuliensis | Pongo        | Hominidae    ',
      '|                     | Histiophryne | Antennariidae'
    ]
    assert_equal expected, format_table(lines, columns)
  end

  def test_missing_columns
    lines = [
      '| A| B| C',
      '| 1| 2',
      '| X'
    ]
    columns = 3
    expected = [
      '| A | B | C',
      '| 1 | 2 |  ',
      '| X |   |  '
    ]
    assert_equal expected, format_table(lines, columns)
  end

  # def test_extra_columns
  #   lines = [
  #     "| A| B| C| D",
  #     "| 1| 2| 3| 4| 5"
  #   ]
  #   columns = 3
  #   expected = [
  #     "| A | B | C ",
  #     "| 1 | 2 | 3 "
  #   ]
  #   assert_equal expected, format_table(lines, columns)
  # end

  def test_empty_input
    assert_equal [], format_table([], 3)
  end

  def test_single_column
    lines = [
      '| A',
      '| Longer text',
      '| Short'
    ]
    columns = 1
    expected = [
      '| A          ',
      '| Longer text',
      '| Short      '
    ]
    assert_equal expected, format_table(lines, columns)
  end

  def test_no_pipe_at_end
    lines = [
      '| A| B| C',
      '| 1| 2| 3'
    ]
    columns = 3
    expected = [
      '| A | B | C',
      '| 1 | 2 | 3'
    ]
    assert_equal expected, format_table(lines, columns)
  end
end

class TestFormatTable2 < Minitest::Test
  def test_basic_formatting
    lines = [
      '| Name | Age | City |',
      '| John | 30 | New York |',
      '| Jane | 25 | Los Angeles |'
    ]
    expected_output = [
      '| Name | Age | City       ',
      '| John | 30  | New York   ',
      '| Jane | 25  | Los Angeles'
    ]
    assert_equal expected_output, format_table(lines, 3)
  end

  def test_incomplete_columns
    lines = [
      '| Name | Age |',
      '| John | 30 | New York |',
      '| Jane | 25 | Los Angeles |'
    ]
    expected_output = [
      '| Name | Age |            ',
      '| John | 30  | New York   ',
      '| Jane | 25  | Los Angeles'
    ]
    assert_equal expected_output, format_table(lines, 3)
  end

  def test_extra_columns
    lines = [
      '| Name | Age | City | Country |',
      '| John | 30 | New York | USA |',
      '| Jane | 25 | Los Angeles | USA |'
    ]
    expected_output = [
      '| Name | Age | City        | Country',
      '| John | 30  | New York    | USA    ',
      '| Jane | 25  | Los Angeles | USA    '
    ]
    assert_equal expected_output, format_table(lines, 4)
  end

  def test_varied_column_lengths
    lines = [
      '| Name | Age |',
      '| Johnathan | 30 | New York |',
      '| Jane | 25 | LA |'
    ]
    expected_output = [
      '| Name      | Age |         ',
      '| Johnathan | 30  | New York',
      '| Jane      | 25  | LA      '
    ]
    assert_equal expected_output, format_table(lines, 3)
  end

  def test_single_line
    lines = ['| Name | Age | City |']
    expected_output = ['| Name | Age | City']
    assert_equal expected_output, format_table(lines, 3)
  end

  def test_empty_lines
    lines = []
    expected_output = []
    assert_equal expected_output, format_table(lines, 3)
  end

  def test_incomplete_rows
    lines = [
      '| Name | Age |',
      '| John | 30 |'
    ]
    expected_output = [
      '| Name | Age | ',
      '| John | 30  | '
    ]
    assert_equal expected_output, format_table(lines, 3)
  end
end
