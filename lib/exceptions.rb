#!/usr/bin/env ruby
# frozen_string_literal: true

# encoding=utf-8

module Exceptions
  def self.error_handler(name = '', opts = {}, backtrace: $@, format_string: "\nError: %{name} -- %{message}", color_symbol: :red, take_count: 16)
    warn(error = format(format_string,
                        { name: name, message: $! }).send(color_symbol))
    if backtrace
      warn(backtrace.select do |s|
             s.include? 'markdown_exec'
           end.reject { |s| s.include? 'vendor' }.take(take_count).map.with_index { |line, ind| " *   #{ind}: #{line}" })
    end

    binding.pry if $tap_enable
    raise ArgumentError, error unless opts.fetch(:abort, true)

    exit 1
  end

  def self.warn_format(message = '', opts = {})
    warn(
      error = format(
        opts.fetch(:format_string, "\nError: %{error}"),
        { error: message }
      ).send(opts.fetch(:color_symbol, :yellow))
    )
    # warn(caller.take(4).map.with_index { |line, ind| " *   #{ind}: #{line}" })

    binding.pry if $tap_enable
    raise ArgumentError, error unless opts.fetch(:abort, false)

    exit 1
  end
end
