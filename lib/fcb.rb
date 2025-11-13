#!/usr/bin/env -S bundle exec ruby
# frozen_string_literal: true

# encoding=utf-8
require 'digest'
require_relative 'namer'
BT_UX_FLD_REQUIRED = 'required'
def parse_yaml_of_ux_block(
  data,
  prompt: nil,
  validate: nil
)
  export = data if (export = data['export']).nil?

  # a single variable name is required to display a single value
  menu_format = export['format'] || export['menu_format']
  name = export['name']
  # if name is missing, use the last key in the echo or exec hashes
  if !name&.present?
    name = if export['echo'].is_a? Hash
             export['echo'].keys.last
           elsif export['exec'].is_a? Hash
             export['exec'].keys.last
           end
  end
  raise "Name is missing in UX block: #{data.inspect}" unless name.present? || menu_format.present?

  OpenStruct.new(
    act: export['act'],
    allow: export['allow'] || export['allowed'],
    default: export['default'],
    echo: export['echo'],
    exec: export['exec'],
    force: export['force'],
    init: export['init'],
    menu_format: menu_format,
    name: name,
    prompt: export['prompt'] || prompt,
    readonly: export['readonly'].nil? ? false : export['readonly'],
    required: export['require'] || export['required'] || export[BT_UX_FLD_REQUIRED],
    transform: export['transform'],
    validate: export['validate'] || validate
  )
end

