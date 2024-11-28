# frozen_string_literal: true

# encoding=utf-8

# Extends Ruby's native String class to include ANSI coloring functionality.
# Adds methods to apply RGB colors, named colors, and other formatting to strings.
class String
  # Handles dynamic method calls to create RGB colors.
  #
  # @param method_name [Symbol] The name of the method being called.
  # @param args [Array] The arguments passed to the method.
  # @param block [Proc] An optional block.
  # @return [String] The formatted string.
  def method_missing(method_name, *args, &block)
    case method_name.to_s
    when /^fg_bg_rgb_/
      bytes = $'.split('_')
      fg_bg_rgb_color(bytes[0..2].join(';'), bytes[3..5].join(';'))
    when /^fg_bg_rgbh_/
      hex_to_fg_bg_rgb($')
    when /^fg_rgb_/
      fg_rgb_color($'.gsub('_', ';'))
    when /^fg_rgbh_/
      hex_to_rgb($')

    when 'to_a', 'to_ary', 'to_hash', 'to_int', 'to_io', 'to_regexp'
      nil
    else
      super
    end
  end

  # Generates an ANSI control sequence for the string.
  #
  # @return [String] The string wrapped in an ANSI control sequence.
  def ansi_control_sequence
    "\033[#{self}\033[0m"
  end

  # # Applies a 24-bit RGB background color to the string.
  # #
  # # @param rgb [String] The RGB color, expressed as a string like "1;2;3".
  # # @return [String] The string with the applied RGB foreground color.
  # def bg_rgb_color(rgb)
  #   "48;2;#{rgb}m#{self}".ansi_control_sequence
  # end

  # Applies a 24-bit RGB foreground color to the string.
  #
  # @param rgb [String] The RGB color, expressed as a string like "1;2;3".
  # @return [String] The string with the applied RGB foreground color.
  def fg_bg_rgb_color(fg_rgb, bg_rgb)
    "38;2;#{fg_rgb}m\033[48;2;#{bg_rgb}m#{self}".ansi_control_sequence
  end

  # Applies a 24-bit RGB foreground color to the string.
  #
  # @param rgb [String] The RGB color, expressed as a string like "1;2;3".
  # @return [String] The string with the applied RGB foreground color.
  def fg_rgb_color(rgb)
    "38;2;#{rgb}m#{self}".ansi_control_sequence
  end

  # Converts hex color codes to RGB and applies them to the string.
  #
  # @param hex_str [String] The RGB color, expressed as a hex string like "FF00FF".
  # @return [String] The string with the applied RGB foreground color.
  def hex_to_fg_bg_rgb(hex_str)
    values = hex_str.split('_').map { |hex| hex.to_i(16).to_s }
    fg_bg_rgb_color(
      values[0..2].join(';'),
      values[3..5].join(';')
    )
  end

  # Converts hex color codes to RGB and applies them to the string.
  #
  # @param hex_str [String] The RGB color, expressed as a hex string like "FF00FF".
  # @return [String] The string with the applied RGB foreground color.
  def hex_to_rgb(hex_str)
    fg_rgb_color(
      hex_str.split('_').map { |hex| hex.to_i(16).to_s }.join(';')
    )
  end

  # Provides a plain, unmodified version of the string.
  #
  # @return [String] The original string.
  def plain
    self
  end

  # A collection of methods for applying named colors.
  #
  # For example, #black applies a black foreground color to the string.
  # These are provided for convenience and easy readability.

  def black;   "30m#{self}".ansi_control_sequence; end
  def bred;    "1;31m#{self}".ansi_control_sequence; end
  def bgreen;  "1;32m#{self}".ansi_control_sequence; end
  def byellow; "1;33m#{self}".ansi_control_sequence; end
  def magenta; "35m#{self}".ansi_control_sequence; end
  def cyan;    "36m#{self}".ansi_control_sequence; end
  def white;   "37m#{self}".ansi_control_sequence; end
  def bwhite;  "1;37m#{self}".ansi_control_sequence; end

  # More named colors using RGB hex values
  def blue;    fg_rgbh_00_00_FF; end
  def green;   fg_rgbh_00_FF_00; end
  def indigo;  fg_rgbh_4B_00_82; end
  def orange;  fg_rgbh_FF_7F_00; end
  def red;     fg_rgbh_FF_00_00; end
  def violet;  fg_rgbh_94_00_D3; end
  def yellow;  fg_rgbh_FF_FF_00; end

  def x
    pp [__LINE__, caller[1]]; binding.irb
  end

  # graphics modes
  def bold;             x; "\033[1m#{self}\033[22m"; end
  def bold_italic;      x; "\033[1m\033[3m#{self}\033[22m\033[23m"; end
  def bold_underline;   x; "\033[1m\033[4m#{self}\033[22m\033[24m"; end
  def dim;              x; "\033[2m#{self}\033[22m"; end
  def italic;           x; "\033[3m#{self}\033[23m"; end
  def underline;        x; "\033[4m#{self}\033[24m"; end
  def underline_italic; x; "\033[4m\033[3m#{self}\033[23m\033[24m"; end
  def blinking;         x; "\033[5m#{self}\033[25m"; end
  def inverse;          x; "\033[7m#{self}\033[27m"; end
  def hidden;           x; "\033[8m#{self}\033[28m"; end
  def strikethrough;    x; "\033[9m#{self}\033[29m"; end
end
