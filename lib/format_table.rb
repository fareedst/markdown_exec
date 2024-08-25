# frozen_string_literal: true

require 'ostruct'

require_relative 'hierarchy_string'

module MarkdownTableFormatter
  module_function

  def format_table(lines, columns, decorate: nil)
    rows = parse_rows(lines, columns)

    alignment_indicators, column_widths =
      calculate_column_alignment_and_widths(rows, columns)

    format_rows(rows, alignment_indicators, column_widths, decorate)
  end

  def parse_rows(lines, columns)
    role = :header_row
    counter = -1

    lines.map.with_index do |line, _row_ind|
      line += '|' unless line.end_with?('|')
      counter += 1

      role = update_role(role, line)
      counter = reset_counter_if_needed(role, counter)

      cells = extract_cells(line, columns)

      OpenStruct.new(cells: cells, role: role, counter: counter)
    end
  end

  def update_role(current_role, line)
    if current_role == :header_row && line =~ /^[ \t]*\| *[:\-][:\- |]*$/
      :separator_line
    elsif current_role == :separator_line
      :row
    elsif :row
      current_role
    else
      raise "Unexpected role: #{current_role} for line #{line}"
    end
  end

  def reset_counter_if_needed(role, counter)
    %i[header_row row].include?(role) ? counter : 0
  end

  def extract_cells(line, columns)
    cells = line.split('|').map(&:strip)[1..-1]
    cells&.fill('', cells.length...columns)
  end

  def calculate_column_alignment_and_widths(rows, columns)
    alignment_indicators = Array.new(columns, :left)
    column_widths = Array.new(columns, 0)

    rows.each do |row|
      next if row.cells.nil?

      row.cells.each_with_index do |cell, i|
        column_widths[i] = [column_widths[i], cell.length].max

        if row.role == :separator_line
          alignment_indicators[i] = determine_column_alignment(cell)
        end
      end
    end

    # 2024-08-24 remove last column if it is 0-width
    if column_widths.last.zero?
      column_widths.pop
      alignment_indicators.pop
    end

    [alignment_indicators, column_widths]
  end

  def determine_column_alignment(cell)
    if cell =~ /^-+:$/
      :right
    elsif cell =~ /^:-+:$/
      :center
    else
      :left
    end
  end

  def format_rows(rows, alignment_indicators, column_widths, decorate)
    rows.map do |row|
      format_row_line(row, alignment_indicators, column_widths, decorate)
    end
  end

  def format_row_line(row, alignment_indicators, column_widths, decorate)
    return '' if row.cells.nil?

    border_style = decorate && decorate[:border]
    HierarchyString.new(
      [{ text: '| ', style: border_style },
       *insert_every_other(
         row.cells.map.with_index do |cell, i|
           next unless alignment_indicators[i] && column_widths[i]

           if row.role == :separator_line
             { text: '-' * column_widths[i],
               style: decorate && decorate[row.role] }
           else
             {
               text: format_cell(cell, alignment_indicators[i],
                                 column_widths[i]),
               style: decoration_style(row.role, row.counter, decorate)
             }
           end
         end.compact,
         { text: ' | ', style: border_style }
       ),
       { text: ' |',
         style: border_style }].compact,
      style_sym: :style,
      text_sym: :text
    ).decorate
  end

  def format_cell(cell, align, width)
    case align
    when :center
      cell.center(width)
    when :right
      cell.rjust(width)
    else
      cell.ljust(width)
    end
  end

  def decorate_line(line, role, counter, decorate)
    return line unless decorate

    return line unless (style = decoration_style(line, role, counter, decorate))

    line.send(style)
  end

  def decoration_style(role, counter, decorate)
    return nil unless decorate

    return nil unless (style = decorate[role])

    if style.is_a?(Array)
      style[counter % style.count]
    else
      style
    end
  end

  def insert_every_other(array, obj)
    result = []
    array.each_with_index do |element, index|
      result << element
      result << obj if index < array.size - 1
    end
    result
  end
end

return if $PROGRAM_NAME != __FILE__

require 'minitest/autorun'
require_relative 'colorize'

