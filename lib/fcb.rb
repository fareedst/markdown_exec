#!/usr/bin/env ruby
# frozen_string_literal: true

# encoding=utf-8

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
        headings: [],
        dname: nil,
        indent: '',
        name: nil,
        nickname: nil,
        oname: nil,
        reqs: [],
        shell: '',
        title: '',
        random: Random.new.rand,
        text: nil # displayable in menu
      }.merge(options)
    end

    def title=(value)
      @attrs[:title] = value
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
                         format_multiline_body_as_title(body_content)
                       end
    end

    private

    # Formats multiline body content as a title string.
    # indents all but first line with two spaces so it displays correctly in menu
    # @param body_lines [Array<String>] The lines of body content.
    # @return [String] Formatted title.
    def format_multiline_body_as_title(body_lines)
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
      # raise StandardError, error
      raise err # Here, we simply propagate the original error instead of wrapping it in a StandardError.
    end

    public

    def respond_to_missing?(method_name, include_private = false)
      @attrs.key?(method_name.to_sym) || super
    end

    def to_h
      @attrs
    end

    def to_yaml
      @attrs.to_yaml
    end
  end
end

if $PROGRAM_NAME == __FILE__
  require 'bundler/setup'
  Bundler.require(:default)

  require 'minitest/autorun'
  require 'yaml'

  class FCBTest < Minitest::Test
    def setup
      @fcb_data = {
        body: 'Sample body',
        call: 'Sample call',
        headings: %w[Header1 Header2],
        dname: 'Sample name',
        indent: '',
        nickname: nil,
        name: 'Sample name',
        oname: 'Sample name',
        reqs: %w[req1 req2],
        shell: 'bash',
        text: 'Sample Text',
        title: 'Sample Title'
      }
      @fcb = MarkdownExec::FCB.new(@fcb_data)
    end

    def test_initialization_with_correct_data
      assert_equal 'Sample body', @fcb.body
      assert_equal %w[Header1 Header2], @fcb.headings
    end

    def test_to_h_method
      assert_equal @fcb_data.merge({ random: @fcb.random }), @fcb.to_h
    end

    def test_to_yaml_method
      assert_equal YAML.load(@fcb_data.merge({ random: @fcb.random }).to_yaml),
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
