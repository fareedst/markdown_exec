#!/usr/bin/env ruby
# frozen_string_literal: true

# encoding=utf-8

require_relative 'filter'

module MarkdownExec
  ##
  # MDoc represents an imported markdown document.
  #
  # It provides methods to extract and manipulate specific sections
  # of the document, such as code blocks. It also supports recursion
  # to fetch related or dependent blocks.
  #
  class MDoc
    attr_reader :table

    # convert block name to fcb_parse
    #
    def initialize(table)
      @table = table
    end

    def collect_recursively_required_code(name)
      get_required_blocks(name)
        .map do |fcb|
        body = fcb[:body].join("\n")

        if fcb[:cann]
          xcall = fcb[:cann][1..-2]
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
        elsif fcb[:stdout]
          stdout = fcb[:stdout]
          body = fcb[:body].join("\n")
          if stdout[:type]
            %(export #{stdout[:name]}=$(cat <<"EOF"\n#{body}\nEOF\n))
          else
            "cat > '#{stdout[:name]}' <<\"EOF\"\n" \
              "#{body}\n" \
              "EOF\n"
          end
        else
          fcb[:body]
        end
      end.flatten(1)
    end

    def get_block_by_name(name, default = {})
      @table.select { |fcb| fcb.fetch(:name, '') == name }.fetch(0, default)
    end

    def get_required_blocks(name)
      name_block = get_block_by_name(name)
      raise "Named code block `#{name}` not found." if name_block.nil? || name_block.keys.empty?

      all = [name_block.fetch(:name, '')] + recursively_required(name_block[:reqs])

      # in order of appearance in document
      # insert function blocks
      @table.select { |fcb| all.include? fcb.fetch(:name, '') }
            .map do |fcb|
        if (call = fcb[:call])
          [get_block_by_name("[#{call.match(/^%\((\S+) |\)/)[1]}]")
            .merge({ cann: call })]
        else
          []
        end + [fcb]
      end.flatten(1)
    end

    # :reek:UtilityFunction
    def hide_menu_block_per_options(opts, block)
      (opts[:hide_blocks_by_name] &&
              block[:name]&.match(Regexp.new(opts[:block_name_hidden_match])) &&
              (block[:name]&.present? || block[:label]&.present?)
      )
    end

    def fcbs_per_options(opts = {})
      options = opts.merge(block_name_hidden_match: nil)
      selrows = @table.select do |fcb_title_groups|
        Filter.fcb_select? options, fcb_title_groups
      end

      ### hide rows correctly

      if opts[:hide_blocks_by_name]
        selrows.reject { |block| hide_menu_block_per_options opts, block }
      else
        selrows
      end.map do |block|
        # block[:name] = block[:text] if block[:name].nil?
        block
      end
    end

    def recursively_required(reqs)
      return [] unless reqs

      rem = reqs
      memo = []
      while rem.count.positive?
        rem = rem.map do |req|
          next if memo.include? req

          memo += [req]
          get_block_by_name(req).fetch(:reqs, [])
        end
                 .compact
                 .flatten(1)
      end
      memo
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
