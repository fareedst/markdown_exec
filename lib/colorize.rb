# frozen_string_literal: true

# encoding=utf-8

class String
  alias_method :original_method_missing, :method_missing

  def method_missing(method_name, *args, &block)
    if /^fg_rgb_/ =~ method_name.to_s
      fg_rgb_color($'.gsub('_', ';'))
    else
      original_method_missing(method_name, *args, &block)
    end
  end

  # control sequence with reset
  #
  def ansi_control_sequence
    "\033[#{self}\033[0m"
  end

  # use 24-bit RGB foreground color spec
  # ex: 1;2;3
  #
  def fg_rgb_color(rgb)
    "38;2;#{rgb}m#{self}".ansi_control_sequence
  end

  def plain
    self
  end

  # named colors
  #
  def black
    "30m#{self}".ansi_control_sequence
  end

  def red
    "31m#{self}".ansi_control_sequence
  end

  def bred
    "1;31m#{self}".ansi_control_sequence
  end

  def green
    "32m#{self}".ansi_control_sequence
  end

  def bgreen
    "1;32m#{self}".ansi_control_sequence
  end

  def yellow
    "33m#{self}".ansi_control_sequence
  end

  def byellow
    "1;33m#{self}".ansi_control_sequence
  end

  def blue
    "34m#{self}".ansi_control_sequence
  end

  def magenta
    "35m#{self}".ansi_control_sequence
  end

  def cyan
    "36m#{self}".ansi_control_sequence
  end

  def white
    "37m#{self}".ansi_control_sequence
  end

  def bwhite
    "1;37m#{self}".ansi_control_sequence
  end
end
