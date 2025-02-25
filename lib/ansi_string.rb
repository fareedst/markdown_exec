# frozen_string_literal: true

# encoding=utf-8

# Extends Ruby's native String class to include ANSI coloring functionality.
# Adds methods to apply RGB colors, named colors, and other formatting to strings.
class AnsiString < String
  # Handles dynamic method calls to create RGB colors.
  #
  # @param method_name [Symbol] The name of the method being called.
  # @param args [Array] The arguments passed to the method.
  # @param block [Proc] An optional block.
  # @return [AnsiString] The formatted string.
  def method_missing(method_name, *args, &block)
    if dynamic_color_method?(method_name)
      case method_name.to_s
      when /^ansi_/
        segments = $'.split('__')
        codes = ''
        segments[0..-2].each do |segment|
          codes += "\033[#{segment.split('_').join(';')}m"
        end
        codes += self.to_s
        codes += "\033[#{segments.last.split('_').join(';')}m"
        self.class.new(codes)
      when /^fg_bg_rgb_/
        bytes = $'.split('_')
        fg_bg_rgb_color(bytes[0..2].join(';'), bytes[3..5].join(';'))
      when /^fg_bg_rgbh_/
        hex_to_fg_bg_rgb($')
      when /^fg_rgb_/
        fg_rgb_color($'.gsub('_', ';'))
      when /^fg_rgbh_/
        hex_to_rgb($')
      else
        super
      end
    else
      super
    end
  end

  # Checks if the AnsiString instance responds to a particular method.
  #
  # @param method_name [Symbol] The name of the method being checked.
  # @param include_private [Boolean] Whether to include private methods in the check.
  # @return [Boolean] True if the method is supported, otherwise false.
  def respond_to_missing?(method_name, include_private = false)
    dynamic_color_method?(method_name) || super
  end

  # Generates an ANSI control sequence for the string.
  #
  # @return [AnsiString] The string wrapped in an ANSI control sequence.
  def ansi_control_sequence
    self.class.new("\033[#{self}\033[0m")
  end

  # Applies a 24-bit RGB foreground and background color to the string.
  #
  # @param fg_rgb [String] The RGB foreground color, expressed as a string like "1;2;3".
  # @param bg_rgb [String] The RGB background color, expressed as a string like "4;5;6".
  # @return [AnsiString] The string with the applied RGB foreground and background colors.
  def fg_bg_rgb_color(fg_rgb, bg_rgb)
    self.class.new("38;2;#{fg_rgb}m\033[48;2;#{bg_rgb}m#{self}").ansi_control_sequence
  end

  # Applies a 24-bit RGB foreground color to the string.
  #
  # @param rgb [String] The RGB color, expressed as a string like "1;2;3".
  # @return [AnsiString] The string with the applied RGB foreground color.
  def fg_rgb_color(rgb)
    self.class.new("38;2;#{rgb}m#{self}").ansi_control_sequence
  end

  # Converts hex color codes to RGB and applies them to the string.
  #
  # @param hex_str [String] The RGB color, expressed as a hex string like "FF00FF".
  # @return [AnsiString] The string with the applied RGB foreground color.
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
  # @return [AnsiString] The string with the applied RGB foreground color.
  def hex_to_rgb(hex_str)
    self.class.new(
      fg_rgb_color(
        hex_str.split('_').map { |hex| hex.to_i(16).to_s }.join(';')
      )
    )
  end

  # Provides a plain, unmodified version of the string.
  #
  # @return [AnsiString] The original string.
  def plain
    self.class.new(self)
  end

  # A collection of methods for applying named colors.
  #
  # For example, #black applies a black foreground color to the string.
  # These are provided for convenience and easy readability.
  def black;   self.class.new("30m#{self}").ansi_control_sequence; end
  def bred;    self.class.new("1;31m#{self}").ansi_control_sequence; end
  def bgreen;  self.class.new("1;32m#{self}").ansi_control_sequence; end
  def byellow; self.class.new("1;33m#{self}").ansi_control_sequence; end
  def magenta; self.class.new("35m#{self}").ansi_control_sequence; end
  def cyan;    self.class.new("36m#{self}").ansi_control_sequence; end
  def white;   self.class.new("37m#{self}").ansi_control_sequence; end
  def bwhite;  self.class.new("1;37m#{self}").ansi_control_sequence; end

  # More named colors using RGB hex values
  def blue;    fg_rgbh_00_00_FF; end
  def green;   fg_rgbh_00_FF_00; end
  def indigo;  fg_rgbh_4B_00_82; end
  def orange;  fg_rgbh_FF_7F_00; end
  def red;     fg_rgbh_FF_00_00; end
  def violet;  fg_rgbh_94_00_D3; end
  def yellow;  fg_rgbh_FF_FF_00; end

  # Graphics modes
  def bold; self.class.new("\033[1m#{self}\033[22m"); end

  def bold_italic;
    self.class.new("\033[1m\033[3m#{self}\033[22m\033[23m");
  end

  def bold_underline;
    self.class.new("\033[1m\033[4m#{self}\033[22m\033[24m");
  end

  def dim;              self.class.new("\033[2m#{self}\033[22m"); end
  def italic;           self.class.new("\033[3m#{self}\033[23m"); end
  def underline;        self.class.new("\033[4m#{self}\033[24m"); end

  def underline_italic;
    self.class.new("\033[4m\033[3m#{self}\033[23m\033[24m");
  end

  def blinking;         self.class.new("\033[5m#{self}\033[25m"); end
  def inverse;          self.class.new("\033[7m#{self}\033[27m"); end
  def hidden;           self.class.new("\033[8m#{self}\033[28m"); end
  def strikethrough;    self.class.new("\033[9m#{self}\033[29m"); end

  private

  # Checks if the method name matches any of the dynamic color methods.
  #
  # @param method_name [Symbol] The name of the method being checked.
  # @return [Boolean] True if the method name matches a dynamic color method.
  def dynamic_color_method?(method_name)
    method_name.to_s =~ /^(ansi_|fg_bg_rgb_|fg_bg_rgbh_|fg_rgb_|fg_rgbh_)/
  end
end
