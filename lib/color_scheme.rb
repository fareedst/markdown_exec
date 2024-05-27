# frozen_string_literal: true

# encoding=utf-8

# A class that represents a color scheme based on configurable parameters
# that determine how the RGB values are calculated for a given string segment.
class ColorScheme
  attr_accessor :base_red, :multiplier_red, :modulus_red,
                :base_green, :multiplier_green, :modulus_green,
                :base_blue, :multiplier_blue, :modulus_blue

  # Initializes a new ColorScheme object with base values, multipliers, and moduli
  # for the red, green, and blue components of an RGB color.
  # @param [Integer] base_red Base red component value.
  # @param [Integer] multiplier_red Multiplier for red component based on string hash.
  # @param [Integer] modulus_red Modulus for calculating red component.
  # @param [Integer] base_green Base green component value.
  # @param [Integer] multiplier_green Multiplier for green component based on string hash.
  # @param [Integer] modulus_green Modulus for calculating green component.
  # @param [Integer] base_blue Base blue component value.
  # @param [Integer] multiplier_blue Multiplier for blue component based on string hash.
  # @param [Integer] modulus_blue Modulus for calculating blue component.
  def initialize(base_red, multiplier_red, modulus_red,
                 base_green, multiplier_green, modulus_green,
                 base_blue, multiplier_blue, modulus_blue)
    @base_red = base_red
    @multiplier_red = multiplier_red
    @modulus_red = modulus_red
    @base_green = base_green
    @multiplier_green = multiplier_green
    @modulus_green = modulus_green
    @base_blue = base_blue
    @multiplier_blue = multiplier_blue
    @modulus_blue = modulus_blue
  end

  # Calculates and returns the ANSI escape code for coloring a string segment
  # based on its hash value.
  # @param [String] segment The string segment to color.
  # @return [String] ANSI escape code string with RGB color formatting.
  def color_for(segment)
    hash_value = segment.each_byte.reduce(0, :+)
    red = @base_red + (@multiplier_red * (hash_value % @modulus_red))
    green = @base_green + (@multiplier_green * (hash_value % @modulus_green))
    blue = @base_blue + (@multiplier_blue * (hash_value % @modulus_blue))
    "\e[38;2;#{red};#{green};#{blue}m#{segment}\e[0m"
  end

  # Applies color codes to each segment of a filesystem path, differentiating the
  # final segment from others using a distinct color scheme.
  # @param [String] path The filesystem path to colorize.
  # @return [String] The colorized path.
  def self.colorize_path(path)
    segments = path.split('/')
    segments.map.with_index do |segment, index|
      color_scheme = if index == segments.size - 1
                       ColorScheme.new(192, 0, 1, 192, 0, 1, 192, 0, 1)
                     else
                       ColorScheme.new(32, 1, 192, 32, 1, 192, 255, 0, 1)
                     end

      color_scheme.color_for(segment)
    end.join('/')
  end
end
