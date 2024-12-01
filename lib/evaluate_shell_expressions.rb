#!/usr/bin/env bundle exec ruby
# frozen_string_literal: true

# encoding=utf-8

require 'open3'

def evaluate_shell_expressions(initial_code, expressions, shell: '/bin/bash',
                               key_format: "%%<%s>",
                               initial_code_required: false)
  # !!p initial_code expressions key_format shell
  return if (initial_code_required && (initial_code.nil? || initial_code.empty?)) ||
            expressions.nil? || expressions.empty? ||
            key_format.nil? || key_format.empty?

  # token to separate output
  token = "__TOKEN__#{Time.now.to_i}__"

  # Construct a single shell script
  script = initial_code.dup
  expressions.each_with_index do |(key, expression), index|
    script << "\necho #{token}#{index}\n"
    script << expression << "\n"
  end

  # Execute
  stdout_str, stderr_str, status = Open3.capture3(shell, "-c", script)

  unless status.success?
    raise "Shell script execution failed: #{stderr_str}"
  end

  # Extract output for expressions
  result_hash = {}
  stdout_str.split(/\n?#{token}\d+\n/)[1..-1].tap do |output_parts|
    expressions.each_with_index do |(key, _expression), index|
      result_hash[sprintf(key_format, key)] = output_parts[index].chomp
    end
  end

  result_hash
end

return if $PROGRAM_NAME != __FILE__

require 'bundler/setup'
Bundler.require(:default)

require 'minitest/autorun'
require 'open3'

class TestShellExpressionEvaluator < Minitest::Test
  def setup
    @initial_code = <<~BASH
      #!/bin/sh
      echo "Initial setup..."
    BASH
  end

  def test_single_expression
    expressions = { "greeting" => "echo 'Hello, World!'" }
    result = evaluate_shell_expressions(@initial_code, expressions)

    assert_equal "Hello, World!", result["%<greeting>"]
  end

  def test_multiple_expressions
    expressions = {
      "greeting" => "echo 'Hello, World!'",
      "date" => "date +%Y-%m-%d",
      "kernel" => "uname -r"
    }
    result = evaluate_shell_expressions(@initial_code, expressions)

    assert_equal "Hello, World!", result["%<greeting>"]
    assert_match /\d{4}-\d{2}-\d{2}/, result["%<date>"]
    assert_match /\d+\.\d+\.\d+/, result["%<kernel>"]
  end

  def test_empty_expressions_list
    expressions = {}
    result = evaluate_shell_expressions(@initial_code, expressions)

    assert_nil result
  end

  def test_invalid_expression
    expressions = { "invalid" => "invalid_command" }

    error = assert_raises(RuntimeError) do
      evaluate_shell_expressions(@initial_code, expressions)
    end

    assert_match /Shell script execution failed/, error.message
  end

  def test_initial_code_execution
    initial_code = <<~BASH
      #!/bin/sh
      echo "Custom setup message"
    BASH
    expressions = { "test" => "echo Test after initial setup" }

    result = evaluate_shell_expressions(initial_code, expressions)

    assert_equal "Test after initial setup", result["%<test>"]
  end

  def test_large_number_of_expressions
    expressions = (1..100).map { |i|
      ["expr_#{i}", "echo Expression #{i}"]
    }.to_h

    result = evaluate_shell_expressions(@initial_code, expressions)

    expressions.each_with_index do |(key, _expression), index|
      assert_equal "Expression #{index + 1}", result["%<#{key}>"]
    end
  end
end
