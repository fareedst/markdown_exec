# frozen_string_literal: true

require 'ostruct'

require_relative 'hierarchy_string'

module MarkdownTableFormatter
  module_function

  def calculate_column_alignment_and_widths(rows, column_count)
    alignment_indicators = Array.new(column_count, :left)
    column_widths = Array.new(column_count, 0)

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
    if column_widths.last&.zero?
      column_widths.pop
      alignment_indicators.pop
    end

    [alignment_indicators, column_widths]
  end

  def decorate_line(line, role, counter, decorate)
    return line unless decorate

    style = decoration_style(line, role, counter, decorate)
    return line unless style

    AnsiString.new(line).send(style)
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

  def determine_column_alignment(cell)
    if cell =~ /^-+:$/
      :right
    elsif cell =~ /^:-+:$/
      :center
    else
      :left
    end
  end

  def format_cell(cell, align, width, truncate: true)
    plain_string = cell.gsub(/\033\[[\d;]+m|\033\[0m/, '')
    truncated = false
    ret = TrackedString.new(
      case
      when truncate && plain_string.length > width
        truncated = true
        plain_string[0, width]
      when align == :center
        cell.center(width)
      when align == :right
        cell.rjust(width)
      else
        cell.ljust(width)
      end
    )
    ret.truncated = truncated
    ret
  end

  def format_row_line__hs(
    row, alignment_indicators, column_widths, decorate,
    style_sym: :color,
    text_sym: :text,
    truncate: true
  )
    return HierarchyString.new if row.cells.nil?

    border_style = decorate && decorate[:border]
    HierarchyString.new(
      [{ text_sym => '| ', style_sym => border_style },
       *insert_every_other(
         row.cells.map.with_index do |cell, i|
           next unless alignment_indicators[i] && column_widths[i]

           if row.role == :separator_line
             { text_sym => '-' * column_widths[i],
               style_sym => decorate && decorate[row.role] }
           else
             {
               text_sym => format_cell(
                 cell, alignment_indicators[i], column_widths[i],
                 truncate: truncate
               ),
               style_sym => decoration_style(row.role, row.counter, decorate)
             }
           end
         end.compact,
         { text_sym => ' | ', style_sym => border_style }
       ),
       { text_sym => ' |', style_sym => border_style }].compact,
      style_sym: style_sym,
      text_sym: text_sym
    )
  end

  def format_rows__hs(
    rows, alignment_indicators, column_widths, decorate,
    truncate: true
  )
    rows.map do |row|
      format_row_line__hs(
        row, alignment_indicators, column_widths, decorate,
        truncate: truncate
      )
    end
  end

  def format_table(**kwargs)
    format_table__hs(**kwargs).map(&:decorate)
  end

  def format_table__hs(
    lines:, column_count:, decorate: nil,
    table_width: nil,
    truncate: true
  )
    unless column_count.positive?
      return lines.map do |line|
        HierarchyString.new([{ text: line }])
        # HierarchyString.new([{ text: line, color: decorate }]) #???
      end
    end

    rows = raw_lines_into_row_role_cells(lines, column_count)

    alignment_indicators, column_widths =
      calculate_column_alignment_and_widths(rows, column_count)

    unless table_width.nil?
      sum_column_widths = column_widths.sum + (column_count * 3 + 5)
      if sum_column_widths > table_width
        ratio = table_width.to_f / sum_column_widths
        column_widths.each_with_index do |width, i|
          column_widths[i] = (width * ratio).to_i
        end
      end
    end

    format_rows__hs(
      rows, alignment_indicators, column_widths, decorate,
      truncate: truncate
    )
  end

  def insert_every_other(array, obj)
    result = []
    array.each_with_index do |element, index|
      result << element
      result << obj if index < array.size - 1
    end
    result
  end

  def raw_lines_into_row_role_cells(lines, column_count)
    role = :header_row
    counter = -1

    ret = []
    lines.each do |line|
      line += '|' unless line.end_with?('|')
      counter += 1

      role = role_for_raw_row(role, line)
      counter = reset_counter_if_needed(role, counter)
      cells = split_decorated_row_into_cells(line, column_count)
      ret << OpenStruct.new(cells: cells, role: role, counter: counter)
    end
    ret
  end

  def reset_counter_if_needed(role, counter)
    %i[header_row row].include?(role) ? counter : 0
  end

  def role_for_raw_row(current_role, line)
    case current_role
    when :header_row
      if line =~ /^[ \t]*\| *[:\-][:\- |]*$/
        :separator_line
      else
        current_role
      end
    when :separator_line
      :row
    when :row
      current_role
    else
      raise "Unexpected role: #{current_role} for line #{line}"
    end
  end

  def split_decorated_row_into_cells(line, column_count)
    cells = line.split('|').map(&:strip)[1..-1]
    cells&.slice(0, column_count)&.fill('', cells.length...column_count)
  end
end

return if $PROGRAM_NAME != __FILE__

require 'minitest/autorun'

class TestMarkdownTableFormatter < Minitest::Test
  def setup
    @lines = [
      '| Header 1 | Header 2 | Header 3 |',
      '|----------|:--------:|---------:|',
      '| Row 1 Col 1 | Row 1 Col 2 | Row 1 Col 3 |',
      '| Row 2 Col 1 | Row 2 Col 2 | Row 2 Col 3 |'
    ]
    @column_count = 3
  end

  def test_format_table
    result = MarkdownTableFormatter.format_table(
      column_count: @column_count, lines: @lines
    )
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
    result = MarkdownTableFormatter.format_table(
      column_count: @column_count,
      decorate: decorate,
      lines: @lines
    )
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
    result = MarkdownTableFormatter.format_table(
      lines: lines_with_empty,
      column_count: @column_count
    )
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
    result = MarkdownTableFormatter.format_table(
      lines: lines_with_alignment,
      column_count: @column_count
    )
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
    column_count = 3
    expected = [
      '| Species             | Genus        | Family        |',
      '| ------------------- | ------------ | ------------- |',
      '| Pongo tapanuliensis | Pongo        | Hominidae     |',
      '|                     | Histiophryne | Antennariidae |'
    ]
    assert_equal expected, MarkdownTableFormatter.format_table(
      lines: lines,
      column_count: column_count
    )
  end

  def test_missing_column_count
    lines = [
      '| A| B| C',
      '| 1| 2',
      '| X'
    ]
    column_count = 3
    expected = [
      '| A | B | C |',
      '| 1 | 2 |   |',
      '| X |   |   |'
    ]
    assert_equal expected, MarkdownTableFormatter.format_table(
      lines: lines,
      column_count: column_count
    )
  end

  # def test_extra_column_count
  #   lines = [
  #     "| A| B| C| D",
  #     "| 1| 2| 3| 4| 5"
  #   ]
  #   column_count = 3
  #   expected = [
  #     "| A | B | C ",
  #     "| 1 | 2 | 3 "
  #   ]
  #   assert_equal expected, MarkdownTableFormatter.format_table(lines, column_count)
  # end

  def test_empty_input
    assert_equal [], MarkdownTableFormatter.format_table(
      lines: [],
      column_count: 3
    )
  end

  def test_single_column
    lines = [
      '| A',
      '| Longer text',
      '| Short'
    ]
    column_count = 1
    expected = [
      '| A           |',
      '| Longer text |',
      '| Short       |'
    ]
    assert_equal expected, MarkdownTableFormatter.format_table(
      lines: lines,
      column_count: column_count
    )
  end

  def test_no_pipe_at_end
    lines = [
      '| A| B| C',
      '| 1| 2| 3'
    ]
    column_count = 3
    expected = [
      '| A | B | C |',
      '| 1 | 2 | 3 |'
    ]
    assert_equal expected, MarkdownTableFormatter.format_table(
      lines: lines,
      column_count: column_count
    )
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
    assert_equal expected_output, MarkdownTableFormatter.format_table(
      lines: lines,
      column_count: 3
    )
  end

  def test_incomplete_column_count
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
    assert_equal expected_output, MarkdownTableFormatter.format_table(
      lines: lines,
      column_count: 3
    )
  end

  def test_extra_column_count
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
    assert_equal expected_output, MarkdownTableFormatter.format_table(
      lines: lines,
      column_count: 4
    )
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
    assert_equal expected_output, MarkdownTableFormatter.format_table(
      lines: lines,
      column_count: 3
    )
  end

  def test_single_line
    lines = ['| Name | Age | City |']
    expected_output = ['| Name | Age | City |']
    assert_equal expected_output, MarkdownTableFormatter.format_table(
      lines: lines,
      column_count: 3
    )
  end

  def test_empty_lines
    lines = []
    expected_output = []
    assert_equal expected_output, MarkdownTableFormatter.format_table(
      lines: lines,
      column_count: 3
    )
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
    assert_equal expected_output, MarkdownTableFormatter.format_table(
      lines: lines,
      column_count: 3
    )
  end
end
