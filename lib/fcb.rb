#!/usr/bin/env ruby
# frozen_string_literal: true

# encoding=utf-8
require 'digest'
require_relative 'namer'

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
        body: nil,
        call: nil,
        dname: nil,
        headings: [],
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
                         FCB::format_multiline_body_as_title(body_content)
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
      block_calls_scan: @delegate_object[:block_calls_scan],
      block_name_match: @delegate_object[:block_name_match],
      block_name_nick_match: @delegate_object[:block_name_nick_match],
      id: ''
    )
      call = @attrs[:call] = @attrs[:start_line]&.match(
        Regexp.new(block_calls_scan)
      )&.fetch(1, nil)
      titlexcall = call ? @attrs[:title].sub("%#{call}", '') : @attrs[:title]

      oname = if block_name_nick_match.present? &&
                 @attrs[:oname] =~ Regexp.new(block_name_nick_match)
                @attrs[:nickname] = $~[0]
                derive_title_from_body
              else
                bm = NamedCaptureExtractor::extract_named_groups(
                  titlexcall,
                  block_name_match
                )
                bm && bm[1] ? bm[:title] : titlexcall
              end
      @attrs[:title] = @attrs[:oname] = oname
      @attrs[:id] = id
      @attrs[:dname] = HashDelegator.indent_all_lines(
        (yield oname, BLOCK_TYPE_COLOR_OPTIONS[@attrs[:type]]),
        @attrs[:indent]
      )
    end

    private

    # Formats multiline body content as a title string.
    # indents all but first line with two spaces
    # so it displays correctly in menu.
    # @param body_lines [Array<String>] The lines of body content.
    # @return [String] Formatted title.
    def self.format_multiline_body_as_title(body_lines)
      body_lines.map.with_index do |line, index|
        index.zero? ? line : "  #{line}"
      end.join("\n") << "\n"
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

    public

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

    # Expand variables in `dname` and `body` attributes
    def expand_variables_in_attributes!(pattern, replacements)
      ### update name, nickname, title, label ???

      # Replace variables in `dname` using the replacements dictionary
      @attrs[:dname] = @attrs[:dname].gsub(pattern) do |match|
        replacements[match]
      end

      # Replace variables in each line of `body` if `body` is present
      if @attrs[:body]
        @attrs[:body] = @attrs[:body].map do |line|
          if line.empty?
            line
          else
            line.gsub(pattern) { |match| replacements[match] }
          end
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
    hash.each_with_object({}) do |(k, v), new_hash|
      new_hash[k] = v.is_a?(Hash) ? sort_hash_recursively(v) : v
    end.sort.to_h
  end

  class FCBTest < Minitest::Test
    def setup
      @fcb_data = {
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
      assert_equal_hash @fcb_data.merge({ random: @fcb.random }), @fcb.to_h
    end

    def test_to_yaml_method
      assert_equal_hash YAML.load(@fcb_data.merge({ random: @fcb.random })
                                           .to_yaml),
                        YAML.load(@fcb.to_yaml)
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
