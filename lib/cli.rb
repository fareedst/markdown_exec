# frozen_string_literal: true

# encoding=utf-8

# utility functions to provide CLI
#
module CLI
  # skip :reek:UtilityFunction
  def value_for_cli(value)
    case value.class.to_s
    when 'String'
      Shellwords.escape value
    when 'FalseClass', 'TrueClass'
      value ? 't' : 'f'
    else
      Shellwords.escape value.to_s
    end
  end
end
