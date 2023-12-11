#!/usr/bin/env ruby
# frozen_string_literal: true

# encoding=utf-8

class AnsiFormatter
  def initialize(options = {})
    @options = options
  end

  def format_and_highlight_array(
    data,
    highlight_color_sym: :exception_color_detail,
    plain_color_sym: :menu_chrome_color,
    label: 'Data:',
    highlight: [],
    line_prefix: '  ',
    line_postfix: '',
    detail_sep: ''
  )
    (data&.map do |item|
      scan_and_process_multiple_substrings(item, highlight, plain_color_sym,
                                           highlight_color_sym).join
      # color_sym = highlight.include?(item) ? highlight_color_sym : c
      # string_send_color(item, color_sym)
    end || []) #.join
    # formatted_deps
    # "#{line_prefix}#{string_send_color(label, highlight_color_sym)}#{line_postfix}\n" + formatted_deps.join("\n")
  end

  # Formats and highlights a list of data. data are presented with indentation,
  # and specific items can be highlighted in a specified color, while others are shown in a plain color.
  #
  # @param data [Hash] A hash of data, where each key is a dependency name,
  #        and its value is an array of sub-items.
  # @param highlight_color_sym [Symbol] The color method to apply to highlighted items.
  #        Default is :exception_color_detail.
  # @param plain_color_sym [Symbol] The color method for non-highlighted items.
  #        Default is :menu_chrome_color.
  # @param label [String] The label to prefix the list of data with.
  #        Default is 'data:'.
  # @param highlight [Array] An array of items to highlight. Each item in this array will be
  #        formatted with the specified highlight color.
  # @param line_prefix [String] Prefix for each line. Default is '  '.
  # @param line_postfix [String] Postfix for each line. Default is ''.
  # @param detail_sep [String] Separator for items in the sub-list. Default is '  '.
  # @return [String] A formatted string representation of the data with highlighted items.
  def format_and_highlight_hash(
    data,
    highlight_color_sym: :exception_color_detail,
    plain_color_sym: :menu_chrome_color,
    label: 'Data:',
    highlight: [],
    line_prefix: '  ',
    line_postfix: '',
    detail_sep: '  '
  )
    formatted_deps = data&.map do |dep_name, sub_items|
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

  # Function to scan a string and process its segments based on multiple substrings
  # @param str [String] The string to scan.
  # @param substrings [Array<String>] The substrings to match in the string.
  # @param plain_sym [Symbol] The symbol for non-matching segments.
  # @param color_sym [Symbol] The symbol for matching segments.
  # @return [Array<String>] The processed segments.
  def scan_and_process_multiple_substrings(str, substrings, plain_sym, color_sym)
    return string_send_color(str, plain_sym) if substrings.empty? || substrings.any?(&:empty?)

    results = []
    remaining_str = str.dup

    while remaining_str.length.positive?
      match_indices = substrings.map { |substring| remaining_str.index(substring) }.compact
      earliest_match = match_indices.min

      if earliest_match
        # Process non-matching segment before the earliest match, if any
        unless earliest_match.zero?
          non_matching_segment = remaining_str.slice!(0...earliest_match)
          results << string_send_color(non_matching_segment, plain_sym)
        end

        # Find which substring has this earliest match
        matching_substring = substrings.find do |substring|
          remaining_str.index(substring) == earliest_match
        end

        if matching_substring
          matching_segment = remaining_str.slice!(0...matching_substring.length)
          results << string_send_color(matching_segment, color_sym)
        end
      else
        # Process the remaining non-matching segment
        results << string_send_color(remaining_str, plain_sym)
        break
      end
    end

    results
  end

  # Function to scan a string and process its segments
  # @param str [String] The string to scan.
  # @param substring [String] The substring to match in the string.
  # @param plain_sym [Symbol] The symbol for non-matching segments.
  # @param color_sym [Symbol] The symbol for matching segments.
  # @return [Array<String>] The processed segments.
  def scan_and_process_string(str, substring, plain_sym, color_sym)
    return string_send_color(str, plain_sym) unless substring.present?

    results = []
    remaining_str = str.dup

    while remaining_str.length.positive?
      match_index = remaining_str.index(substring)
      if match_index
        # Process non-matching segment before the match, if any
        unless match_index.zero?
          non_matching_segment = remaining_str.slice!(0...match_index)
          results << string_send_color(non_matching_segment, plain_sym)
        end

        # Process the matching segment
        matching_segment = remaining_str.slice!(0...substring.length)
        results << string_send_color(matching_segment, color_sym)
      else
        # Process the remaining non-matching segment
        results << string_send_color(remaining_str, plain_sym)
        break
      end
    end

    results
  end

  # Applies a color method to a string based on the provided color symbol.
  # The color method is fetched from @options and applied to the string.
  # @param string [String] The string to which the color will be applied.
  # @param color_sym [Symbol] The symbol representing the color method.
  # @param default [String] Default color method to use if color_sym is not found in @options.
  # @return [String] The string with the applied color method.
  def string_send_color(string, color_sym, default: 'plain')
    color_method = @options.fetch(color_sym, default).to_sym
    string.to_s.send(color_method)
  end
end
