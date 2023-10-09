#!/usr/bin/env ruby
# frozen_string_literal: true

# encoding=utf-8

module MarkdownExec
  # SavedFilesMatcher
  #
  # This class is responsible for matching saved files based on the given pattern.
  # It can list all matching files, retrieve the most recent file, or a list of
  # most recent files.
  #
  class SavedFilesMatcher
    # Lists all files in the specified folder that match the given glob pattern
    def self.list_all(folder, glob)
      Dir.glob(File.join(folder, glob))
    end

    # Retrieves the most recent file from the specified folder that matches the given glob pattern
    def self.most_recent(folder, glob, arr = nil)
      arr = list_all(folder, glob) if arr.nil?
      return if arr.count < 1

      arr.max
    end

    # Retrieves a list of the most recent files (up to list_count) from the specified folder
    # that match the given glob pattern
    def self.most_recent_list(folder, glob, list_count, arr = nil)
      arr = list_all(folder, glob) if arr.nil?
      return if arr.empty?

      arr.sort[-[arr.count, list_count].min..].reverse
    end
  end
end

if $PROGRAM_NAME == __FILE__
  require 'minitest/autorun'

  class SavedFilesMatcherTest < Minitest::Test
    def setup
      @folder = 'fixtures'
      @glob = '*.md'
    end

    def test_list_all
      assert_kind_of Array, MarkdownExec::SavedFilesMatcher.list_all(@folder, @glob)
    end

    def test_most_recent
      assert_match(/\.md$/, MarkdownExec::SavedFilesMatcher.most_recent(@folder, @glob))
    end

    def test_most_recent_list
      result = MarkdownExec::SavedFilesMatcher.most_recent_list(@folder, @glob, 5)
      assert_kind_of Array, result
      assert_operator result.size, :<=, 16
    end
  end
end
