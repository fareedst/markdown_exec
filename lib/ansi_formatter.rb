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
