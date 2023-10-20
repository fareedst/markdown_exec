#!/usr/bin/env ruby
# frozen_string_literal: true

# encoding=utf-8

require_relative 'filter'

module MarkdownExec
  ##
  # MarkdownBlockManager represents an imported markdown document.
  #
  # It provides methods to extract and manipulate specific sections
  # of the document, such as code blocks. It also supports recursion
  # to fetch related or dependent blocks.
  #
  class MarkdownBlockManager
    attr_reader :block_table

    # initialize
    #
    # Initializes an instance of MarkdownBlockManager with the given block table.
    #
    # @param block_table [Array<Hash>] An array of hashes representing markdown blocks.
    def initialize(block_table)
      @block_table = block_table
    end

    # get_block
    #
    # Retrieves a code block by its name.
    #
    # @param name [String] The name of the code block to retrieve.
    # @param default [Hash] The default value to return if the code block is not found.
    # @return [Hash] The code block as a hash or the default value if not found.
    def get_block(name, default = {})
      @block_table.select { |block| block.fetch(:name, '') == name }.fetch(0, default)
    end
  end
end

if $PROGRAM_NAME == __FILE__
  # require 'bundler/setup'
  # Bundler.require(:default)

  require 'minitest/autorun'

  class MarkdownBlockManagerTest < Minitest::Test
    def setup
      @block_table = [
        { name: 'block1', reqs: ['block2'], body: ['code1'] },
        { name: 'block2', body: ['code2'] },
        { name: 'block3', body: ['code3'] }
      ]
      @manager = MarkdownExec::MarkdownBlockManager.new(@block_table)
    end

    # Test the get_block method
    def test_get_block
      block = @manager.get_block('block2')
      expected_block = { name: 'block2', body: ['code2'] }
      assert_equal expected_block, block
    end
  end
end
