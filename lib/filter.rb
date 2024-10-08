#!/usr/bin/env ruby
# frozen_string_literal: true

# encoding=utf-8

# Determines if a given block type is selected based on a list.
#
# @param selected_types [Array<String>, nil] An array of block types to
# check against. If nil, all types are considered selected.
# @param type [String] The block type to check for selection.
# @return [Boolean] Returns true if the type is selected or if
# selected_types is nil (indicating all types are selected).
def block_type_selected?(selected_types, type)
  !selected_types || selected_types.include?(type)
end

module MarkdownExec
  # Filter
  #
  # The Filter class provides utilities to determine the inclusion of
  # fenced code blocks (FCB) based on a set of provided options. The
  # primary function, `fcb_select?`, checks various properties of an
  # FCB and decides whether to include or exclude it.
  #
  # :reek:UtilityFunction
  class Filter
    # Determines whether to include or exclude a fenced code block
    # (FCB) based on the provided options.
    #
    # @param options [Hash] The options used for filtering FCBs.
    # @param fcb [Hash] The fenced code block to be evaluated.
    # @return [Boolean] True if the FCB should be included; false if
    # it should be excluded.
    # @raise [StandardError] If an error occurs during the evaluation.
    #
    def self.fcb_select?(options, fcb)
      filters = {
        name_default: true,
        name_exclude: nil,
        name_select: nil,
        shell_default: true,
        shell_exclude: nil,
        shell_select: nil,
        hidden_name: nil,
        include_name: nil,
        wrap_name: nil
      }

      name = fcb.oname
      shell = fcb.shell

      apply_name_filters(options, filters, name)
      apply_shell_filters(options, filters, shell)
      apply_other_filters(options, filters, fcb)

      evaluate_filters(options, filters)
    rescue StandardError
      warn("ERROR ** Filter::fcb_select?(); #{$!.inspect}")
      raise ArgumentError, $!
    end

    # Applies name-based filters to determine whether to include or
    # exclude a fenced code block (FCB)
    # based on the block's name and provided options.
    #
    # @param options [Hash] The options used for filtering FCBs.
    # @param filters [Hash] The filter settings to be updated.
    # @param name [String] The name of the fenced code block.
    #
    def self.apply_name_filters(options, filters, name)
      filters[:name_select] = true
      filters[:name_exclude] = false

      if name.present? && filters[:name_select].nil? && options[:select_by_name_regex].present?
        filters[:name_select] =
          !!(name =~ /#{options[:select_by_name_regex]}/)
      end

      unless name.present? && filters[:name_exclude].nil? && options[:exclude_by_name_regex].present?
        return
      end

      filters[:name_exclude] =
        !!(name =~ /#{options[:exclude_by_name_regex]}/)
    end

    # Applies shell-based filters to determine whether to include or
    # exclude a fenced code block (FCB)
    # based on the block's shell type and provided options.
    #
    # @param options [Hash] The options used for filtering FCBs.
    # @param filters [Hash] The filter settings to be updated.
    # @param shell [String] The shell type of the fenced code block.
    #
    def self.apply_shell_filters(options, filters, shell)
      filters[:shell_expect] = shell == 'expect'

      if shell.empty? && options[:bash_only]
        filters[:shell_exclude] = true
        return
      end

      if shell.present? && options[:select_by_shell_regex].present?
        filters[:shell_select] =
          !!(shell =~ /#{options[:select_by_shell_regex]}/)
      end

      return unless shell.present? && options[:exclude_by_shell_regex].present?

      filters[:shell_exclude] =
        !!(shell =~ /#{options[:exclude_by_shell_regex]}/)
    end

    # Applies additional filters to determine whether to include or
    # exclude a fenced code block (FCB)
    # based on various criteria and provided options.
    #
    # @param options [Hash] The options used for filtering FCBs.
    # @param filters [Hash] The filter settings to be updated.
    # @param fcb [Hash] The fenced code block to be evaluated.
    #
    def self.apply_other_filters(options, filters, fcb)
      name = fcb.oname
      shell = fcb.shell
      filters[:fcb_chrome] = fcb.fetch(:chrome, false)

      if name.present? && options[:hide_blocks_by_name]
        filters[:hidden_name] =
          !!(options[:block_name_hidden_match].present? &&
                    name =~ /#{options[:block_name_hidden_match]}/)
      end
      filters[:include_name] =
        !!(options[:block_name_include_match].present? &&
                  name =~ /#{options[:block_name_include_match]}/)
      filters[:wrap_name] =
        !!(options[:block_name_wrapper_match].present? &&
                  name =~ /#{options[:block_name_wrapper_match]}/)

      filters[:shell_default] = (shell == BlockType::BASH)
    end

    # Evaluates the filter settings to make a final decision on
    # whether to include or exclude a fenced
    # code block (FCB) based on the provided options.
    #
    # @param options [Hash] The options used for filtering FCBs.
    # @param filters [Hash] The filter settings to be evaluated.
    # @return [Boolean] True if the FCB should be included; false
    # if it should be excluded.
    #
    def self.evaluate_filters(options, filters)
      if filters[:depth] == true
        false
      elsif filters[:fcb_chrome] == true
        !options[:no_chrome]
      elsif options[:exclude_expect_blocks] && filters[:shell_expect] == true
        false
      elsif filters[:hidden_name] == true
        false
      elsif filters[:include_name] == true
        true
      elsif filters[:wrap_name] == true
        true
      elsif filters[:name_exclude] == true || filters[:shell_exclude] == true ||
            filters[:name_select] == false || filters[:shell_select] == false
        false
      elsif filters[:name_select] == true || filters[:shell_select] == true
        true
      elsif filters[:name_default] == false || filters[:shell_default] == false
        false
      else
        true
      end
    end

    # check if a block is not in the menu based on multiple match patterns
    #
    # @param options [Hash] Options hash containing various settings
    # @param fcb [Hash] Hash representing a file code block
    # @param match_patterns [Array<String>] Array of regular expression patterns for matching
    # @return [Boolean] True if the block should not be in the menu, false otherwise
    def self.prepared_not_in_menu?(options, fcb, match_patterns)
      return false unless fcb.shell == BlockType::BASH

      match_patterns.any? do |pattern|
        options[pattern].present? && fcb.oname =~ /#{options[pattern]}/
      end
    end

    # Yields to the provided block with specified parameters if certain conditions are met.
    # The method checks if a block is given, if the selected_types include :blocks,
    # and if the fcb_select? method returns true for the given fcb.
    #
    # @param fcb [Object] The object to be evaluated and potentially passed to the block.
    # @param selected_types [Array<Symbol>] A collection of message types, one of which must be :blocks.
    # @param block [Block] A block to be called if conditions are met.
    def self.yield_to_block_if_applicable(fcb, selected_types, configuration = {}, &block)
      if block_given? &&
         block_type_selected?(selected_types, :blocks) &&
         fcb_select?(configuration, fcb)
        block.call :blocks, fcb
      end
    end
  end
end

if $PROGRAM_NAME == __FILE__
  require 'bundler/setup'
  Bundler.require(:default)

  require 'fcb'
  require 'minitest/autorun'

  module MarkdownExec
    class FilterTest < Minitest::Test
      def setup
        @options = {}
        @fcb = FCB.new(
          dname: nil,
          oname: nil
        )
      end

      # Tests for fcb_select? method
      def test_no_chrome_condition
        @options[:no_chrome] = true
        @fcb[:chrome] = true
        refute Filter.fcb_select?(@options, @fcb)
      end

      def test_exclude_expect_blocks_condition
        @options[:exclude_expect_blocks] = true
        @fcb.shell = 'expect'
        refute Filter.fcb_select?(@options, @fcb)
      end

      def test_hidden_name_condition
        @options[:hide_blocks_by_name] = true
        @options[:block_name_hidden_match] = 'hidden'
        @fcb.oname = 'hidden_block'
        refute Filter.fcb_select?(@options, @fcb)
      end

      def test_include_name_condition
        @options[:hide_blocks_by_name] = true
        @options[:block_name_indlude_match] = 'include'
        @fcb.oname = 'include_block'
        assert Filter.fcb_select?(@options, @fcb)
      end

      def test_wrap_name_condition
        @options[:hide_blocks_by_name] = true
        @options[:block_name_wrapper_match] = 'wrap'
        @fcb.oname = 'wrap_block'
        assert Filter.fcb_select?(@options, @fcb)
      end

      def test_shell_exclude_condition
        @options[:exclude_by_shell_regex] = 'exclude_this'
        @fcb.shell = 'exclude_this_shell'
        refute Filter.fcb_select?(@options, @fcb)
      end

      def test_name_select_condition
        @options[:select_by_name_regex] = 'select'
        @fcb.oname = 'select_this'
        assert Filter.fcb_select?(@options, @fcb)
      end

      def test_shell_select_condition
        @options[:select_by_shell_regex] = 'select_this'
        @fcb.shell = 'select_this_shell'
        assert Filter.fcb_select?(@options, @fcb)
      end

      def test_bash_only_condition_true
        @options[:bash_only] = true
        @fcb.shell = BlockType::BASH
        assert Filter.fcb_select?(@options, @fcb)
      end

      def test_default_case
        assert Filter.fcb_select?(@options, @fcb)
      end
    end
  end
end
