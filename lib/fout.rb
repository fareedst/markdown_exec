#!/usr/bin/env ruby
# frozen_string_literal: true

# encoding=utf-8

# stdout manager
#
# module FOut
class FOut
  def initialize(config)
    @config = config
  end

  def approved_fout?(level)
    level <= fetch_display_level
  end

  # integer value for comparison
  #
  def fetch_display_level
    @config.fetch(:display_level, 1)
  end

  # integer value for comparison
  #
  def fetch_display_level_xbase_prefix
    @config.fetch(:level_xbase_prefix, '')
  end

  # standard output; not for debug
  #
  def fout(str)
    puts str
  end

  def fout_list(str)
    puts str
  end

  def fout_section(name, data)
    puts "# #{name}"
    puts data.to_yaml
  end

  # display output at level or lower than filter (DISPLAY_LEVEL_DEFAULT)
  #
  def lout(str, level: DISPLAY_LEVEL_BASE)
    return unless approved_fout?(level)

    fout level == DISPLAY_LEVEL_BASE ? str : fetch_display_level_xbase_prefix + str
  end
end
