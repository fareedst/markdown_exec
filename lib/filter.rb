#!/usr/bin/env ruby
# frozen_string_literal: true

# encoding=utf-8

module MarkdownExec
  # Filter
  #
  # The Filter class provides utilities to determine the inclusion of fenced code blocks (FCB)
  # based on a set of provided options. The primary function, `fcb_select?`, checks
  # various properties of an FCB and decides whether to include or exclude it.
  #
  # :reek:UtilityFunction
  class Filter
    #     def self.fcb_title_parse(opts, fcb_title)
    #       fcb_title.match(Regexp.new(opts[:fenced_start_ex_match])).named_captures.sym_keys
    #     end

    def self.fcb_select?(options, fcb)
      # options.tap_yaml 'options'
      # fcb.tap_inspect 'fcb'
      name = fcb.fetch(:name, '').tap_inspect 'name'
      shell = fcb.fetch(:shell, '').tap_inspect 'shell'

      ## include hidden blocks for later use
      #
      name_default = true
      name_exclude = nil
      name_select = nil
      shell_default = true
      shell_exclude = nil
      shell_select = nil
      hidden_name = nil

      if name.present? && options[:block_name]
        if name =~ /#{options[:block_name]}/
          '=~ block_name'.tap_puts
          name_select = true
          name_exclude = false
        else
          '!~ block_name'.tap_puts
          name_exclude = true
          name_select = false
        end
      end

      if name.present? && name_select.nil? && options[:select_by_name_regex].present?
        '+select_by_name_regex'.tap_puts
        name_select = (!!(name =~ /#{options[:select_by_name_regex]}/)).tap_inspect 'name_select'
      end

      if shell.present? && options[:select_by_shell_regex].present?
        '+select_by_shell_regex'.tap_puts
        shell_select = (!!(shell =~ /#{options[:select_by_shell_regex]}/)).tap_inspect 'shell_select'
      end

      if name.present? && name_exclude.nil? && options[:exclude_by_name_regex].present?
        '-exclude_by_name_regex'.tap_puts
        name_exclude = (!!(name =~ /#{options[:exclude_by_name_regex]}/)).tap_inspect 'name_exclude'
      end

      if shell.present? && options[:exclude_by_shell_regex].present?
        '-exclude_by_shell_regex'.tap_puts
        shell_exclude = (!!(shell =~ /#{options[:exclude_by_shell_regex]}/)).tap_inspect 'shell_exclude'
      end

      if name.present? && options[:hide_blocks_by_name] &&
         options[:block_name_hidden_match].present?
        '+block_name_hidden_match'.tap_puts
        hidden_name = (!!(name =~ /#{options[:block_name_hidden_match]}/)).tap_inspect 'hidden_name'
      end

      if shell.present? && options[:hide_blocks_by_shell] &&
         options[:block_shell_hidden_match].present?
        '-hide_blocks_by_shell'.tap_puts
        (!!(shell =~ /#{options[:block_shell_hidden_match]}/)).tap_inspect 'hidden_shell'
      end

      if options[:bash_only]
        '-bash_only'.tap_puts
        shell_default = (shell == 'bash').tap_inspect 'shell_default'
      end

      ## name matching does not filter hidden blocks
      #
      case
      when options[:no_chrome] && fcb.fetch(:chrome, false)
        '-no_chrome'.tap_puts
        false
      when options[:exclude_expect_blocks] && shell == 'expect'
        '-exclude_expect_blocks'.tap_puts
        false
      when hidden_name == true
        true
      when name_exclude == true, shell_exclude == true,
           name_select == false, shell_select == false
        false
      when name_select == true, shell_select == true
        true
      when name_default == false, shell_default == false
        false
      else
        true
      end.tap_inspect
    rescue StandardError => err
      warn("ERROR ** Filter::fcb_select?(); #{err.inspect}")
      raise err
    end
  end
end

if $PROGRAM_NAME == __FILE__
  require 'minitest/autorun'

  require_relative 'tap'
  include Tap

  class FilterTest < Minitest::Test
    def test_no_chrome_condition
      options = { no_chrome: true }
      fcb = { chrome: true }
      refute MarkdownExec::Filter.fcb_select?(options, fcb)
    end

    def test_exclude_expect_blocks_condition
      options = { exclude_expect_blocks: true }
      fcb = { shell: 'expect' }
      refute MarkdownExec::Filter.fcb_select?(options, fcb)
    end

    def test_hidden_name_condition
      options = { hide_blocks_by_name: true, block_name_hidden_match: 'hidden' }
      fcb = { name: 'hidden_block' }
      assert MarkdownExec::Filter.fcb_select?(options, fcb)
    end

    def test_name_exclude_condition
      options = { block_name: 'test' }
      fcb = { name: 'sample' }
      refute MarkdownExec::Filter.fcb_select?(options, fcb)
    end

    def test_shell_exclude_condition
      options = { exclude_by_shell_regex: 'exclude_this' }
      fcb = { shell: 'exclude_this_shell' }
      refute MarkdownExec::Filter.fcb_select?(options, fcb)
    end

    def test_name_select_condition
      options = { select_by_name_regex: 'select' }
      fcb = { name: 'select_this' }
      assert MarkdownExec::Filter.fcb_select?(options, fcb)
    end

    def test_shell_select_condition
      options = { select_by_shell_regex: 'select_this' }
      fcb = { shell: 'select_this_shell' }
      assert MarkdownExec::Filter.fcb_select?(options, fcb)
    end

    def test_bash_only_condition_true
      options = { bash_only: true }
      fcb = { shell: 'bash' }
      assert MarkdownExec::Filter.fcb_select?(options, fcb)
    end

    def test_bash_only_condition_false
      options = { bash_only: true }
      fcb = { shell: 'zsh' }
      refute MarkdownExec::Filter.fcb_select?(options, fcb)
    end

    def test_default_case
      options = {}
      fcb = {}
      assert MarkdownExec::Filter.fcb_select?(options, fcb)
    end
  end
end
