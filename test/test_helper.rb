# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path('../lib', __dir__)
require 'markdown_exec'

require 'minitest/autorun'

module Minitest
  # ensures all tests run in verbose mode by default
  def self.plugin_verbose_init(options)
    self.reporter << Minitest::Reporter.new(options[:io], true)
  end
end
