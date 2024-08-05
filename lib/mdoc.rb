#!/usr/bin/env ruby
# frozen_string_literal: true

# encoding=utf-8

require_relative 'block_types'
require_relative 'filter'

$pd = false unless defined?($pd)

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
    def initialize(table = [])
      @table = table
      # &bt @table.count
    end

    def collect_block_code_cann(fcb)
      body = fcb.body.join("\n")
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

    # Collects and formats the shell command output to redirect script block code to a file or a variable.
    #
    # @param [Hash] fcb A hash containing information about the script block's stdout and body.
    #   @option fcb [Hash] :stdout A hash specifying the stdout details.
    #     @option stdout [Boolean] :type Indicates whether to export to a variable (true) or to write to a file (false).
    #     @option stdout [String] :name The name of the variable or file to which the body will be output.
    #   @option fcb [Array<String>] :body An array of strings representing the lines of the script block's body.
    #
    # @return [String] A string containing the formatted shell command to output the script block's body.
    #   If stdout[:type] is true, the command will export the body to a shell variable.
    #   If stdout[:type] is false, the command will write the body to a file.
    def collect_block_code_stdout(fcb)
      stdout = fcb[:stdout]
      body = fcb.body.join("\n")
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
    def collect_block_dependencies(anyname:)
      name_block = get_block_by_anyname(anyname)
      if name_block.nil? || name_block.keys.empty?
        raise "Named code block `#{anyname}` not found. (@#{__LINE__})"
      end

      nickname = name_block.pub_name

      dependencies = collect_dependencies(nickname)
      # &bt dependencies.count
      all_dependency_names = collect_unique_names(dependencies).push(nickname).uniq
      # &bt all_dependency_names.count

      # select blocks in order of appearance in source documents
      #
      blocks = @table.select do |fcb|
        # 2024-08-04 match nickname
        all_dependency_names.include?(fcb.pub_name) || all_dependency_names.include?(fcb.nickname) || all_dependency_names.include?(fcb.oname)
      end
      # &bt blocks.count

      ## add cann key to blocks, calc unmet_dependencies
      #
      unmet_dependencies = all_dependency_names.dup
      blocks = blocks.map do |fcb|
        # 2024-08-04 match oname for long block names
        # 2024-08-04 match nickname
        unmet_dependencies.delete(fcb.pub_name) || unmet_dependencies.delete(fcb.nickname) || unmet_dependencies.delete(fcb.oname) # may not exist if block name is duplicated
        if (call = fcb.call)
          [get_block_by_anyname("[#{call.match(/^%\((\S+) |\)/)[1]}]")
            .merge({ cann: call })]
        else
          []
        end + [fcb]
      end.flatten(1)
      # &bt unmet_dependencies.count

      { all_dependency_names: all_dependency_names,
        blocks: blocks,
        dependencies: dependencies,
        unmet_dependencies: unmet_dependencies }
    end

    # Collects recursively required code blocks and returns them as an array of strings.
    #
    # @param name [String] The name of the code block to start the collection from.
    # @return [Array<String>] An array of strings containing the collected code blocks.
    #
    def collect_recursively_required_code(anyname:, block_source:, label_body: true, label_format_above: nil,
                                          label_format_below: nil)
      block_search = collect_block_dependencies(anyname: anyname)
      if block_search[:blocks]
        blocks = collect_wrapped_blocks(block_search[:blocks])
        # &bt blocks.count

        block_search.merge(
          { block_names: blocks.map(&:pub_name),
            code: blocks.map do |fcb|
              if fcb[:cann]
                collect_block_code_cann(fcb)
              elsif fcb[:stdout]
                collect_block_code_stdout(fcb)
              elsif [BlockType::OPTS].include? fcb.shell
                fcb.body # entire body is returned to requesing block
              elsif [BlockType::LINK,
                     BlockType::VARS].include? fcb.shell
                nil
              elsif fcb[:chrome] # for Link blocks like History
                nil
              elsif fcb.shell == BlockType::PORT
                generate_env_variable_shell_commands(fcb)
              elsif label_body
                generate_label_body_code(fcb, block_source, label_format_above,
                                         label_format_below)
              else # raw body
                fcb.body
              end
            end.compact.flatten(1).compact }
        )
      else
        block_search.merge({ block_names: [], code: [] })
      end
    rescue StandardError
      error_handler('collect_recursively_required_code')
    end

    def collect_unique_names(hash)
      hash.values.flatten.uniq
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

    def error_handler(name = '', opts = {})
      Exceptions.error_handler(
        "MDoc.#{name} -- #{$!}",
        opts
      )
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

      unless options[:menu_include_imported_blocks]
        selrows = selrows.reject do |block|
          block.fetch(:depth, 0).positive?
        end
      end

      if opts[:hide_blocks_by_name]
        selrows = selrows.reject do |block|
          hide_menu_block_on_name opts, block
        end
      end

      # remove
      # . empty chrome between code; edges are same as blanks
      #
      select_elements_with_neighbor_conditions(selrows) do |prev_element, current, next_element|
        !(current[:chrome] && !current.oname.present?) ||
          !(!prev_element.nil? &&
            prev_element.shell.present? &&
            !next_element.nil? &&
            next_element.shell.present?)
      end
    end

    # Generates shell code lines to set environment variables named in the body of the given object.
    # Reads a whitespace-separated list of environment variable names from `fcb.body`,
    # retrieves their values from the current environment, and constructs shell commands
    # to set these environment variables.
    #
    # @param fcb [Object] An object with a `body` method that returns an array of strings,
    #   where each string is a name of an environment variable.
    # @return [Array<String>] An array of strings, each representing a shell command to
    #   set an environment variable in the format `KEY=value`.
    #
    # Example:
    #   If `fcb.body` returns ["PATH", "HOME"], and the current environment has PATH=/usr/bin
    #   and HOME=/home/user, this method will return:
    #     ["PATH=/usr/bin", "HOME=/home/user"]
    #
    def generate_env_variable_shell_commands(fcb)
      fcb.body.join(' ').split.compact.map do |key|
        "#{key}=#{Shellwords.escape ENV.fetch(key, '')}"
      end
    end

    # Generates a formatted code block with labels above and below the main content.
    # The labels and content are based on the provided format strings and the body of the given object.
    #
    # @param fcb [Object] An object with a `pub_name` method that returns a string, and a `body` method that returns an array of strings.
    # @param block_source [Hash] A hash containing additional information to be merged into the format strings.
    # @param label_format_above [String, nil] A format string for the label above the content, or nil if no label is needed.
    # @param label_format_below [String, nil] A format string for the label below the content, or nil if no label is needed.
    # @return [Array<String>] An array of strings representing the formatted code block, with optional labels above and below the main content.
    #
    # Example:
    #   If `fcb.pub_name` returns "Example Block", `fcb.body` returns ["line1", "line2"],
    #   `block_source` is { source: "source_info" }, `label_format_above` is "Start of %{block_name}",
    #   and `label_format_below` is "End of %{block_name}", the method will return:
    #     ["Start of Example_Block", "line1", "line2", "End of Example_Block"]
    #
    def generate_label_body_code(fcb, block_source, label_format_above, label_format_below)
      block_name_for_bash_comment = fcb.pub_name.gsub(/\s+/, '_')

      label_above = if label_format_above
                      format(label_format_above,
                             block_source.merge({ block_name: block_name_for_bash_comment }))
                    else
                      nil
                    end
      label_below = if label_format_below
                      format(label_format_below,
                             block_source.merge({ block_name: block_name_for_bash_comment }))
                    else
                      nil
                    end

      [label_above, *fcb.body, label_below].compact
    end

    # Retrieves a code block by its name.
    #
    # @param name [String] The name of the code block to retrieve.
    # @param default [Hash] The default value to return if the code block is not found.
    # @return [Hash] The code block as a hash or the default value if not found.
    #
    def get_block_by_anyname(name, default = {})
      # &bt name
      @table.select do |fcb|
        fcb.tap { |_ret| pp [__LINE__, 'get_block_by_anyname()', 'fcb', fcb] if $pd }
        fcb.nickname == name ||
          fcb.dname == name ||
          fcb.oname == name ||
          fcb.pub_name == name
      end.fetch(0, default).tap { |ret| pp [__LINE__, 'get_block_by_anyname() ->', ret] if $pd }
    end

    # Checks if a code block should be hidden based on the given options.
    #
    # @param opts [Hash] The options used for hiding code blocks.
    # @param block [Hash] The code block to check for hiding.
    # @return [Boolean] True if the code block should be hidden; false otherwise.
    #
    # :reek:UtilityFunction
    def hide_menu_block_on_name(opts, block)
      if block.fetch(:chrome, false)
        false
      else
        opts[:hide_blocks_by_name] &&
          ((opts[:block_name_hidden_match]&.present? &&
            block.oname&.match(Regexp.new(opts[:block_name_hidden_match]))) ||
           (opts[:block_name_include_match]&.present? &&
            block.oname&.match(Regexp.new(opts[:block_name_include_match]))) ||
           (opts[:block_name_wrapper_match]&.present? &&
            block.oname&.match(Regexp.new(opts[:block_name_wrapper_match])))) &&
          (block.oname&.present? || block[:label]&.present?)

      end
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
      while rem && rem.count.positive?
        rem = rem.map do |req|
          next if memo.include? req

          memo += [req]
          get_block_by_anyname(req).reqs
        end
                 .compact
                 .flatten(1)
      end
      memo
    end

    # Recursively fetches required code blocks for a given list of requirements.
    #
    # @param source [String] The name of the code block to start the recursion from.
    # @return [Hash] A list of code blocks required by each source code block.
    #
    def recursively_required_hash(source, memo = Hash.new([]))
      return memo unless source
      return memo if memo.keys.include? source

      block = get_block_by_anyname(source)
      if block.nil? || block.keys.empty?
        raise "Named code block `#{source}` not found. (@#{__LINE__})"
      end

      memo[source] = block.reqs
      return memo unless memo[source]&.count&.positive?

      memo[source].each do |req|
        next if memo.keys.include? req

        recursively_required_hash(req, memo)
      end
      memo
    end

    # Recursively collects dependencies of a given source.
    # @param source [String] The name of the initial source block.
    # @param memo [Hash] A memoization hash to store resolved dependencies.
    # @return [Hash] A hash mapping sources to their respective dependencies.
    def collect_dependencies(source, memo = {})
      return memo unless source

      if (block = get_block_by_anyname(source)).nil? || block.keys.empty?
        return memo if true

        raise "Named code block `#{source}` not found. (@#{__LINE__})"

      end

      return memo unless block.reqs

      memo[source] = block.reqs

      block.reqs.each { |req| collect_dependencies(req, memo) unless memo.key?(req) }
      memo
    end

    def select_elements_with_neighbor_conditions(array,
                                                 last_selected_placeholder = nil, next_selected_placeholder = nil)
      selected_elements = []
      last_selected = last_selected_placeholder

      array.each_with_index do |current, index|
        next_element = if index < array.size - 1
                         array[index + 1]
                       else
                         next_selected_placeholder
                       end

        if yield(last_selected, current, next_element)
          selected_elements << current
          last_selected = current
        end
      end

      selected_elements
    end

    # def select_elements_with_neighbor_conditions(array)
    #   # This function filters elements from the array where the current element has property A set to true
    #   # and both the previous and next elements have property B set to true.
    #   selected_elements = []

    #   array.each_with_index do |element, index|
    #     next if index.zero? # Skip the first element since it has no previous element
    #     break if index >= array.size - 1 # Break before the last to avoid out-of-bound errors

    #     prev_element = array[index - 1]
    #     next_element = array[index + 1]

    #     # Check the conditions for property A on the current element and property B on adjacent elements
    #     unless element[:chrome] && !element[:oname].present? && prev_element.shell.present? && next_element.shell.present?
    #       selected_elements << element
    #     # else
    # # pp 'SKIPPING', element
    #     end
    #   end

    #   selected_elements
    # end
  end
