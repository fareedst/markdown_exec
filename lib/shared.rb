# frozen_string_literal: true

# encoding=utf-8

require 'shellwords'

public

# skip :reek:UtilityFunction
def value_for_cli(value)
  case value.class.to_s
  when 'String'
    Shellwords.escape value
  when 'FalseClass', 'TrueClass'
    value ? '1' : '0'
  else
    Shellwords.escape value.to_s
  end
end
