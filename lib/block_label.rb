#!/usr/bin/env ruby
# frozen_string_literal: true

# encoding=utf-8

##
# This class is used to represent a block label which can be constructed using various components.
# It handles initialization using a hash and provides a method to create a label string.
#
# Example Usage:
# block = {
#   filename: 'example.md',
#   headings: ['Header1', 'Header2'],
#   menu_blocks_with_docname: true,
#   menu_blocks_with_headings: false,
#   title: 'Sample Title',
#   body: 'Sample Body',
#   text: 'Sample Text'
# }
# label_obj = BlockLabel.new(block)
# label_str = label_obj.make
#

class BlockLabel
  def self.make(filename:, headings:, menu_blocks_with_docname:, menu_blocks_with_headings:, title:, body:, text:)
    label = title
    label = body if label.nil? || label.empty?
    label = text if label.nil? || label.empty?

    parts = [label]

    parts << headings.compact.join(' # ') if menu_blocks_with_headings
    parts << filename if menu_blocks_with_docname

    parts.join('  ')
  rescue StandardError => err
    warn(error = "ERROR ** BlockLabel.make(); #{err.inspect}")
    binding.pry if $tap_enable
    raise ArgumentError, error
  end
end

if $PROGRAM_NAME == __FILE__
  require 'minitest/autorun'

  class BlockLabelTest < Minitest::Test
    def setup
      @block_data = {
        filename: 'example.md',
        headings: %w[Header1 Header2],
        menu_blocks_with_docname: true,
        menu_blocks_with_headings: false,
        title: 'Sample Title',
        body: 'Sample Body',
        text: 'Sample Text'
      }
    end

    def test_make_method
      assert_equal 'Sample Title  example.md', BlockLabel.make(**@block_data)
    end

    def test_make_method_without_title
      @block_data[:title] = nil
      label = BlockLabel.make(**@block_data)
      assert_equal 'Sample Body  example.md', label
    end

    def test_make_method_without_title_and_body
      @block_data[:title] = nil
      @block_data[:body] = nil
      label = BlockLabel.make(**@block_data)
      assert_equal 'Sample Text  example.md', label
    end

    def test_make_method_with_headings
      @block_data[:menu_blocks_with_headings] = true
      label = BlockLabel.make(**@block_data)
      assert_equal 'Sample Title  Header1 # Header2  example.md', label
    end
  end
end