class TestMarkdownTableFormatter < Minitest::Test
  def setup
    @lines = [
      '| Header 1 | Header 2 | Header 3 |',
      '|----------|:--------:|---------:|',
      '| Row 1 Col 1 | Row 1 Col 2 | Row 1 Col 3 |',
      '| Row 2 Col 1 | Row 2 Col 2 | Row 2 Col 3 |'
    ]
    @columns = 3
  end

  def test_format_table
    result = MarkdownTableFormatter.format_table(@lines, @columns)
    expected = [
      '| Header 1    |  Header 2   |    Header 3 |',
      '| ----------- | ----------- | ----------- |',
      '| Row 1 Col 1 | Row 1 Col 2 | Row 1 Col 3 |',
      '| Row 2 Col 1 | Row 2 Col 2 | Row 2 Col 3 |'
    ]
    assert_equal expected, result
  end

  def test_format_table_with_decoration
    decorate = { header_row: :upcase, row: %i[downcase upcase] }
    result = MarkdownTableFormatter.format_table(@lines, @columns,
                                                 decorate: decorate)
    expected = [
      '| HEADER 1    |  HEADER 2   |    HEADER 3 |',
      '| ----------- | ----------- | ----------- |',
      '| ROW 1 COL 1 | ROW 1 COL 2 | ROW 1 COL 3 |',
      '| row 2 col 1 | row 2 col 2 | row 2 col 3 |'
    ]
    assert_equal expected, result
  end

  def test_format_table_with_empty_lines
    lines_with_empty = [
      '| Header 1 | Header 2 | Header 3 |',
      '|----------|:--------:|---------:|',
      '| Row 1 Col 1 | Row 1 Col 2 | Row 1 Col 3 |',
      '',
      '| Row 2 Col 1 | Row 2 Col 2 | Row 2 Col 3 |'
    ]
    result = MarkdownTableFormatter.format_table(lines_with_empty, @columns)
    expected = [
      '| Header 1    |  Header 2   |    Header 3 |',
      '| ----------- | ----------- | ----------- |',
      '| Row 1 Col 1 | Row 1 Col 2 | Row 1 Col 3 |',
      '',
      '| Row 2 Col 1 | Row 2 Col 2 | Row 2 Col 3 |'
    ]
    assert_equal expected, result
  end

  def test_alignment_detection
    lines_with_alignment = [
      '| Header 1 | Header 2 | Header 3 |',
      '|:-------- |:--------:| --------:|'
    ]
    result = MarkdownTableFormatter.format_table(lines_with_alignment, @columns)
    expected = [
      '| Header 1  |  Header 2  |  Header 3 |',
      '| --------- | ---------- | --------- |'
    ]
    assert_equal expected, result[0..1] # only checking the header and separator
  end
end

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
      '| Species             | Genus        | Family        |',
      '| ------------------- | ------------ | ------------- |',
      '| Pongo tapanuliensis | Pongo        | Hominidae     |',
      '|                     | Histiophryne | Antennariidae |'
    ]
    assert_equal expected, MarkdownTableFormatter.format_table(lines, columns)
  end

  def test_missing_columns
    lines = [
      '| A| B| C',
      '| 1| 2',
      '| X'
    ]
    columns = 3
    expected = [
      '| A | B | C |',
      '| 1 | 2 |   |',
      '| X |   |   |'
    ]
    assert_equal expected, MarkdownTableFormatter.format_table(lines, columns)
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
  #   assert_equal expected, MarkdownTableFormatter.format_table(lines, columns)
  # end

  def test_empty_input
    assert_equal [], MarkdownTableFormatter.format_table([], 3)
  end

  def test_single_column
    lines = [
      '| A',
      '| Longer text',
      '| Short'
    ]
    columns = 1
    expected = [
      '| A           |',
      '| Longer text |',
      '| Short       |'
    ]
    assert_equal expected, MarkdownTableFormatter.format_table(lines, columns)
  end

  def test_no_pipe_at_end
    lines = [
      '| A| B| C',
      '| 1| 2| 3'
    ]
    columns = 3
    expected = [
      '| A | B | C |',
      '| 1 | 2 | 3 |'
    ]
    assert_equal expected, MarkdownTableFormatter.format_table(lines, columns)
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
      '| Name | Age | City        |',
      '| John | 30  | New York    |',
      '| Jane | 25  | Los Angeles |'
    ]
    assert_equal expected_output, MarkdownTableFormatter.format_table(lines, 3)
  end

  def test_incomplete_columns
    lines = [
      '| Name | Age |',
      '| John | 30 | New York |',
      '| Jane | 25 | Los Angeles |'
    ]
    expected_output = [
      '| Name | Age |             |',
      '| John | 30  | New York    |',
      '| Jane | 25  | Los Angeles |'
    ]
    assert_equal expected_output, MarkdownTableFormatter.format_table(lines, 3)
  end

  def test_extra_columns
    lines = [
      '| Name | Age | City | Country |',
      '| John | 30 | New York | USA |',
      '| Jane | 25 | Los Angeles | USA |'
    ]
    expected_output = [
      '| Name | Age | City        | Country |',
      '| John | 30  | New York    | USA     |',
      '| Jane | 25  | Los Angeles | USA     |'
    ]
    assert_equal expected_output, MarkdownTableFormatter.format_table(lines, 4)
  end

  def test_varied_column_lengths
    lines = [
      '| Name | Age |',
      '| Johnathan | 30 | New York |',
      '| Jane | 25 | LA |'
    ]
    expected_output = [
      '| Name      | Age |          |',
      '| Johnathan | 30  | New York |',
      '| Jane      | 25  | LA       |'
    ]
    assert_equal expected_output, MarkdownTableFormatter.format_table(lines, 3)
  end

  def test_single_line
    lines = ['| Name | Age | City |']
    expected_output = ['| Name | Age | City |']
    assert_equal expected_output, MarkdownTableFormatter.format_table(lines, 3)
  end

  def test_empty_lines
    lines = []
    expected_output = []
    assert_equal expected_output, MarkdownTableFormatter.format_table(lines, 3)
  end

  def test_complete_rows
    lines = [
      '| Name | Age |',
      '| John | 30 |'
    ]
    expected_output = [
      '| Name | Age |',
      '| John | 30  |'
    ]
    assert_equal expected_output, MarkdownTableFormatter.format_table(lines, 3)
  end
end
