# frozen_string_literal: true

# encoding=utf-8

require 'json'
require 'yaml'

require_relative 'env'
include Env

## application-level debug control
#
module Tap
  $tap_enable = env_bool 'TAP_DEBUG'

  def tap_config(enable: nil, envvar: nil, value: nil)
    $tap_enable = if envvar
                    env_bool envvar
                  elsif value
                    value.to_i != 0
                  elsif enable
                    enable
                  end
  end

  def tap_inspect(format: nil, name: 'return')
    return self unless $tap_enable

    cvt = {
      json: :to_json,
      string: :to_s,
      yaml: :to_yaml,
      else: :inspect
    }
    fn = cvt.fetch(format, cvt[:else])

    puts "-> #{caller[0].scan(/in `?(\S+)'$/)[0][0]}()" \
         " #{name}: #{method(fn).call}"

    self
  end
end
