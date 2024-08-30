# frozen_string_literal: true

# encoding=utf-8

# utility functions to read environment variables
#
module Env
  # :reek:BooleanParameter
  # :reek:DataClump
  # :reek:NilCheck
  # :reek:UtilityFunction
  def env_bool(name, default: false)
    return default if name.nil? || (val = ENV.fetch(name, nil)).nil?
    return false if val.empty? || val == '0'

    true
  end

  # :reek:UtilityFunction
  def env_bool_false(name)
    !(val = name && ENV.fetch(name, nil)).nil? && !(val.empty? || val == '0')
  end

  # skip :reek:DataClump
  # skip :reek:NilCheck
  # skip :reek:UtilityFunction
  def env_int(name, default: 0)
    return default if name.nil? || (val = ENV.fetch(name, nil)).nil?
    return default if val.empty?

    val.to_i
  end

  # skip :reek:DataClump
  # skip :reek:NilCheck
  # skip :reek:UtilityFunction
  def env_str(name, default: '')
    return default if name.nil? || (val = ENV.fetch(name, nil)).nil?

    val || default
  end
end
