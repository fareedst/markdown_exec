# frozen_string_literal: true

# encoding=utf-8

require 'json'
require 'yaml'

require_relative 'env'
include Env # rubocop:disable Style/MixinUsage

# add function for in-line tap
#
module Tap
  $pdebug = env_bool 'MDE_DEBUG'

  def tap_config(enable)
    $pdebug = enable
  end

  def tap_inspect(format: nil, name: 'return')
    return self unless $pdebug

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