module MarkdownExec
  class Error < StandardError; end

  # Fenced Code Block (FCB)
  #
  # This class represents a fenced code block in a markdown document.
  # It allows for setting and getting attributes related to the code block,
  # such as body, call, headings, and more.
  #
  class FCB
    def initialize(options = {})
      @attrs = {
        block: nil,
        body: nil,
        call: nil,
        dname: nil,
        headings: [],
        id: object_id,
        indent: '',
        name: nil,
        nickname: nil,
        oname: nil,
        random: Random.new.rand,
        reqs: [],
        shell: '',
        start_line: nil,
        text: nil, # displayable in menu
        title: '',
        type: ''
      }.merge(options)
    end

    def append_block_line(line)
      @attrs[:block].push line
    end

    def pub_name(**kwargs)
      self.class.pub_name(@attrs, **kwargs)
    end

    def self.pub_name(attrs, **kwargs)
      full = attrs.fetch(:nickname, nil) || attrs.fetch(:oname, nil)
      full&.to_s&.pub_name(**kwargs)
    end

    def code_name_included?(*names)
      names.include?(@attrs[:oname])
    end

    def code_name_exp?(regexp)
      Regexp.new(regexp) =~ @attrs[:oname]
    end

    def delete_key(key)
      @attrs.delete(key)
    end

    # Removes and returns the first matching name from dependencies collection
    # Checks nickname, oname, pub_name and s2title
    # 2024-08-04 match oname for long block names
    # 2024-08-04 match nickname
    # may not exist if block name is duplicated
    def delete_matching_name!(dependencies)
      dependencies.delete(@attrs[:id]) ||
        dependencies.delete(@attrs[:dname]) ||
        dependencies.delete(@attrs[:nickname]) ||
        dependencies.delete(@attrs[:oname]) ||
        dependencies.delete(@attrs.pub_name) ||
        dependencies.delete(@attrs[:s2title])
    end

    # Derives a title from the body of an FCB object.
    # @param fcb [Object] The FCB object whose title is to be derived.
    # @return [String] The derived title.
    def derive_title_from_body
      unless (body_content = @attrs[:body])
        # empty body -> empty title
        @attrs[:title] = ''
        return
      end

      # body -> title
      @attrs[:title] = if body_content.count == 1
                         body_content.first
                       else
                         FCB.format_multiline_body_as_title(body_content)
                       end
    end

    # Processes a block to generate its summary, modifying its attributes
    #  based on various matching criteria.
    # It handles special formatting for bash blocks, extracting and setting
    #  properties like call, stdin, stdout, and dname.
    #
    # @param fcb [Object] An object representing a functional code block.
    # @return [Object] The modified functional code block with updated
    #  summary attributes.
    def for_menu!(
      appopts:,
      block_calls_scan:,
      block_name_match:,
      block_name_nick_match:,
      id: '',
      menu_format:,
      prompt:,
      table_center:
    )
      call = @attrs[:call] = @attrs[:start_line]&.match(
        Regexp.new(block_calls_scan)
      )&.fetch(1, nil)
      titlexcall = call ? @attrs[:title].sub("%#{call}", '') : @attrs[:title]

      oname = if is_split?
                @attrs[:text]
              elsif block_name_nick_match.present? &&
                    @attrs[:oname] =~ Regexp.new(block_name_nick_match)
                @attrs[:nickname] = $~[0]
                derive_title_from_body
              else
                bm = NamedCaptureExtractor.extract_named_groups(
                  titlexcall,
                  block_name_match
                )
                bm && bm[1] ? bm[:title] : titlexcall
              end
      @attrs[:title] = @attrs[:oname] = oname
      @attrs[:id] = id

      if @attrs[:type] == BlockType::UX
        begin
          case data = YAML.load(@attrs[:body].join("\n"))
          when Hash
            export = parse_yaml_of_ux_block(
              data,
              prompt: prompt
            )

            if !export.menu_format || export.menu_format.empty?
              format_symbol = option_to_format_ux_block(export)
              export.menu_format = appopts[format_symbol]
              if !export.menu_format || export.menu_format.empty?
                export.menu_format = appopts[:menu_ux_row_format]
              end
            end
            @attrs[:oname] = oname = format(export.menu_format, export.to_h)

            @attrs[:center] = table_center
            @attrs[:readonly] = export.readonly
          else
            # triggered by an empty or non-YAML block
            return NullResult.new(message: 'Invalid YAML', data: data)
          end
        rescue StandardError
          wwe 'Error processing block for menu', 'body:', @attrs[:body],
              'data', data, 'export', export
        end
      end

      @attrs[:dname] = HashDelegator.indent_all_lines(
        # yield the text and option name for the color
        (yield oname, option_to_decorate_ux_block),
        @attrs[:indent]
      )

      SuccessResult.instance
    end

    # Formats multiline body content as a title string.
    # indents all but first line with two spaces
    # so it displays correctly in menu.
    # @param body_lines [Array<String>] The lines of body content.
    # @return [String] Formatted title.
    def self.format_multiline_body_as_title(body_lines)
      body_lines.map.with_index do |line, index|
        index.zero? ? line : "  #{line}"
      end.join("\n")
    end

    def self.is_allow?(export)
      export&.allow&.present?
    end

    def is_allow?
      FCB.is_allow?(export)
    end

    def self.is_echo?(export)
      export&.echo&.present?
    end

    def is_echo?
      FCB.is_echo?(export)
    end

    def self.is_edit?(export)
      export&.edit&.present?
    end

    def is_edit?
      FCB.is_edit?(export)
    end

    def self.is_exec?(export)
      export&.exec&.present?
    end

    def is_exec?
      FCB.is_exec?(export)
    end

    def self.act_source(export)
      # If `false`, the UX block is not activated.
      # If one of `:allow`, `:echo`, `:edit`, or `:exec` is specified,
      # the value is calculated or the user is prompted.
      # If not present, the default value is `:edit`.
      if export.act.nil?
        export.act = if export.init.to_s == 'false'
                       # if export.allow.present?
                       if FCB.is_allow?(export)
                         UxActSource::ALLOW
                       # elsif export.echo.present?
                       elsif FCB.is_echo?(export)
                         UxActSource::ECHO
                       # elsif export.edit.present?
                       elsif FCB.is_edit?(export)
                         UxActSource::EDIT
                       # elsif export.exec.present?
                       elsif FCB.is_exec?(export)
                         UxActSource::EXEC
                       else
                         UxActSource::EDIT
                       end
                     elsif FCB.is_allow?(export)
                       UxActSource::ALLOW
                     else
                       UxActSource::EDIT
                     end
      end

      export.act
    end

    def self.init_source(export)
      # If `false`, there is no initial value set.
      # If a string, it is the initial value of the object variable.
      # Otherwise, if one of `:allow`, `:echo`, or `:exec` is specified,
      # the value is the output of the `echo` or `exec` evaluation
      # or the first allowed value.
      # If not present, the default value is whichever of
      # `:allow`, `:default`, `:echo`, or `:exec` is present.
      if export.init.nil?
        export.init = case
                      when FCB.is_allow?(export)
                        UxActSource::ALLOW
                      when export.default.present?
                        UxActSource::DEFAULT
                      # when export.echo.present?
                      when FCB.is_echo?(export)
                        UxActSource::ECHO
                      # when export.exec.present?
                      when FCB.is_exec?(export)
                        UxActSource::EXEC
                      else
                        UxActSource::FALSE
                      end
      end

      export.init
    end

    # :reek:ManualDispatch
    # 2024-08-04 match nickname
    def is_dependency_of?(dependency_names)
      dependency_names.include?(@attrs[:id]) ||
        dependency_names.include?(@attrs[:dname]) ||
        dependency_names.include?(@attrs[:nickname]) ||
        dependency_names.include?(@attrs[:oname]) ||
        dependency_names.include?(@attrs.pub_name) ||
        dependency_names.include?(@attrs[:s2title])
    end

    def is_disabled?
      @attrs[:disabled] == TtyMenu::DISABLE
    end

    def is_enabled?
      !is_disabled?
    end

    def is_named?(name)
      if /^ItrBlk/.match(name)
        @attrs[:id] == name
      else
        @attrs[:id] == name ||
          @attrs[:dname] == name ||
          @attrs[:nickname] == name ||
          @attrs[:oname] == name ||
          @attrs.pub_name == name ||
          @attrs[:s2title] == name
      end
    end

    # true if this is a line split block
    def is_split?
      is_split_first? || is_split_rest?
    end

    # true if this block displays its split body
    # names and nicknames are displayed instead of the body
    # ux blocks display a single line for the named variable
    # split blocks are: opts, shell, vars
    def is_split_displayed?(opts)
      @attrs[:type] != BlockType::UX &&
        !(@attrs[:start_line] =~ Regexp.new(opts[:block_name_nick_match]) ||
           @attrs[:start_line] =~ Regexp.new(opts[:block_name_match]))
    end

    # true if this is the first line in a split block
    def is_split_first?
      @attrs.fetch(:is_split_first, false)
    end

    # true if this is the second or later line in a split block
    def is_split_rest?
      @attrs.fetch(:is_split_rest, false)
    end

    # :reek:ManualDispatch
    def method_missing(method, *args, &block)
      method_name = method.to_s
      if @attrs.respond_to?(method_name)
        @attrs.send(method_name, *args, &block)
      elsif method_name[-1] == '='
        @attrs[method_name.chop.to_sym] = args[0]
      else
        @attrs[method_name.to_sym]
      end
    rescue StandardError => err
      warn("ERROR ** FCB.method_missing(method: #{method_name}," \
           " *args: #{args.inspect}, &block)")
      warn err.inspect
      warn(caller[0..4])
      raise err
    end

    def name_in_menu!(indented_multi_line)
      # Indent has been extracted from the first line,
      # remove indent from the remaining lines.
      @attrs[:dname] =
        if @attrs[:indent].empty?
          indented_multi_line
        else
          indented_multi_line.gsub("\n#{@attrs[:indent]}", "\n")
        end
    end

    # calc the decoration sybol for the current block
    def option_to_decorate_ux_block
      symbol_or_hash = BLOCK_TYPE_COLOR_OPTIONS[@attrs[:type]] || BLOCK_TYPE_COLOR_OPTIONS[true]
      if @attrs[:type] == BlockType::UX
        # only UX blocks accept a symbol or a hash
        if symbol_or_hash.is_a? Hash
          # default to the first symbol
          symbol = symbol_or_hash.first.last
          symbol_or_hash.each_key do |key|
            if key == true
              symbol = symbol_or_hash[key]
              break
            elsif symbol_or_hash[key].present? && send(key)
              symbol = symbol_or_hash[key]
              break
            end
          end
          symbol
        else
          # only symbol
          symbol_or_hash
        end
      else
        # only symbol
        symbol_or_hash
      end
    end

    def option_to_format_ux_block(export)
      if export.readonly
        :menu_ux_row_format_readonly
      else
        case FCB.act_source(export)
        when UxActSource::ALLOW
          :menu_ux_row_format_allow
        when UxActSource::ECHO
          :menu_ux_row_format_echo
        when UxActSource::EDIT
          :menu_ux_row_format_edit
        when UxActSource::EXEC
          :menu_ux_row_format_exec
        else
          # this UX block does not have a format, treat as editable
          :menu_ux_row_format_edit
        end
      end
    end

    def respond_to_missing?(method_name, include_private = false)
      @attrs.key?(method_name.to_sym) || super
    end

    def shell
      @attrs[:shell]
    end

    def shell=(value)
      @attrs[:shell] = value
    end

    def type
      @attrs[:type]
    end

    def type=(value)
      @attrs[:type] = value
    end

    def to_h
      @attrs.to_h
    end

    def to_yaml
      @attrs.to_yaml
    end

    # Expand variables in attributes
    # @return [void]
    def expand_variables_in_attributes!(pattern, replacements)
      @attrs[:raw_dname] ||= @attrs[:dname]
      @attrs[:dname] = @attrs[:dname]&.gsub(pattern) do |match|
        replacements[match]
      end

      @attrs[:raw_s0printable] ||= @attrs[:s0printable]
      @attrs[:s0printable] = @attrs[:s0printable]&.gsub(pattern) do |match|
        replacements[match]
      end

      @attrs[:raw_s1decorated] ||= @attrs[:s1decorated]
      @attrs[:s1decorated] = @attrs[:s1decorated]&.gsub(pattern) do |match|
        replacements[match]
      end

      # Replace variables in each line of `body` if `body` is present
      return unless @attrs[:body]

      # save body for YAML and re-interpretation
      @attrs[:raw_body] ||= @attrs[:body]
      @attrs[:body] = @attrs[:body]&.map do |line|
        if line.empty?
          line
        else
          line.gsub(pattern) { |match| replacements[match] }
        end
      end
    end
  end
