#!/usr/bin/env -S bundle exec ruby
# frozen_string_literal: true

# encoding=utf-8

ALL = [
  BASH = 'bash',
  FISH = 'fish',
  SH = 'sh'
].freeze

# Encapsulates the result of executing a system command, storing its output,
# exit status, and any number of additional, arbitrary attributes.
#
# @example
#   result = CommandResult.new(stdout: output, exit_status: $?.exitstatus,
#                              duration: 1.23)
#   result.stdout        # => output
#   result.exit_status   # => 0
#   result.duration      # => 1.23
#   result.new_field = 42
#   result.new_field     # => 42
#   result.success?      # => true
class CommandResult
  ALL = [
    EXIT_STATUS_OK = 0,
    EXIT_STATUS_FAIL = 127,
    EXIT_STATUS_REQUIRED_EMPTY = 248
  ].freeze

  # @param attributes [Hash{Symbol=>Object}] initial named attributes
  def initialize(**attributes)
    @attributes = {
      exit_status: EXIT_STATUS_OK,
      stdout: '',
      warning: ''
    }.merge(attributes)
  end

  def failure?
    !success?
  end

  # @return [Boolean] true if the exit status is zero
  def success?
    exit_status.zero?
  end

  def new_lines
    value = @attributes[:new_lines] || []
    ww caller.deref[0..4], value
    value
  end

  def stdout
    @attributes[:stdout]
  end

  def transformed
    @attributes[:transformed]
  end

  # # trap assignment to new_lines
  # def new_lines=(value)
  #   ww caller.deref[0..4], value
  #   @attributes[:new_lines] = value
  # end

  def method_missing(name, *args)
    key = name.to_s.chomp('=').to_sym

    if name.to_s.end_with?('=') # setter
      @attributes[key] = args.first
    elsif attribute?(name) # getter
      @attributes[name]
    else
      super
    end
  end

  def respond_to_missing?(name, include_private = false)
    key = name.to_s.chomp('=').to_sym
    attribute?(key) || super
  end

  private

  def attribute?(name)
    @attributes.key?(name)
  end
end