end

if $PROGRAM_NAME == __FILE__
  require 'bundler/setup'
  Bundler.require(:default)

  require 'minitest/autorun'
  require 'mocha/minitest'

  module MarkdownExec
    class TestMDocCollectDependencies < Minitest::Test
      def setup
        @mdoc = MDoc.new
      end

      def test_collect_dependencies_with_no_source
        assert_empty @mdoc.collect_dependencies(nil)
      end

      if false # must raise error
        def test_collect_dependencies_with_nonexistent_source
          assert_raises(RuntimeError) { @mdoc.collect_dependencies('nonexistent') }
        end
      end

      def test_collect_dependencies_with_valid_source
        @mdoc.stubs(:get_block_by_anyname).with('source1').returns({ reqs: ['source2'] })
        @mdoc.stubs(:get_block_by_anyname).with('source2').returns({ reqs: [] })

        expected = { 'source1' => ['source2'], 'source2' => [] }
        assert_equal expected, @mdoc.collect_dependencies('source1')
      end
    end

    class TestCollectUniqueNames < Minitest::Test
      def setup
        @mdoc = MDoc.new
      end

      def test_empty_hash
        assert_empty @mdoc.collect_unique_names({})
      end

      def test_single_key
        input = { group1: %w[Alice Bob Charlie] }
        assert_equal %w[Alice Bob Charlie], @mdoc.collect_unique_names(input)
      end

      def test_multiple_keys
        input = { group1: %w[Alice Bob], group2: %w[Charlie Alice] }
        assert_equal %w[Alice Bob Charlie], @mdoc.collect_unique_names(input)
      end

      def test_no_unique_names
        input = { group1: ['Alice'], group2: ['Alice'] }
        assert_equal ['Alice'], @mdoc.collect_unique_names(input)
      end
    end

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
        result = @doc.get_block_by_anyname('block1')
        assert_equal @table[0], result

        result_missing = @doc.get_block_by_anyname('missing_block')
        assert_equal({}, result_missing)
      end

      ### broken test
      def test_collect_block_dependencies
        result = @doc.collect_block_dependencies(anyname: 'block3')[:blocks]
        expected_result = [@table[0], @table[1], @table[2]]
        assert_equal expected_result, result

        assert_raises(RuntimeError) do
          @doc.collect_block_dependencies(anyname: 'missing_block')
        end
      end

      def test_hide_menu_block_on_name
        opts = { hide_blocks_by_name: true,
                 block_name_hidden_match: 'block1' }
        block = FCB.new(oname: 'block1')
        result = @doc.hide_menu_block_on_name(opts, block)
        assert result # this should be true based on the given logic
      end

      ### broken test
      # def test_fcbs_per_options
      #   opts = { hide_blocks_by_name: true, block_name_hidden_match: 'block1' }
      #   result = @doc.fcbs_per_options(opts)
      #   assert_equal [@table[1], @table[2]], result
      # end

      def test_recursively_required
        result = @doc.recursively_required_hash('block3')
        assert_equal ({ 'block3' => ['block1'], 'block1' => ['block2'], 'block2' => nil }),
                     result

        result_no_reqs = @doc.recursively_required_hash(nil)
        assert_equal ({}), result_no_reqs
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
