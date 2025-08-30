#!/usr/bin/env bundle exec ruby
# frozen_string_literal: true

# encoding=utf-8

require 'open3'

class EvaluateShellExpression
  StatusFail = :script_execution_failed unless const_defined?(:StatusFail)
end

def evaluate_shell_expressions(initial_code, expressions, shell: '/bin/bash',
                               initial_code_required: false,
                               occurrence_expressions: nil)
  # !!p initial_code expressions key_format shell
  return if (initial_code_required && (initial_code.nil? || initial_code.empty?)) ||
            expressions.nil? || expressions.empty?

  # token to separate output
  token = "__TOKEN__#{Time.now.to_i}__"

  # Construct a single shell script
  script = initial_code.dup
  expressions.each_with_index do |(_key, expression), index|
    script << "\necho #{token}#{index}\n"
    script << expression << "\n"
  end
  wwt :eval, 'script:', script

  # Execute
  stdout_str, _, status = Open3.capture3(shell, '-c', script)

  unless status.success?
    return EvaluateShellExpression::StatusFail
  end

  # Extract output for expressions
  result_hash = {}
  part = stdout_str.split(/\n?#{token}\d+\n/)
  unless part.empty?
    part[1..-1].tap do |output_parts|
      expressions.each_with_index do |(key, _expression), index|
        result_hash[occurrence_expressions[key]] = output_parts[index].chomp
      end
    end
  end

  result_hash
rescue StandardError
  ww $@, $!, caller.deref
  ww initial_code, expressions
  raise StandardError, $!
end

return if $PROGRAM_NAME != __FILE__

require 'bundler/setup'
Bundler.require(:default)

require 'minitest/autorun'

class TestShellExpressionEvaluator < Minitest::Test
  def setup
    @initial_code = <<~BASH
      #!/bin/sh
      echo "Initial setup..."
    BASH
  end

  def test_single_expression
    expressions = { 'greeting' => "echo 'Hello, World!'" }
    occurrence_expressions = { 'greeting' => '%<greeting>' }
    result = evaluate_shell_expressions(
      @initial_code, expressions,
      occurrence_expressions: occurrence_expressions
    )

    assert_equal 'Hello, World!', result['%<greeting>']
  end

  def test_multiple_expressions
    expressions = {
      'greeting' => "echo 'Hello, World!'",
      'date' => 'date +%Y-%m-%d',
      'kernel' => 'uname -r'
    }
    occurrence_expressions = {
      'date' => '%<date>',
      'greeting' => '%<greeting>',
      'kernel' => '%<kernel>'
    }
    result = evaluate_shell_expressions(
      @initial_code, expressions,
      occurrence_expressions: occurrence_expressions
    )

    assert_equal 'Hello, World!', result['%<greeting>']
    assert_match(/\d{4}-\d{2}-\d{2}/, result['%<date>'])
    assert_match(/\d+\.\d+\.\d+/, result['%<kernel>'])
  end

  def test_empty_expressions_list
    expressions = {}
    occurrence_expressions = {}
    result = evaluate_shell_expressions(
      @initial_code, expressions,
      occurrence_expressions: occurrence_expressions
    )

    assert_nil result
  end

  def test_invalid_expression
    expressions = { 'invalid' => 'invalid_command' }
    occurrence_expressions = {}
    result = evaluate_shell_expressions(
      @initial_code, expressions,
      occurrence_expressions: occurrence_expressions
    )

    assert_equal EvaluateShellExpression::StatusFail, result
  end

  def test_initial_code_execution
    initial_code = <<~BASH
      #!/bin/sh
      echo "Custom setup message"
    BASH
    expressions = { 'test' => 'echo Test after initial setup' }
    occurrence_expressions = { 'test' => '%<test>' }
    result = evaluate_shell_expressions(
      @initial_code, expressions,
      occurrence_expressions: occurrence_expressions
    )

    assert_equal 'Test after initial setup', result['%<test>']
  end

  def test_large_number_of_expressions
    expressions = (1..100).to_h do |i|
      ["expr_#{i}", "echo Expression #{i}"]
    end
    occurrence_expressions = (1..100).to_h do |i|
      ["expr_#{i}", "%<expr_#{i}>"]
    end
    result = evaluate_shell_expressions(
      @initial_code, expressions,
      occurrence_expressions: occurrence_expressions
    )

    expressions.each_with_index do |(key, _expression), index|
      assert_equal "Expression #{index + 1}", result["%<#{key}>"]
    end
  end
end
