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
        substring ### no change
      end

    else
      binding.irb
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
    last_end = 0

    text.scan(pattern) do |match|
      match_start = Regexp.last_match.begin(0)
      match_end = Regexp.last_match.end(0)

      # Yield the non-matching segment before the match
      yield text[last_end...match_start], false if match_start > last_end

      # Yield the matching segment
      yield match.first, true

      last_end = match_end
    end

    # Yield any remaining non-matching segment after the last match
    return unless last_end < text.length

    yield text[last_end..-1], false
  end
end
