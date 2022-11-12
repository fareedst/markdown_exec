# frozen_string_literal: true

# encoding=utf-8

require 'json'
require 'yaml'

require_relative 'env'
require_relative 'object_present'

include Env

# rubocop:disable Metrics/ParameterLists

## application-level debug control
#
module Tap
  DN = 'return'
  NONE = 0x0
  T1 = 1 # RESULT
  T2 = 2 # CONTEXT
  T3 = 4 # MONITOR
  T4 = 8 # DUMP
  ALL2 = 0x77
  ALL = 0xFF
  TDD = 0x11
  TB1 = 0x22
  TB2 = 0x44
  TB3 = 0x88
  TD = 0x0F
  TD0 = 0x01
  TD1 = 0x02
  TD2 = 0x04
  TP = 0xF0
  TP0 = 0x10
  TP1 = 0x20
  TP2 = 0x40

  # cast with message per tap_inspect type
  # type: message
  #
  CVT = {
    json: :to_json,
    string: :to_s,
    yaml: :to_yaml,
    else: :inspect
  }.freeze

  $tap_enable = false
  $tap_mask = ALL2

  def tap_config(enable: true, envvar: nil, value: nil)
    $tap_enable = false
    if envvar
      $tap_enable = (env_int envvar).positive?
      $tap_mask = ALL2 if $tap_enable
    elsif value
      $tap_mask = value.to_i
      $tap_enable = $tap_mask.positive?
    elsif enable
      $tap_mask = ALL2
      $tap_enable = true
    end
    # puts "$tap_enable: #{$tap_enable}"
    # puts "$tap_mask: #{$tap_mask.to_s(2)}"
    self
  end

  def tap_inspect(name_ = nil, caller0: nil, mask: TDD, name: DN, source: nil, type: nil)
    return self unless $tap_enable
    return self unless (mask & $tap_mask).positive?

    fn = CVT.fetch(type, CVT[:else])
    outs = []
    outs.push(source.to_s) if source.present?

    vs = (caller0 || caller[0]).scan(/in `?(\S+)'$/).fetch(0, []).fetch(0, '')
    outs.push("#{vs}()") if vs.present?

    outs.push(tap_named_value(name_ || name, method(fn).call))

    $stdout.puts(outs.join(' ')) if outs.length.positive?
    self
  end

  def tap_print(mask: TDD)
    return self unless $tap_enable
    return self unless (mask & $tap_mask).positive?

    $stdout.print self
    self
  end

  def tap_puts(name_ = nil, mask: TDD, name: nil)
    return self unless $tap_enable
    return self unless (mask & $tap_mask).positive?

    $stdout.puts tap_named_value(name_ || name, self)
    self
  end

  def tap_yaml(name_ = nil, caller0: nil, mask: TDD, name: DN, source: nil)
    tap_inspect name_, caller0: (caller0 || caller[0]), mask: mask, name: name, source: source, type: :yaml
  end

  private

  def tap_named_value(name, value)
    if name.present?
      "#{name}: #{value}"
    else
      value.to_s
    end
  end
end

# rubocop:enable Metrics/ParameterLists
