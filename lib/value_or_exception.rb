#!/usr/bin/env -S bundle exec ruby
# frozen_string_literal: true

# encoding=utf-8

# == ValueOrException
#
# Encapsulates either a valid String value or an exception Symbol,
# and provides methods to query and update the stored value.
#
# === Examples
#
#   obj = ValueOrException.new("foo")
#   obj.valid?       # => true
#   obj.exception?   # => false
#   obj.get          # => "foo"
#
#   obj.set(:error)  # now holds an exception
#   obj.valid?       # => false
#   obj.exception?   # => true
#   obj.get          # => :error
class ValueOrException
  # @return [String, Symbol] the stored value or exception
  attr_accessor :message
  attr_reader :value

  # @param [String, Symbol] val a valid string or an exception symbol
  # @raise [ArgumentError] if val is neither String nor Symbol
  def initialize(val, message = nil)
    validate!(val)
    @value = val
    @message = message
  end

  # @return [Boolean] true if the stored value is a Symbol (an exception)
  def exception?
    value.is_a?(Symbol)
  end

  # @return [Boolean] true if the stored value is a String (a valid value)
  def valid?
    !exception?
  end

  # Retrieve the current stored value or exception.
  #
  # @return [String, Symbol]
  def get
    valid? ? value : message
  end

  # Update the stored value or exception.
  #
  # @param [String, Symbol] new_val the new value or exception
  # @raise [ArgumentError] if new_val is neither String nor Symbol
  def set(new_val)
    validate!(new_val)
    @value = new_val
  end

  def to_s
    valid? ? value.to_s : message
  end

  private

  # Ensure the provided value is of an allowed type.
  #
  # @param [Object] val the value to check
  # @raise [ArgumentError] if val is not a String or Symbol
  def validate!(val)
    return if val.is_a?(String) || val.is_a?(Symbol)

    raise ArgumentError, "Expected a String or Symbol, got #{val.class}"
  end
end