end

if $PROGRAM_NAME == __FILE__
  require 'bundler/setup'
  Bundler.require(:default)

  require 'minitest/autorun'
  require 'yaml'

  def assert_equal_hash(expected, actual, message = nil)
    sorted_expected = sort_hash_recursively(expected)
    sorted_actual = sort_hash_recursively(actual)
    assert_equal sorted_expected, sorted_actual, message
  end

  def sort_hash_recursively(hash)
    hash.transform_values do |v|
      v.is_a?(Hash) ? sort_hash_recursively(v) : v
    end.sort.to_h
  end

  class FCBTest < Minitest::Test
    def setup
      @fcb_data = {
        block: nil,
        body: 'Sample body',
        call: 'Sample call',
        dname: 'Sample name',
        headings: %w[Header1 Header2],
        indent: '',
        name: 'Sample name',
        nickname: nil,
        oname: 'Sample name',
        reqs: %w[req1 req2],
        shell: ShellType::BASH,
        start_line: nil,
        text: 'Sample Text',
        title: 'Sample Title',
        type: 'shell'
      }
      @fcb = MarkdownExec::FCB.new(@fcb_data)
    end

    def test_initialization_with_correct_data
      assert_equal 'Sample body', @fcb.body
      assert_equal %w[Header1 Header2], @fcb.headings
    end

    def test_to_h_method
      assert_equal_hash @fcb_data.merge(
        { id: @fcb.id, random: @fcb.random }
      ), @fcb.to_h
    end

    def test_to_yaml_method
      assert_equal_hash YAML.load(@fcb_data.merge(
        { id: @fcb.id, random: @fcb.random }
      ).to_yaml), YAML.load(@fcb.to_yaml)
    end

    def test_method_missing_getter
      assert_equal 'Sample Title', @fcb.title
    end

    def test_method_missing_setter
      @fcb.title = 'New Title'
      assert_equal 'New Title', @fcb.title
    end

    # 2023-10-09 does not trigger error; treats as option name
    #
    # def test_method_missing_with_unknown_method
    #   assert_raises(NoMethodError) { @fcb.unknown_method }
    # end
  end
end
