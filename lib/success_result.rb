#!/usr/bin/env -S bundle exec ruby
# frozen_string_literal: true

# encoding=utf-8

# frozen_string_literal: true

require 'singleton'

##
# SuccessResult represents a successful outcome when no specific result value is produced.
#
# This class follows the Null Object pattern for successful cases, ensuring a consistent
# interface with methods such as #success? and #failure?. It is implemented as a singleton,
# meaning there is only one instance of SuccessResult available.
#
# Example:
#   result = SomeService.call
#   if result.success?
#     # proceed knowing the operation succeeded
#   else
#     # handle failure
#   end
#
class SuccessResult
  include Singleton

  ##
  # Indicates that the result is a success.
  #
  # @return [Boolean] always true for SuccessResult
  def success?
    true
  end

  ##
  # Indicates that the result is not a failure.
  #
  # @return [Boolean] always false for SuccessResult
  def failure?
    false
  end

  ##
  # Provides a default message for the successful result.
  #
  # @return [String] a message indicating success
  def message
    'Success'
  end

  ##
  # Returns a string representation of this SuccessResult.
  #
  # @return [String]
  def to_s
    'SuccessResult'
  end
end

# Default instance for ease-of-use.
DEFAULT_SUCCESS_RESULT = SuccessResult.instance

return unless $PROGRAM_NAME == __FILE__

require 'bundler/setup'
Bundler.require(:default)

require 'minitest/autorun'
require 'mocha/minitest'

require_relative 'ww'

##
# Tests for the SuccessResult class.
#
# This suite verifies that the SuccessResult singleton behaves as expected:
# - It is a singleton (all calls to SuccessResult.instance return the same object)
# - The #success? method returns true and #failure? returns false
# - The default message and string representation are correct.
#
class SuccessResultTest < Minitest::Test
  def test_singleton
    instance1 = SuccessResult.instance
    instance2 = SuccessResult.instance
    assert_same instance1, instance2, "Expected the singleton instances to be identical"
  end

  def test_success_method
    sr = SuccessResult.instance
    assert sr.success?, "Expected success? to return true"
  end

  def test_failure_method
    sr = SuccessResult.instance
    refute sr.failure?, "Expected failure? to return false"
  end

  def test_message
    sr = SuccessResult.instance
    assert_equal 'Success', sr.message, "Expected message to be 'Success'"
  end

  def test_to_s
    sr = SuccessResult.instance
    assert_equal 'SuccessResult', sr.to_s, "Expected to_s to return 'SuccessResult'"
  end

  def test_default_success_result_constant
    assert_same SuccessResult.instance, DEFAULT_SUCCESS_RESULT, "Expected DEFAULT_SUCCESS_RESULT to be the same singleton instance"
  end
end
