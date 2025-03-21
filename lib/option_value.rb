#!/usr/bin/env -S bundle exec ruby
# frozen_string_literal: true

# encoding=utf-8

module MarkdownExec
  # OptionValue
  #
  # This class provides utilities to format option values for different contexts.
  # The `for_hash` method prepares the value to be used as a default in `env_str()`.
  # The `for_yaml` method prepares the value for output as a default in `list_default_yaml()`.
  #
  class OptionValue
    # Formats the value for use in a hash.
    def self.for_hash(value, default = nil)
      return default if value.nil?

      case value
      when String, Integer, Array, Hash
        value
      when TrueClass, FalseClass
        value ? true : false
      when ->(v) { v.respond_to?(:empty?) && v.empty? }
        default
      else
        value.to_s
      end
    end

    # Formats the value for output in YAML.
    def self.for_yaml(value, default = nil)
      return default if value.nil?

      case value
      when String
        "'#{value}'"
      when Integer
        value
      when TrueClass, FalseClass
        value ? true : false
      when ->(v) { v.respond_to?(:empty?) && v.empty? }
        default
      else
        value.to_s
      end
    end
  end
end

if $PROGRAM_NAME == __FILE__
  require 'minitest/autorun'

  class OptionValueTest < Minitest::Test
    def test_for_hash_with_string
      assert_equal 'sample', MarkdownExec::OptionValue.for_hash('sample')
    end

    def test_for_hash_with_integer
      assert_equal 42, MarkdownExec::OptionValue.for_hash(42)
    end

    def test_for_hash_with_boolean
      assert_equal true, MarkdownExec::OptionValue.for_hash(true)
      assert_equal false, MarkdownExec::OptionValue.for_hash(false)
    end

    def test_for_hash_with_empty_array
      assert_equal [], MarkdownExec::OptionValue.for_hash([], 'default')
    end

    def test_for_hash_with_empty_hash
      assert_equal({}, MarkdownExec::OptionValue.for_hash({}, 'default'))
    end

    def test_for_yaml_with_string
      assert_equal "'sample'", MarkdownExec::OptionValue.for_yaml('sample')
    end

    def test_for_yaml_with_integer
      assert_equal 42, MarkdownExec::OptionValue.for_yaml(42)
    end

    def test_for_yaml_with_boolean
      assert_equal true, MarkdownExec::OptionValue.for_yaml(true)
      assert_equal false, MarkdownExec::OptionValue.for_yaml(false)
    end

    def test_for_yaml_with_empty_value
      assert_equal 'default', MarkdownExec::OptionValue.for_yaml([], 'default')
    end
  end
end
