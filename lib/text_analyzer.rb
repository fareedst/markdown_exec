# frozen_string_literal: true

module TextAnalyzer
  # Analyzes a hierarchical structure (String or Array) and highlights segments based on the pattern
  #
  # @param hierarchy [String, Array] the hierarchical structure to be analyzed
  # @param pattern [Regexp] the pattern to match against the text
  # @param default_color [String] the color for non-matching segments
  # @param match_color [String] the color for matching segments
  #
  # @return [Array<Hash>, Array<Array<Hash>>] an array or nested arrays of highlighted segments
  #
  # @raise [ArgumentError] if the hierarchy structure is neither a String nor an Array
  def self.analyze_hierarchy(hierarchy, pattern, default_color, match_color)
    case hierarchy
    when String
      highlight_segments(hierarchy, pattern, default_color, match_color)

    when Hash
      decorated = highlight_segments(hierarchy[:text], pattern,
                                     hierarchy[:color], match_color)

      case decorated
      when String
        hierarchy
      when Array
        if decorated.length == 1
          hierarchy
        else
          decorated
        end
      else
        decorated
      end

    when Array
      hierarchy.map do |element|
        analyze_hierarchy(element, pattern, default_color, match_color)
      end

    when HierarchyString
      hierarchy.replace_text! do |substring|
        substring # no change
      end

    else
      warn [hierarchy.class, hierarchy].inspect
      raise ArgumentError, 'Invalid hierarchy structure'
    end
  end

  # Highlights segments of the text based on the pattern
  #
  # @param text [String] the text to be analyzed
  # @param pattern [Regexp] the pattern to match against the text
  # @param default_color [String] the color for non-matching segments
  # @param match_color [String] the color for matching segments
  #
  # @return [Array<Hash>] an array of hashes, each containing a segment of text and its corresponding color
  def self.highlight_segments(text, pattern, default_color, match_color)
    segments = []

    yield_matches_and_non_matches(text, pattern) do |segment, is_match|
      segments << if is_match
                    { text: segment, color: match_color }
                  else
                    { text: segment, color: default_color }
                  end
    end

    segments
  end

  # Yields matching and non-matching segments of the text based on the pattern
  #
  # @param text [String] the text to be analyzed
  # @param pattern [Regexp] the pattern to match against the text
  #
  # @yieldparam segment [String] a segment of the text
  # @yieldparam is_match [Boolean] true if the segment matches the pattern, false otherwise
  def self.yield_matches_and_non_matches(text, pattern)
    last_end = nil

    text.scan(pattern) do |match|
      match_start = Regexp.last_match.begin(0)
      match_end = Regexp.last_match.end(0)

      # Yield the non-matching segment before the match
      yield text[(last_end || 0)...match_start], false if last_end.nil? || match_start > last_end

      # Yield the matching segment
      yield match.first, true

      last_end = match_end
    end

    last_end ||= 0
    # Yield any remaining non-matching segment after the last match
    return unless last_end < text.length

    yield text[last_end..-1], false
  end
end

return if $PROGRAM_NAME != __FILE__

require 'minitest/autorun'
require_relative 'hierarchy_string'

$default_color = :upcase
$match_color = :downcase

class TestTextAnalyzer < Minitest::Test
  def test_analyze_hierarchy_with_string
    text = 'This is a test string.'
    pattern = /(test)/

    expected_output = [[[
      { text: 'This is a ', color: $default_color },
      { text: 'test', color: $match_color },
      { text: ' string.', color: $default_color }
    ]]]

    tree = HierarchyString.new([{ text: text, color: $default_color }])
    assert_equal expected_output,
                 TextAnalyzer.analyze_hierarchy(tree.substrings, pattern, $default_color,
                                                $match_color)
  end

  def test_analyze_hierarchy_with_array
    hierarchy = [
      'This is a test string.',
      'Another test line.'
    ]
    pattern = /(test)/

    expected_output = [
      [
        { text: 'This is a ', color: $default_color },
        { text: 'test', color: $match_color },
        { text: ' string.', color: $default_color }
      ],
      [
        { text: 'Another ', color: $default_color },
        { text: 'test', color: $match_color },
        { text: ' line.', color: $default_color }
      ]
    ]

    assert_equal expected_output,
                 TextAnalyzer.analyze_hierarchy(hierarchy, pattern,
                                                $default_color, $match_color)
  end

  def test_analyze_hierarchy_with_nested_array
    hierarchy = [
      'This is a test string.',
      ['Another test line.', 'Yet another test.']
    ]
    pattern = /(test)/

    expected_output = [
      [
        { text: 'This is a ', color: $default_color },
        { text: 'test', color: $match_color },
        { text: ' string.', color: $default_color }
      ],
      [
        [
          { text: 'Another ', color: $default_color },
          { text: 'test', color: $match_color },
          { text: ' line.', color: $default_color }
        ],
        [
          { text: 'Yet another ', color: $default_color },
          { text: 'test', color: $match_color },
          { text: '.', color: $default_color }
        ]
      ]
    ]

    assert_equal expected_output,
                 TextAnalyzer.analyze_hierarchy(hierarchy, pattern,
                                                $default_color, $match_color)
  end

  def test_analyze_hierarchy_with_invalid_type
    hierarchy = 12_345
    # hierarchy = HierarchyString.new([{ text: '12345', color: $default_color }])
    pattern = /(test)/

    assert_raises(ArgumentError) do
      TextAnalyzer.analyze_hierarchy(hierarchy, pattern, $default_color,
                                     $match_color)
    end
  end

  def test_highlight_segments
    text = 'This is a test string.'
    pattern = /(test)/

    expected_output = [
      { text: 'This is a ', color: $default_color },
      { text: 'test', color: $match_color },
      { text: ' string.', color: $default_color }
    ]

    assert_equal expected_output,
                 TextAnalyzer.highlight_segments(text, pattern, $default_color,
                                                 $match_color)
  end

  def test_yield_matches_and_non_matches
    text = 'This is a test string with multiple tests.'
    pattern = /(test)/
    segments = []

    TextAnalyzer.yield_matches_and_non_matches(text,
                                               pattern) do |segment, is_match|
      segments << { text: segment, is_match: is_match }
    end

    expected_output = [
      { text: 'This is a ', is_match: false },
      { text: 'test', is_match: true },
      { text: ' string with multiple ', is_match: false },
      { text: 'test', is_match: true },
      { text: 's.', is_match: false }
    ]

    assert_equal expected_output, segments
  end
end
