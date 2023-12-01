# frozen_string_literal: true

##
# Replace substrings in an input string based on a regular expression pattern
# with named capture groups. The replacements are formatted using a provided
# format string. Additional context can be provided to supplement or override
# the named captures in the format string.
#
# @param input_str [String] The input string to process.
# @param regex [Regexp] The regular expression pattern with named capture groups.
# @param format_str [String] The format string for sprintf.
# @param context [Hash] Additional context to supplement or override named captures.
#
# @return [String] The processed string after replacements.
#

#     ### add import file name, line number, line, to captures_hash, chain
#     # $~ (MatchData) - MatchData object created from the match; thread-local and frame-local. - English - $LAST_MATCH_INFO.
#     # $& (Matched Substring) - The matched string. - English - $MATCH.
#     # $` (Pre-Match Substring) - The string to the left of the match. - English - $PREMATCH.
#     # $' (Post-Match Substring) - The string to the right of the match. - English - $POSTMATCH.
#     # $+ (Last Matched Group) - The last group matched. - English - $LAST_PAREN_MATCH.

# # Add file name, line number, line to captures_hash
# captures_hash[:file_name] = $~.pre_match.split("\n").last
# captures_hash[:line_number] = $~.pre_match.count("\n") + 1
# captures_hash[:line] = $&
class Regexp
  def gsub_format(input_str, format_str, context: {})
    input_str.gsub(self) do
      format(
        format_str,
        context.merge($~.names.each_with_object({}) do |name, hash|
          hash[name.to_sym] = $~[name]
        end)
      )
    end
  end
end

if $PROGRAM_NAME == __FILE__
  require 'bundler/setup'
  Bundler.require(:default)

  require 'minitest/autorun'

  class RegexpGsubFormatTest < Minitest::Test
    def test_basic_replacement
      input_str = '123 example'
      re = /(?<foo>\d+) (?<bar>\w+)/
      fmt = '%<foo>d : %<bar>s'

      result = re.gsub_format(input_str, fmt)

      assert_equal '123 : example', result
    end

    def test_no_match
      input_str = 'This is a test.'
      re = /(?<foo>\d+) (?<bar>\w+)/
      fmt = '%<foo>d : %<bar>s'

      result = re.gsub_format(input_str, fmt)

      assert_equal 'This is a test.', result
    end

    def test_multiple_matches
      input_str = '123 example, 456 test'
      re = /(?<foo>\d+) (?<bar>\w+)/
      fmt = '[%<foo>d %<bar>s]'

      result = re.gsub_format(input_str, fmt)

      assert_equal '[123 example], [456 test]', result
    end

    def test_different_named_captures
      input_str = 'Jane is 25 years old.'
      re = /^(?<name>\w+) is (?<age>\d+).*$/
      fmt = "%<name>s's age is %<age>d"

      result = re.gsub_format(input_str, fmt)

      assert_equal "Jane's age is 25", result
    end

    def test_with_context
      input_str = 'Jane is 25 years old.'
      re = /^(?<name>\w+) is (?<age>\d+).*$/
      fmt = "%<name>s's age is %<age>d and she lives in %<city>s"

      result = re.gsub_format(input_str, re, fmt, context: { city: 'New York' })

      assert_equal "Jane's age is 25 and she lives in New York", result
    end

    def test_with_context
      input_str = 'Jane is 25 years old.'
      re = /^(?<name>\w+) is (?<age>\d+).*$/
      fmt = "%<name>s's age is %<age>d and she lives in %<city>s"

      result = re.gsub_format(input_str, fmt, context: { city: 'New York' })

      assert_equal "Jane's age is 25 and she lives in New York", result
    end
  end
end
