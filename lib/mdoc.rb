#!/usr/bin/env ruby
# frozen_string_literal: true

# encoding=utf-8

require_relative 'filter'
require_relative 'block_types'

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

    # Initializes an instance of MDoc with the given table of markdown sections.
    #
    # @param table [Array<Hash>] An array of hashes representing markdown sections.
    #
    def initialize(table)
      @table = table
    end

    def collect_block_code_cann(fcb)
      body = fcb[:body].join("\n")
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
    end

    def collect_block_code_shell(fcb)
      # write named variables to block at top of script
      #
      fcb[:body].join(' ').split.compact.map do |key|
        format(opts[:block_type_port_set_format], { key: key, value: ENV.fetch(key, nil) })
      end
    end

    def collect_block_code_stdout(fcb)
      stdout = fcb[:stdout]
      body = fcb[:body].join("\n")
      if stdout[:type]
        %(export #{stdout[:name]}=$(cat <<"EOF"\n#{body}\nEOF\n))
      else
        "cat > '#{stdout[:name]}' <<\"EOF\"\n" \
          "#{body}\n" \
          "EOF\n"
      end
    end

    # Retrieves code blocks that are required by a specified code block.
    #
    # @param name [String] The name of the code block to start the retrieval from.
    # @return [Array<Hash>] An array of code blocks required by the specified code block.
    #
    def collect_recursively_required_blocks(name)
      name_block = get_block_by_name(name)
      raise "Named code block `#{name}` not found." if name_block.nil? || name_block.keys.empty?

      # all = [name_block.fetch(:name, '')] + recursively_required(name_block[:reqs])
      all = [name_block.oname] + recursively_required(name_block[:reqs])

      # in order of appearance in document
      # insert function blocks
      # @table.select { |fcb| all.include? fcb.fetch(:name, '') }
      @table.select { |fcb| all.include? fcb.oname }
            .map do |fcb|
        if (call = fcb[:call])
          [get_block_by_name("[#{call.match(/^%\((\S+) |\)/)[1]}]")
            .merge({ cann: call })]
        else
          []
        end + [fcb]
      end.flatten(1)
    end

    # Collects recursively required code blocks and returns them as an array of strings.
    #
    # @param name [String] The name of the code block to start the collection from.
    # @return [Array<String>] An array of strings containing the collected code blocks.
    #
    def collect_recursively_required_code(name, opts: {})
      code = collect_wrapped_blocks(
        blocks = collect_recursively_required_blocks(name)
      ).map do |fcb|
        if fcb[:cann]
          collect_block_code_cann(fcb)
        elsif fcb[:stdout]
          collect_block_code_stdout(fcb)
        elsif [BLOCK_TYPE_LINK, BLOCK_TYPE_OPTS, BLOCK_TYPE_VARS].include? fcb[:shell]
          nil
        elsif fcb[:shell] == BLOCK_TYPE_PORT
          collect_block_code_shell(fcb)
        else
          fcb[:body]
        end
      end.compact.flatten(1)
      { blocks: blocks, code: code }
    end

    # Retrieves code blocks that are wrapped
    # wraps are applied from left to right
    # e.g. w1 w2 => w1-before w2-before w1 w2 w2-after w1-after
    #
    # @return [Array<Hash>] An array of code blocks required by the specified code blocks.
    #
    def collect_wrapped_blocks(blocks)
      blocks.map do |block|
        (block[:wraps] || []).map do |wrap|
          wrap_before = wrap.sub('}', '-before}') ### hardcoded wrap name
          @table.select { |fcb| [wrap_before, wrap].include? fcb.oname }
        end.flatten(1) +
          [block] +
          (block[:wraps] || []).reverse.map do |wrap|
            wrap_after = wrap.sub('}', '-after}') ### hardcoded wrap name
            @table.select { |fcb| fcb.oname == wrap_after }
          end.flatten(1)
      end.flatten(1).compact
    end

    # Retrieves code blocks based on the provided options.
    #
    # @param opts [Hash] The options used for filtering code blocks.
    # @return [Array<Hash>] An array of code blocks that match the options.
    #
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

    # Retrieves a code block by its name.
    #
    # @param name [String] The name of the code block to retrieve.
    # @param default [Hash] The default value to return if the code block is not found.
    # @return [Hash] The code block as a hash or the default value if not found.
    #
    def get_block_by_name(name, default = {})
      @table.select { |fcb| fcb.fetch(:oname, '') == name }.fetch(0, default)
    end

    # Checks if a code block should be hidden based on the given options.
    #
    # @param opts [Hash] The options used for hiding code blocks.
    # @param block [Hash] The code block to check for hiding.
    # @return [Boolean] True if the code block should be hidden; false otherwise.
    #
    # :reek:UtilityFunction
    def hide_menu_block_per_options(opts, block)
      (opts[:hide_blocks_by_name] &&
              ((opts[:block_name_hidden_match]&.present? &&
                block.oname&.match(Regexp.new(opts[:block_name_hidden_match]))) ||
               (opts[:block_name_include_match]&.present? &&
                block.oname&.match(Regexp.new(opts[:block_name_include_match]))) ||
               (opts[:block_name_wrapper_match]&.present? &&
                block.oname&.match(Regexp.new(opts[:block_name_wrapper_match])))) &&
              (block.oname&.present? || block[:label]&.present?)
      )
    end

    # Recursively fetches required code blocks for a given list of requirements.
    #
    # @param reqs [Array<String>] An array of requirements to start the recursion from.
    # @return [Array<String>] An array of recursively required code block names.
    #
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
  require 'bundler/setup'
  Bundler.require(:default)

  require 'minitest/autorun'

  module MarkdownExec
    class TestMDoc < Minitest::Test
      def setup
        @table = [
          { oname: 'block1', body: ['code for block1'], reqs: ['block2'] },
          { oname: 'block2', body: ['code for block2'], reqs: nil },
          { oname: 'block3', body: ['code for block3'], reqs: ['block1'] }
        ]
        @doc = MDoc.new(@table)
      end

      # def test_collect_recursively_required_code
      #   result = @doc.collect_recursively_required_code('block1')[:code]
      #   expected_result = @table[0][:body] + @table[1][:body]
      #   assert_equal expected_result, result
      # end

      def test_get_block_by_name
        result = @doc.get_block_by_name('block1')
        assert_equal @table[0], result

        result_missing = @doc.get_block_by_name('missing_block')
        assert_equal({}, result_missing)
      end

      ### broken test
      # def test_collect_recursively_required_blocks
      #   result = @doc.collect_recursively_required_blocks('block3')
      #   expected_result = [@table[0], @table[1], @table[2]]
      #   assert_equal expected_result, result

      #   assert_raises(RuntimeError) do
      #     @doc.collect_recursively_required_blocks('missing_block')
      #   end
      # end

      def test_hide_menu_block_per_options
        opts = { hide_blocks_by_name: true, block_name_hidden_match: 'block1' }
        block = OpenStruct.new(oname: 'block1')
        result = @doc.hide_menu_block_per_options(opts, block)
        assert result # this should be true based on the given logic
      end

      ### broken test
      # def test_fcbs_per_options
      #   opts = { hide_blocks_by_name: true, block_name_hidden_match: 'block1' }
      #   result = @doc.fcbs_per_options(opts)
      #   assert_equal [@table[1], @table[2]], result
      # end

      def test_recursively_required
        result = @doc.recursively_required(['block3'])
        assert_equal %w[block3 block1 block2], result

        result_no_reqs = @doc.recursively_required(nil)
        assert_equal [], result_no_reqs
      end
    end

    class TestMDoc2 < Minitest::Test
      # Mocking the @table object for testing
      def setup
        @table = [
          OpenStruct.new(oname: '{wrap1}'),
          OpenStruct.new(oname: '{wrap2-before}'),
          OpenStruct.new(oname: '{wrap2}'),
          OpenStruct.new(oname: '{wrap2-after}'),
          OpenStruct.new(oname: '{wrap3-before}'),
          OpenStruct.new(oname: '{wrap3}'),
          OpenStruct.new(oname: '{wrap3-after}')
        ]
        @mdoc = MDoc.new(@table)
      end

      def test_collect_wrapped_blocks
        # Test case 1: blocks with wraps
        OpenStruct.new(oname: 'block1')

        assert_equal(%w[{wrap1} a],
                     @mdoc.collect_wrapped_blocks(
                       [OpenStruct.new(oname: 'a',
                                       wraps: ['{wrap1}'])]
                     ).map(&:oname))

        assert_equal(%w[{wrap2-before} {wrap2} b {wrap2-after}],
                     @mdoc.collect_wrapped_blocks(
                       [OpenStruct.new(oname: 'b',
                                       wraps: ['{wrap2}'])]
                     ).map(&:oname))

        assert_equal(%w[{wrap2-before} {wrap2} {wrap3-before} {wrap3} c {wrap3-after} {wrap2-after}],
                     @mdoc.collect_wrapped_blocks(
                       [OpenStruct.new(oname: 'c',
                                       wraps: %w[{wrap2} {wrap3}])]
                     ).map(&:oname))

        # Test case 2: blocks with no wraps
        blocks = @mdoc.collect_wrapped_blocks([])
        assert_empty blocks

        # Test case 3: blocks with missing wraps
        assert_equal(
          %w[block4],
          @mdoc.collect_wrapped_blocks([OpenStruct.new(oname: 'block4',
                                                       wraps: ['wrap4'])]).map(&:oname)
        )
      end
    end
  end
end
