# frozen_string_literal: true

# encoding=utf-8
module StringUtil
  # Splits the given string on the first occurrence of the specified character.
  # Returns an array containing the portion of the string before the character and the rest of the string.
  #
  # @param input_str [String] The string to be split.
  # @param split_char [String] The character on which to split the string.
  # @return [Array<String>] An array containing two elements: the part of the string before split_char, and the rest of the string.
  def self.partition_at_first(input_str, split_char)
    split_index = input_str.index(split_char)

    if split_index.nil?
      [input_str, '']
    else
      [input_str[0...split_index], input_str[(split_index + 1)..-1]]
    end
  end
end

class String
  unless method_defined?(:present?)
    # Checks if the string contains any non-whitespace characters.
    # @return [Boolean] Returns true if the string contains non-whitespace
    # characters, false otherwise.
    def present?
      !strip.empty?
    end
  end
end

# String.delete_even_chars / String.delete_even_chars!
#
# Class methods that remove the 2nd, 4th, 6th, ... characters from a string.
#
# Behavior
# - Operates on Unicode grapheme clusters via /\X/ to avoid splitting emoji
#   and combining sequences—“user-visible characters” are treated as units.
# - .delete_even_chars(str) returns a new string consisting of the 1st, 3rd,
#   5th, ... clusters from +str+.
# - .delete_even_chars!(str) modifies +str+ in place using #replace and
#   returns it (raises FrozenError if +str+ is frozen).
#
# Examples
#   String.delete_even_chars("abcdef")      # => "ace"
#   String.delete_even_chars("áb̂c̆")        # keeps 1st, 3rd, ... clusters intact
#   s = "👨‍👩‍👧‍👦🙂x"; String.delete_even_chars!(s)  # modifies s
#
class String
  def delete_even_chars
    clusters = scan(/\X/)
    return dup if clusters.length <= 1

    clusters.each_with_index
            .select { |_, i| i.even? } # keep 1st, 3rd, 5th... (0-based even)
            .map(&:first)
            .join
  end

  def delete_even_chars!
    replace(delete_even_chars)
  end
end

# String#sort_chars / String#sort_chars!
#
# Adds methods to order a string's user-visible characters (Unicode grapheme
# clusters) and return the joined result.
#
# Behavior
# - Sorts by Ruby’s default ordering of the grapheme cluster strings.
# - Preserves emoji and combining sequences by splitting on /\X/.
# - Optional case-insensitive key and reverse ordering.
# - Optional custom comparator block; if given, it takes precedence.
#
# API
#   String#sort_chars(reverse: false, casefold: false) { |a, b| ... } -> String
#   String#sort_chars!(reverse: false, casefold: false) { |a, b| ... } -> self
#
# Examples
#   "cba".sort_chars                     #=> "abc"
#   "Baß".sort_chars(casefold: true)     #=> "aBß"
#   "👩‍💻🚀a".sort_chars                  #=> "a👩‍💻🚀" (clusters kept intact)
#   "bca".sort_chars { |a,b| b <=> a }   #=> "cba" (custom comparator)
#
# Notes
# - For locale-aware collation, integrate a collator and use the block form.
#
class String
  def sort_chars(reverse: false, casefold: false, &block)
    clusters = scan(/\X/)
    return self if clusters.length <= 1

    sorted =
      if block
        clusters.sort(&block)
      elsif casefold
        clusters.sort_by(&:downcase)
      else
        clusters.sort
      end

    sorted.reverse! if reverse
    sorted.join
  end

  def sort_chars!(reverse: false, casefold: false, &block)
    replace(sort_chars(reverse: reverse, casefold: casefold, &block))
  end
end
