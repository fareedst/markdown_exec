#!/usr/bin/env -S bundle exec ruby
# frozen_string_literal: true

# encoding=utf-8

require_relative 'executed_shell_command'

##
# TransformedShellCommand executes a shell command and provides access to
# a transformed version of the output.
#
# The class accepts:
# * The same arguments as ExecutedShellCommand (command, chdir, env)
# * A regex pattern with named capture groups (supports multi-line output)
# * A format that can be either:
#   - A Symbol: calls that method on the output (e.g., :strip, :upcase)
#   - A String: format string with named placeholders like '%{group_name}'
#
# The command is executed automatically during initialization, and the
# entire output (including multi-line output) is transformed in a single
# transformation operation using the format.
#
# The regex pattern can match across multiple lines. Use the multiline
# flag (m) or construct patterns that handle newlines appropriately.
#
# Basic usage with format string:
#
#   regex = /(?<name>\w+):(?<value>\d+)/
#   format_str = "Name: %{name}, Value: %{value}"
#   cmd = TransformedShellCommand.new("echo 'user:123'", regex: regex, format: format_str)
#   cmd.transformed_output  # => "Name: user, Value: 123"
#   cmd.result              # => original ExecutedShellCommand::Result
#
# Basic usage with Symbol:
#
#   cmd = TransformedShellCommand.new("echo '  hello  '", regex: /.*/, format: :strip)
#   cmd.transformed_output  # => "hello"
#
# Multi-line output example:
#
#   regex = /(?<first>\w+)\n(?<second>\w+)\n(?<third>\w+)/m
#   format_str = "%{first}-%{second}-%{third}"
#   cmd = TransformedShellCommand.new("echo -e 'one\ntwo\nthree'", regex: regex, format: format_str)
#   cmd.transformed_output  # => "one-two-three"
#
class TransformedShellCommand
  attr_reader :command, :env, :chdir, :regex, :format

  def initialize(command, regex:, format:, chdir: nil, env: {})
    @command = command
    @chdir = chdir
    @env = env
    @regex = regex && (regex.is_a?(Regexp) ? regex : Regexp.new(regex))
    @format = format
    @result = nil
    @transformed_output = nil
    execute_and_transform
  end

  ##
  # Returns the transformed output string.
  # The transformation is performed once during initialization and memoized.
  #
  attr_reader :transformed_output

  ##
  # Returns the original ExecutedShellCommand result.
  #
  def result
    @executed_command.result
  end

  # Convenience delegators to the original result:

  def stdout
    result.stdout
  end

  def stderr
    result.stderr
  end

  def exit_code
    result.exit_code
  end

  def success?
    result.success?
  end

  def failure?
    !result.success?
  end

  def duration
    result.duration
  end

  def started_at
    result.started_at
  end

  def finished_at
    result.finished_at
  end

  def pid
    result.pid
  end

  private

  ##
  # Execute the command and transform the output.
  #
  def execute_and_transform
    @executed_command = ExecutedShellCommand.new(@command, chdir: @chdir,
                                                           env: @env)
    @result = @executed_command.result
    @transformed_output = transform_output(@result.stdout)
  end

  ##
  # Transform the output using the regex and format.
  #
  # If format is a Symbol, calls that method on the value.
  # If format is a String, extracts named groups and applies the format string.
  # If the regex doesn't match or format is nil, returns the original value.
  #
  def transform_output(value)
    return value if value.nil? || value.empty?
    return value unless @format

    # If format is a Symbol, call that method on the value
    if @format.is_a?(Symbol)
      return value.send(@format)
    end

    # Extract named groups from the value using the regex
    named_groups = @regex && extract_named_groups(value, @regex)
    return value unless named_groups

    # Apply format string with named placeholders
    apply_format_string(@format, named_groups)
  rescue StandardError
    # On error, return original value
    value
  end

  ##
  # Extract named groups from a string using a regex pattern.
  #
  # Supports multi-line strings. The regex pattern should be constructed
  # to handle newlines (e.g., using the multiline flag 'm' or patterns
  # that explicitly match newlines).
  #
  # @param str [String] the string to match (can be multi-line)
  # @param pattern [Regexp] the regex pattern with named groups
  # @return [Hash<Symbol, String>, nil] hash of named groups, or nil if no match
  #
  def extract_named_groups(str, pattern)
    # Match against the entire string (including newlines)
    match = str.match(pattern)
    return nil unless match

    match.named_captures&.transform_keys(&:to_sym)
  end

  ##
  # Apply format string with named placeholders like '%{name}'.
  #
  # Replaces '%{group_name}' with the corresponding value from the named_groups hash.
  #
  # @param format_str [String] format string with '%{name}' placeholders
  # @param named_groups [Hash<Symbol, String>] hash of named groups
  # @return [String] formatted string
  #
  def apply_format_string(format_str, named_groups)
    result = format_str.dup

    # Replace each '%{name}' placeholder with the corresponding value
    named_groups.each do |key, value|
      placeholder = "%{#{key}}"
      result.gsub!(placeholder, value.to_s)
    end

    result
  end
