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
    def self.fcb_select?(options, fcb)
      filters = {
        name_default: true,
        name_exclude: nil,
        name_select: nil,
        shell_default: true,
        shell_exclude: nil,
        shell_select: nil,
        hidden_name: nil
      }

      name = fcb.fetch(:name, '')
      shell = fcb.fetch(:shell, '')

      apply_name_filters(options, filters, name)
      apply_shell_filters(options, filters, shell)
      apply_other_filters(options, filters, fcb)

      evaluate_filters(options, filters)
    rescue StandardError => err
      warn("ERROR ** Filter::fcb_select?(); #{err.inspect}")
      raise err
    end

    def self.apply_name_filters(options, filters, name)
      if name.present? && options[:block_name]
        if name =~ /#{options[:block_name]}/
          filters[:name_select] = true
          filters[:name_exclude] = false
        else
          filters[:name_exclude] = true
          filters[:name_select] = false
        end
      end

      if name.present? && filters[:name_select].nil? && options[:select_by_name_regex].present?
        filters[:name_select] = !!(name =~ /#{options[:select_by_name_regex]}/)
      end

      unless name.present? && filters[:name_exclude].nil? && options[:exclude_by_name_regex].present?
        return
      end

      filters[:name_exclude] = !!(name =~ /#{options[:exclude_by_name_regex]}/)
    end

    def self.apply_shell_filters(options, filters, shell)
      filters[:shell_expect] = shell == 'expect'

      if shell.present? && options[:select_by_shell_regex].present?
        filters[:shell_select] = !!(shell =~ /#{options[:select_by_shell_regex]}/)
      end

      return unless shell.present? && options[:exclude_by_shell_regex].present?

      filters[:shell_exclude] = !!(shell =~ /#{options[:exclude_by_shell_regex]}/)
    end

    def self.apply_other_filters(options, filters, fcb)
      name = fcb.fetch(:name, '')
      shell = fcb.fetch(:shell, '')
      filters[:fcb_chrome] = fcb.fetch(:chrome, false)

      if name.present? && options[:hide_blocks_by_name] &&
         options[:block_name_hidden_match].present?
        filters[:hidden_name] = !!(name =~ /#{options[:block_name_hidden_match]}/)
      end

      if shell.present? && options[:hide_blocks_by_shell] &&
         options[:block_shell_hidden_match].present?
        !!(shell =~ /#{options[:block_shell_hidden_match]}/)
      end

      return unless options[:bash_only]

      filters[:shell_default] = (shell == 'bash')
    end

    def self.evaluate_filters(options, filters)
      if options[:no_chrome] && filters[:fcb_chrome]
        false
      elsif options[:exclude_expect_blocks] && filters[:shell_expect]
        false
      elsif filters[:hidden_name] == true
        true
      elsif filters[:name_exclude] == true || filters[:shell_exclude] == true || filters[:name_select] == false || filters[:shell_select] == false
        false
      elsif filters[:name_select] == true || filters[:shell_select] == true
        true
      elsif filters[:name_default] == false || filters[:shell_default] == false
        false
      else
        true
      end
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
