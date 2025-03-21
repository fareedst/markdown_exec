#!/usr/bin/env -S bundle exec ruby
# frozen_string_literal: true

# encoding=utf-8

##
# NullResult represents a fallback object returned when a valid result cannot be produced.
#
# This class implements the Null Object pattern and can optionally carry additional
# failure details such as a custom message and a data payload.
#
# Example:
#   result = SomeService.call
#
#   if result.failure?
#     puts "Error: #{result.message}"
#     puts "Details: #{result.data.inspect}" if result.data
#   end
#
class NullResult
  ##
  # Initializes a new NullResult.
  #
  # @param message [String] a textual description of the failure (default: 'No valid result available')
  # @param data [Hash, nil] additional structured data conveying details of the failure (default: nil)
  def initialize(message: 'No valid result available', data: nil)
    @message = message
    @data = data
  end

  ##
  # Indicates that the result is a failure.
  #
  # @return [Boolean] always true
  def failure?
    true
  end

  ##
  # Indicates that the result is not a success.
  #
  # @return [Boolean] always false
  def success?
    false
  end

  ##
  # Returns the failure message.
  #
  # @return [String] the message describing the failure
  def message
    @message
  end

  ##
  # Returns additional failure details.
  #
  # @return [Hash, nil] structured data with failure details
  def data
    @data
  end

  ##
  # Returns a string representation of the NullResult.
  #
  # @return [String]
  def to_s
    "NullResult(message: #{@message.inspect}, data: #{@data.inspect})"
  end
end

# A default instance for cases where no extra details are required.
DEFAULT_NULL_RESULT = NullResult.new

return unless $PROGRAM_NAME == __FILE__

require 'bundler/setup'
Bundler.require(:default)

require 'minitest/autorun'
require 'mocha/minitest'

require_relative 'ww'

##
# Tests for the NullResult class.
#
# This suite verifies that the default and custom initialization
# of NullResult work as expected and that the public interface
# (e.g. #message, #data, #success?, #failure?, and #to_s) behaves correctly.
#
class NullResultTest < Minitest::Test
  def test_default_instance
    nr = NullResult.new
    assert_equal 'No valid result available', nr.message, 'Default message mismatch'
    assert_nil nr.data, 'Default data should be nil'
    refute nr.success?, 'Default instance should not be a success'
    assert nr.failure?, 'Default instance should be a failure'
    assert_match /NullResult/, nr.to_s, 'to_s should include the class name'
  end

  def test_custom_message
    custom_message = 'Custom error message'
    nr = NullResult.new(message: custom_message)
    assert_equal custom_message, nr.message, 'Custom message mismatch'
    assert_nil nr.data, 'Data should remain nil when not provided'
  end

  def test_custom_data
    custom_data = { error: 'invalid', code: 404 }
    nr = NullResult.new(data: custom_data)
    assert_equal custom_data, nr.data, 'Custom data mismatch'
    assert_equal 'No valid result available', nr.message, 'Default message expected'
  end

  def test_custom_message_and_data
    custom_message = 'Error occurred'
    custom_data = { reason: 'not_found' }
    nr = NullResult.new(message: custom_message, data: custom_data)
    assert_equal custom_message, nr.message, 'Custom message mismatch'
    assert_equal custom_data, nr.data, 'Custom data mismatch'
  end

  def test_to_s_format
    custom_message = 'Error occurred'
    custom_data = { a: 1, b: 2 }
    nr = NullResult.new(message: custom_message, data: custom_data)
    expected = "NullResult(message: #{custom_message.inspect}, data: #{custom_data.inspect})"
    assert_equal expected, nr.to_s, 'String representation does not match expected format'
  end
end
