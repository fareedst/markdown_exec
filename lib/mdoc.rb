#!/usr/bin/env -S bundle exec ruby
# frozen_string_literal: true

# encoding=utf-8

require_relative 'block_types'
require_relative 'collapser'
require_relative 'filter'

$pd = false unless defined?($pd)

module MarkdownExec
  class MenuFilter
    def initialize(opts)
      @opts = opts.merge(block_name_hide_custom_match: nil)
    end

    def fcb_in_menu?(fcb)
      in_menu = Filter.fcb_select?(@opts, fcb)
      unless @opts[:menu_include_imported_blocks]
        in_menu = fcb.fetch(:depth, 0).zero?
      end
      if in_menu && @opts[:hide_blocks_by_name]
        in_menu = !hide_menu_block_on_name(fcb)
      end
      in_menu
    end

    # Checks if a code block should be hidden based on the given options.
    #
    # @param opts [Hash] The options used for hiding code blocks.
    # @param block [Hash] The code block to check for hiding.
    # @return [Boolean] True if the code block should be hidden; false otherwise.
    #
    # :reek:UtilityFunction
    def hide_menu_block_on_name(block)
      if block.fetch(:chrome, false)
        false
      else
        @opts[:hide_blocks_by_name] &&
          ((@opts[:block_name_hide_custom_match]&.present? &&
            block.s2title&.match(Regexp.new(@opts[:block_name_hide_custom_match]))) ||
           (@opts[:block_name_hidden_match]&.present? &&
            block.s2title&.match(Regexp.new(@opts[:block_name_hidden_match]))) ||
           (@opts[:block_name_wrapper_match]&.present? &&
            block.s2title&.match(Regexp.new(@opts[:block_name_wrapper_match])))) &&
          (block.s2title&.present? || block[:label]&.present?)
      end
    end
  end

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
    end

    def collect_block_code_cann(fcb)
      body = fcb.body.join("\n")
      xcall = fcb[:cann][1..-2]
      mstdin = xcall.match(/<(?<type>\$)?(?<name>[\-.\w]+)/)
      mstdout = xcall.match(/>(?<type>\$)?(?<name>[\-.\w]+)/)

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

    # Generates a shell command to redirect a block's body to either a shell variable or a file.
    #
    # @param [Hash] fcb A hash containing information about the script block's stdout and body.
    #   @option fcb [Hash] :stdout A hash specifying the stdout details.
    #     @option stdout [Boolean] :type Indicates whether to export to a variable (true) or to write to a file (false).
    #     @option stdout [String] :name The name of the variable or file to which the body will be output.
    #   @option fcb [Array<String>] :body An array of strings representing the lines of the script block's body.
    #
    # @return [String] A string containing the shell command to redirect the script block's body.
    #   If stdout[:type] is true, the command will export the body to a shell variable.
    #   If stdout[:type] is false, the command will write the body to a file.
    def code_for_fcb_body_into_var_or_file(fcb)
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
      ref = name_block.id
      dependencies = collect_dependencies(pubname: ref)
      wwt :dependencies, 'dependencies.count:', dependencies.count

      all_dependency_names =
        collect_unique_names(dependencies).push(ref).uniq
      wwt :dependencies, 'all_dependency_names.count:',
          all_dependency_names.count

      # select blocks in order of appearance in source documents
      #
      blocks = table_not_split.select do |fcb|
        fcb.is_dependency_of?(all_dependency_names)
      end
      wwt :blocks, 'blocks.count:', blocks.count

      ## add cann key to blocks, calc unmet_dependencies
      #
      unmet_dependencies = all_dependency_names.dup
      blocks = blocks.map do |fcb|
        fcb.delete_matching_name!(unmet_dependencies)
        if (call = fcb.call)
          fcb1 = get_block_by_anyname("[#{call.match(/^%\((\S+) |\)/)[1]}]")
          fcb1.cann = call
          [fcb1]
        else
          []
        end + [fcb]
      end.flatten(1)
      wwt :unmet_dependencies, 'unmet_dependencies.count:',
          unmet_dependencies.count
      wwt :dependencies, 'dependencies.keys:', dependencies.keys

      { all_dependency_names: all_dependency_names,
        blocks: blocks,
        dependencies: dependencies,
        unmet_dependencies: unmet_dependencies }
    rescue StandardError
      wwe $!
    end

    # Collects recursively required code blocks and returns them as an array of strings.
    #
    # @param name [String] The name of the code block to start the collection from.
    # @return [Array<String>] An array of strings containing the collected code blocks.
    #
    def collect_recursively_required_code(
      anyname:, block_source:,
      label_body: true, label_format_above: nil, label_format_below: nil
    )
      raise 'unexpected label_body' if !label_body
      block_search = collect_block_dependencies(anyname: anyname)
      if block_search[:blocks]
        blocks = collect_wrapped_blocks(block_search[:blocks])
        # !!t blocks.count

        block_search.merge(
          { block_names: blocks.map(&:pub_name),
            code: blocks.map do |fcb|
              process_block_to_code(
                fcb, block_source,
                label_body, label_format_above, label_format_below
              )
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
      blocks.map do |fcb|
        next if fcb.is_split_rest?

        (fcb[:wraps] || []).map do |wrap|
          wrap_before = wrap.sub('}', '-before}') ### hardcoded wrap name
          table_not_split.select { |fcb|
            fcb.code_name_included?(wrap_before, wrap)
          }
        end.flatten(1) +
          [fcb] +
          (fcb[:wraps] || []).reverse.map do |wrap|
            wrap_after = wrap.sub('}', '-after}') ### hardcoded wrap name
            table_not_split.select { |fcb| fcb.code_name_included?(wrap_after) }
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
      options = opts.merge(block_name_hide_custom_match: nil)
      selrows = @table.select do |fcb_title_groups|
        Filter.fcb_select? options, fcb_title_groups
      end

      ### hide rows correctly

      unless opts[:menu_include_imported_blocks]
        selrows = selrows.reject do |fcb|
          fcb.fetch(:depth, 0).positive?
        end
      end

      if opts[:hide_blocks_by_name]
        selrows = selrows.reject do |fcb|
          hide_menu_block_on_name(opts, fcb)
        end
      end

      collapser = Collapser.new(
        options: opts,
        compress_ids: opts[:compressed_ids] || {},
        expand_ids: opts[:expanded_ids] || {}
      )
      selrows = collapser.reject(
        selrows,
        initialize: opts[:compressed_ids].nil?
      ) do |fcb, _hide, _collapsed_level|
        # update fcb per state
        next unless fcb.collapsible

        fcb.s1decorated = fcb.s1decorated + ' ' +
                          (if fcb.collapse
                             opts[:menu_collapsible_symbol_collapsed]
                           else
                             opts[:menu_collapsible_symbol_expanded]
                           end)
      end
      opts[:compressed_ids] = collapser.compress_ids
      opts[:expanded_ids] = collapser.expand_ids

      # remove
      # . empty chrome between code; edges are same as blanks
      #
      select_elements_with_neighbor_conditions(selrows) do |prev_element,
                                                            current,
                                                            next_element|
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

    # Wraps a code block body with formatted labels above and below the main content.
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
    def wrap_block_body_with_labels(fcb, block_source, label_format_above,
                                    label_format_below)
      block_name_for_bash_comment = fcb.pub_name.gsub(/\s+/, '_')

      label_above = if label_format_above.present?
                      format(label_format_above,
                             block_source.merge(
                               { block_name: block_name_for_bash_comment }
                             ))
                    else
                      nil
                    end
      label_below = if label_format_below.present?
                      format(label_format_below,
                             block_source.merge(
                               { block_name: block_name_for_bash_comment }
                             ))
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
      table_not_split.select do |fcb|
        fcb.is_named?(name)
      end.fetch(0, default)
    end

    # Retrieves code blocks by a name.
    #
    # @param name [String] The name of the code block to retrieve.
    # @param default [Hash] The default value to return if the code block is not found.
    # @return [Hash] The code block as a hash or the default value if not found.
    #
    def get_blocks_by_anyname(name)
      table_not_split.select do |fcb|
        fcb.is_named?(name)
      end
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
          ((opts[:block_name_hide_custom_match]&.present? &&
            block.s2title&.match(Regexp.new(opts[:block_name_hide_custom_match]))) ||
           (opts[:block_name_hidden_match]&.present? &&
            block.s2title&.match(Regexp.new(opts[:block_name_hidden_match]))) ||
           (opts[:block_name_wrapper_match]&.present? &&
            block.s2title&.match(Regexp.new(opts[:block_name_wrapper_match])))) &&
          (block.s2title&.present? || block[:label]&.present?)
      end
    end

    # Processes a single code block and returns its code representation.
    #
    # @param fcb [Hash] The code block to process.
    # @param block_source [Hash] Additional information for label generation.
    # @param label_body [Boolean] Whether to generate labels around the body.
    # @param label_format_above [String, nil] Format string for label above content.
    # @param label_format_below [String, nil] Format string for label below content.
    # @return [String, Array, nil] The code representation of the block, or nil if the block should be skipped.
    #
    def process_block_to_code(fcb, block_source, label_body, label_format_above,
                              label_format_below)
      raise 'unexpected label_body' unless label_body

      if fcb[:cann]
        collect_block_code_cann(fcb)
      elsif fcb[:stdout]
        code_for_fcb_body_into_var_or_file(fcb)
      elsif [BlockType::OPTS].include? fcb.type
        fcb.body # entire body is returned to requesing block

      elsif [BlockType::LINK,
             BlockType::LOAD,
             BlockType::UX,
             BlockType::VARS].include? fcb.type
        nil # Vars for all types are collected later
      elsif fcb[:chrome] # for Link blocks like History
        nil
      elsif fcb.type == BlockType::PORT
        generate_env_variable_shell_commands(fcb)
      elsif label_body
        raise 'unexpected type' if fcb.type != BlockType::SHELL

        # BlockType::  SHELL block
        if fcb.start_line =~ /@eval/ ###s
          com_exp_cod = HashDelegator.execute_bash_script_lines(
            code_lines: fcb.body,
            export: OpenStruct.new(exportable: true, name: ''),
            force: true,
            shell: fcb.shell || 'bash' ###s
          )
          ###s CommandResult.exit_status failure?
          com_exp_cod[:new_lines].map { _1[:text] }

        else
          wrap_block_body_with_labels(
            fcb, block_source,
            label_format_above, label_format_below
          )
        end
      else # raw body
        fcb.body
      end.tap { |p1| wwr p1 }
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

      blocks = get_blocks_by_anyname(source)
      if blocks.empty?
        raise "Named code block `#{source}` not found. (@#{__LINE__})"
      end

      memo[source] = blocks.map(&:reqs).flatten(1)
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
    def collect_dependencies(block: nil, memo: {}, pubname: nil)
      if block.nil?
        return memo unless pubname

        blocks = get_blocks_by_anyname(pubname)
        if blocks.empty?
          raise "Named code block `#{pubname}` not found. (@#{__LINE__})"
        end
      else
        blocks = [block]
      end
      blocks.each do |block|
        memo[block.id] = []
      end
      return memo unless blocks.count.positive?

      required_blocks = blocks.map(&:reqs).flatten(1)
      return memo unless required_blocks.count.positive?

      blocks.each do |block|
        memo[block.id] = required_blocks
      end

      required_blocks.each do |req|
        collect_dependencies(pubname: req, memo: memo)
      end

      memo
    end

    def select_elements_with_neighbor_conditions(
      array,
      last_selected_placeholder = nil,
      next_selected_placeholder = nil
    )
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

    # exclude blocks with duplicate code
    # the first block in each split contains the same data as the rest of the split
    def table_not_split
      @table.reject(&:is_split_rest?)
    end
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
        assert_empty @mdoc.collect_dependencies
      end

      ### must raise error
      def test_collect_dependencies_with_nonexistent_source
        assert_raises(RuntimeError) do
          @mdoc.collect_dependencies(pubname: 'nonexistent')
        end
      end if false

      def test_collect_dependencies_with_valid_source
        @mdoc.stubs(:get_blocks_by_anyname)
             .with('source1').returns([OpenStruct.new(id: 'source1',
                                                      reqs: ['source2'])])
        @mdoc.stubs(:get_blocks_by_anyname)
             .with('source2').returns([OpenStruct.new(id: 'source2', reqs: [])])

        expected = { 'source1' => ['source2'], 'source2' => [] }
        assert_equal expected, @mdoc.collect_dependencies(pubname: 'source1')
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
        ].map do |row|
          FCB.new(nickname: nil, **row)
        end
        @doc = MDoc.new(@table)
      end

      def test_get_block_by_name
        result = @doc.get_block_by_anyname('block1')
        assert_equal @table[0], result

        result_missing = @doc.get_block_by_anyname('missing_block')
        assert_equal({}, result_missing)
      end

      def test_collect_block_dependencies
        result = @doc.collect_block_dependencies(anyname: 'block3')[:blocks]
        expected_result = [@table[0], @table[1], @table[2]]
        assert_equal expected_result, result

        assert_raises(RuntimeError) do
          @doc.collect_block_dependencies(anyname: 'missing_block')
        end
      end if false ### broken test

      def test_hide_menu_block_on_name
        opts = { hide_blocks_by_name: true,
                 block_name_hide_custom_match: 'block1' }
        block = FCB.new(s2title: 'block1')
        result = @doc.hide_menu_block_on_name(opts, block)
        assert result # this should be true based on the given logic
      end

      def test_fcbs_per_options
        opts = { hide_blocks_by_name: true,
                 block_name_hide_custom_match: 'block1' }
        result = @doc.fcbs_per_options(opts)
        assert_equal [@table[1], @table[2]], result
      end if false ### broken test

      def test_recursively_required
        result = @doc.recursively_required_hash('block3')
        assert_equal ({ 'block3' => ['block1'],
                        'block1' => ['block2'],
                        'block2' => [nil] }),
                     result

        result_no_reqs = @doc.recursively_required_hash(nil)
        assert_equal ({}), result_no_reqs
      end
    end

    class TestMDoc2 < Minitest::Test
      # Mocking the @table object for testing
      def setup
        @table = [
          FCB.new(oname: '{wrap1}'),
          FCB.new(oname: '{wrap2-before}'),
          FCB.new(oname: '{wrap2}'),
          FCB.new(oname: '{wrap2-after}'),
          FCB.new(oname: '{wrap3-before}'),
          FCB.new(oname: '{wrap3}'),
          FCB.new(oname: '{wrap3-after}')
        ]
        @mdoc = MDoc.new(@table)
      end

      def test_collect_wrapped_blocks
        # Test case 1: blocks with wraps
        assert_equal(%w[{wrap2-before} {wrap2} b {wrap2-after}],
                     @mdoc.collect_wrapped_blocks(
                       [FCB.new(oname: 'b', wraps: ['{wrap2}'])]
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
          @mdoc.collect_wrapped_blocks(
            [OpenStruct.new(oname: 'block4', wraps: ['wrap4'])]
          ).map(&:oname)
        )
      end
    end
  end
end
