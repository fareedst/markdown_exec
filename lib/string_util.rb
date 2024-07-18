#!/usr/bin/env ruby
# frozen_string_literal: true

# encoding=utf-8

class String
  # / !"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\]^_`abcdefghijklmnopqrstuvwxyz{|}~
  def to_blockname
    gsub(%r{[^!#%\+\-0-9=@A-Z_a-z()\[\]{}]}.freeze, '_'.freeze)####.tap{|ret|pp [__LINE__,'to_blockname()',ret]}
  end

  def to_filename
    gsub(%r{[^!#%\+\-0-9=@A-Z_a-z]}.freeze, '_'.freeze)####.tap{|ret|pp [__LINE__,'to_filename()',ret]}
  end
end

module StringUtil
  # Splits the given string on the first occurrence of the specified character.
  # Returns an array containing the portion of the string before the character and the rest of the string.
  #
  # @param input_str [String] The string to be split.
  # @param split_char [String] The character on which to split the string.
  # @return [Array<String>] An array containing two elements: the part of the string before split_char, and the rest of the string.
  def self.partition_at_first(input_str, split_char)
    split_index = input_str.index(split_char)

    if split_index.nil?
      [input_str, '']
    else
      [input_str[0...split_index], input_str[(split_index + 1)..-1]]
    end
  end
end