end

# Test suite when running as a script
return if $PROGRAM_NAME != __FILE__

require 'bundler/setup'
Bundler.require(:default)

require 'minitest/autorun'

class TransformedShellCommandTest < Minitest::Test
  def test_basic_transformation
    regex = /(?<name>\w+):(?<value>\d+)/
    format_str = 'Name: %{name}, Value: %{value}'
    cmd = TransformedShellCommand.new(
      "echo 'user:123'",
      regex: regex,
      format: format_str
    )

    assert cmd.success?
    assert_equal "user:123\n", cmd.stdout
    assert_equal 'Name: user, Value: 123', cmd.transformed_output
  end

  def test_symbol_transform
    regex = /.*/
    cmd = TransformedShellCommand.new(
      "echo '  HELLO WORLD  '",
      regex: regex,
      format: :strip
    )

    assert cmd.success?
    assert_equal "  HELLO WORLD  \n", cmd.stdout
    assert_equal 'HELLO WORLD', cmd.transformed_output
  end

  def test_symbol_transform_upcase
    regex = /.*/
    cmd = TransformedShellCommand.new(
      "echo 'hello'",
      regex: regex,
      format: :upcase
    )

    assert cmd.success?
    assert_equal "hello\n", cmd.stdout
    assert_equal "HELLO\n", cmd.transformed_output
  end

  def test_no_match_returns_original
    regex = /(?<name>\w+):(?<value>\d+)/
    format_str = 'Name: %{name}, Value: %{value}'
    cmd = TransformedShellCommand.new(
      "echo 'no match here'",
      regex: regex,
      format: format_str
    )

    assert cmd.success?
    assert_equal "no match here\n", cmd.stdout
    assert_equal "no match here\n", cmd.transformed_output
  end

  def test_multiple_named_groups
    regex = /(?<year>\d{4})-(?<month>\d{2})-(?<day>\d{2})/
    format_str = 'Date: %{month}/%{day}/%{year}'
    cmd = TransformedShellCommand.new(
      "echo '2024-12-25'",
      regex: regex,
      format: format_str
    )

    assert cmd.success?
    assert_equal "2024-12-25\n", cmd.stdout
    assert_equal 'Date: 12/25/2024', cmd.transformed_output
  end

  def test_delegates_to_result
    regex = /(?<name>\w+)/
    format_str = '%{name}'
    cmd = TransformedShellCommand.new(
      "echo 'test'",
      regex: regex,
      format: format_str
    )

    assert_kind_of ExecutedShellCommand::Result, cmd.result
    assert_equal "test\n", cmd.stdout
    assert_equal 0, cmd.exit_code
    assert cmd.success?
    assert_kind_of Numeric, cmd.duration
    assert_kind_of Time, cmd.started_at
    assert_kind_of Time, cmd.finished_at
    assert_kind_of Integer, cmd.pid
  end

  def test_with_chdir
    regex = /(?<content>.*)/
    format_str = 'Content: %{content}'
    Dir.mktmpdir do |tmpdir|
      test_file = File.join(tmpdir, 'test.txt')
      File.write(test_file, 'hello world')

      cmd = TransformedShellCommand.new(
        'cat test.txt',
        regex: regex,
        format: format_str,
        chdir: tmpdir
      )

      assert cmd.success?
      assert_equal 'hello world', cmd.stdout
      assert_equal 'Content: hello world', cmd.transformed_output
    end
  end

  def test_with_env
    regex = /(?<var>\w+)=(?<val>\w+)/
    format_str = '%{var} is %{val}'
    cmd = TransformedShellCommand.new(
      "echo 'TEST_VAR=test_value'",
      regex: regex,
      format: format_str,
      env: { 'CUSTOM_VAR' => 'custom_value' }
    )

    assert cmd.success?
    assert_equal "TEST_VAR=test_value\n", cmd.stdout
    assert_equal 'TEST_VAR is test_value', cmd.transformed_output
  end

  def test_regex_as_string
    regex_str = '(?<name>\\w+):(?<value>\\d+)'
    format_str = 'Name: %{name}, Value: %{value}'
    cmd = TransformedShellCommand.new(
      "echo 'user:123'",
      regex: regex_str,
      format: format_str
    )

    assert cmd.success?
    assert_equal 'Name: user, Value: 123', cmd.transformed_output
  end

  def test_format_string_with_literal_text
    regex = /(?<num>\d+)/
    format_str = 'The number is %{num}!'
    cmd = TransformedShellCommand.new(
      "echo '42'",
      regex: regex,
      format: format_str
    )

    assert cmd.success?
    assert_equal "42\n", cmd.stdout
    assert_equal 'The number is 42!', cmd.transformed_output
  end

  def test_empty_output
    regex = /(?<name>\w+)/
    format_str = '%{name}'
    cmd = TransformedShellCommand.new(
      'true',
      regex: regex,
      format: format_str
    )

    assert cmd.success?
    assert_equal '', cmd.stdout
    assert_equal '', cmd.transformed_output
  end

  def test_multiple_placeholders_same_group
    regex = /(?<word>\w+)/
    format_str = '%{word} %{word} %{word}'
    cmd = TransformedShellCommand.new(
      "echo 'hello'",
      regex: regex,
      format: format_str
    )

    assert cmd.success?
    assert_equal "hello\n", cmd.stdout
    assert_equal 'hello hello hello', cmd.transformed_output
  end

  def test_multiline_output_single_transformation
    regex = /(?<first>\w+)\n(?<second>\w+)\n(?<third>\w+)/m
    format_str = '%{first}-%{second}-%{third}'
    cmd = TransformedShellCommand.new(
      "printf 'one\ntwo\nthree\n'",
      regex: regex,
      format: format_str
    )

    assert cmd.success?
    assert_equal "one\ntwo\nthree\n", cmd.stdout
    assert_equal 'one-two-three', cmd.transformed_output
  end

  def test_multiline_output_with_multiline_regex
    regex = /Name: (?<name>[\w\s]+)\nAge: (?<age>\d+)\nCity: (?<city>[\w\s]+)/m
    format_str = '%{name} (%{age}) from %{city}'
    cmd = TransformedShellCommand.new(
      "printf 'Name: John Doe\nAge: 30\nCity: New York\n'",
      regex: regex,
      format: format_str
    )

    assert cmd.success?
    assert_includes cmd.stdout, 'John Doe'
    assert_includes cmd.stdout, '30'
    assert_includes cmd.stdout, 'New York'
    # Remove trailing newline for comparison
    assert_equal 'John Doe (30) from New York', cmd.transformed_output.chomp
  end

  def test_multiline_output_symbol_transform
    regex = /.*/m
    cmd = TransformedShellCommand.new(
      "printf '  line1\n  line2\n  line3  \n'",
      regex: regex,
      format: :strip
    )

    assert cmd.success?
    assert_equal "  line1\n  line2\n  line3  \n", cmd.stdout
    # strip removes leading/trailing whitespace from entire string
    # Leading spaces from first line and trailing spaces/newline from last line are removed
    assert_equal "line1\n  line2\n  line3", cmd.transformed_output
  end

  def test_multiline_output_captures_spanning_lines
    regex = /Start: (?<start>.*?)End: (?<end>.*?)$/m
    format_str = 'From %{start} to %{end}'
    cmd = TransformedShellCommand.new(
      "printf 'Start: alpha\nbeta\ngamma\nEnd: delta\n'",
      regex: regex,
      format: format_str
    )

    assert cmd.success?
    assert_equal "From alpha\nbeta\ngamma\n to delta", cmd.transformed_output
  end

  def test_multiline_output_no_match_returns_original
    regex = /(?<name>\w+):(?<value>\d+)/
    format_str = 'Name: %{name}, Value: %{value}'
    cmd = TransformedShellCommand.new(
      "printf 'line1\nline2\nline3\n'",
      regex: regex,
      format: format_str
    )

    assert cmd.success?
    assert_equal "line1\nline2\nline3\n", cmd.stdout
    assert_equal "line1\nline2\nline3\n", cmd.transformed_output
  end
end
