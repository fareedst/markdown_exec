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

    def initialize(block_table)
      @block_table = block_table
    end

    def collect_required_code(name)
      gather_required_blocks(name)
        .map do |block|
        process_block_code(block)
      end.flatten(1)
    end

    def get_block(name, default = {})
      @block_table.select { |block| block.fetch(:name, '') == name }.fetch(0, default)
    end

    def gather_required_blocks(name)
      named_block = get_block(name)
      if named_block.nil? || named_block.keys.empty?
        raise "Named code block `#{name}` not found."
      end

      all_blocks = [named_block.fetch(:name, '')] + required_blocks(named_block[:reqs])
      @block_table.select { |block| all_blocks.include? block.fetch(:name, '') }
                  .map do |block|
        process_block_references(block)
      end.flatten(1)
    end

    def hide_block_given_options(opts, block)
      (opts[:hide_blocks_by_name] &&
       block[:name]&.match(Regexp.new(opts[:block_name_hidden_match])) &&
       (block[:name]&.present? || block[:label]&.present?)
      )
    end

    def blocks_per_options(opts = {})
      filtered_blocks = @block_table.select do |block_group|
        Filter.block_selected? opts, block_group
      end
      if opts[:hide_blocks_by_name]
        filtered_blocks.reject { |block| hide_block_given_options opts, block }
      else
        filtered_blocks
      end.map do |block|
        block
      end
    end

    def required_blocks(reqs)
      return [] unless reqs

      remaining = reqs
      collected = []
      while remaining.count.positive?
        remaining = remaining.map do |req|
          next if collected.include? req

          collected += [req]
          get_block(req).fetch(:reqs, [])
        end
                             .compact
                             .flatten(1)
      end
      collected
    end

    # Helper method to process block code
    def process_block_code(block)
      body = block[:body].join("\n")

      if block[:cann]
        xcall = block[:cann][1..-2]
        mstdin = xcall.match(/<(?<type>\$)?(?<name>[A-Za-z_\-.\w]+)/)
        mstdout = xcall.match(/>(?<type>\$)?(?<name>[A-Za-z_\-.\w]+)/)

        yqcmd = if mstdin[:type]
                  "echo \"$#{mstdin[:name]}\" | yq '#{body}'"
                else
                  "yq e '#{body}' '#{mstdin[:name]}'"
                end
        if mstdout[:type]
          "export #{mstdout[:name]}=$(#{yqcmd})"
        else
          "#{yqcmd} > '#{mstdout[:name]}'"
        end
      elsif block[:stdout]
        stdout = block[:stdout]
        body = block[:body].join("\n")
        if stdout[:type]
          %(export #{stdout[:name]}=$(cat <<"EOF"\n#{body}\nEOF\n))
        else
          "cat > '#{stdout[:name]}' <<\"EOF\"\n" \
            "#{body}\n" \
            "EOF\n"
        end
      else
        block[:body]
      end
    end

    # Helper method to process block references
    def process_block_references(block)
      if (call = block[:call])
        [get_block("[#{call.match(/^%\((\S+) |\)/)[1]}]")
          .merge({ cann: call })]
      else
        []
      end + [block]
    end
  end
end

if $PROGRAM_NAME == __FILE__
  # require 'bundler/setup'
  # Bundler.require(:default)

  require 'minitest/autorun'

  require_relative 'tap'
  include Tap

  module MarkdownExec
    class TestMDoc < Minitest::Test
      def setup
        @table = [
          { name: 'block1', body: ['code for block1'], reqs: ['block2'] },
          { name: 'block2', body: ['code for block2'], reqs: nil },
          { name: 'block3', body: ['code for block3'], reqs: ['block1'] }
        ]
        @doc = MDoc.new(@table)
      end

      def test_collect_recursively_required_code
        result = @doc.collect_recursively_required_code('block1')
        expected_result = @table[0][:body] + @table[1][:body]
        assert_equal expected_result, result
      end

      def test_get_block_by_name
        result = @doc.get_block_by_name('block1')
        assert_equal @table[0], result

        result_missing = @doc.get_block_by_name('missing_block')
        assert_equal({}, result_missing)
      end

      def test_get_required_blocks
        result = @doc.get_required_blocks('block3')
        expected_result = [@table[0], @table[1], @table[2]]
        assert_equal expected_result, result

        assert_raises(RuntimeError) { @doc.get_required_blocks('missing_block') }
      end

      def test_hide_menu_block_per_options
        opts = { hide_blocks_by_name: true, block_name_hidden_match: 'block1' }
        block = { name: 'block1' }
        result = @doc.hide_menu_block_per_options(opts, block)
        assert result # this should be true based on the given logic
      end

      def test_fcbs_per_options
        opts = { hide_blocks_by_name: true, block_name_hidden_match: 'block1' }
        result = @doc.fcbs_per_options(opts)
        assert_equal [@table[1], @table[2]], result
      end

      def test_recursively_required
        result = @doc.recursively_required(['block3'])
        assert_equal %w[block3 block1 block2], result

        result_no_reqs = @doc.recursively_required(nil)
        assert_equal [], result_no_reqs
      end
    end
  end
end
