#!/usr/bin/env ruby
# frozen_string_literal: true

# encoding=utf-8

# version 2023-10-03

##
# The CachedNestedFileReader class provides functionality to read file lines with the ability
# to process '#import filename' directives. When such a directive is encountered in a file,
# the corresponding 'filename' is read and its contents are inserted at that location.
# This class caches read files to avoid re-reading the same file multiple times.
# It allows clients to read lines with or without providing a block.
#
class CachedNestedFileReader
  def initialize(import_pattern: /^ *#import (.+)$/)
    @file_cache = {}
    @import_pattern = import_pattern
  end

  def readlines(filename, &block)
    if @file_cache.key?(filename)
      @file_cache[filename].each(&block) if block_given?
      return @file_cache[filename]
    end

    directory_path = File.dirname(filename)
    lines = File.readlines(filename, chomp: true)
    processed_lines = []

    lines.each do |line|
      if (match = line.match(@import_pattern))
        included_file_path = if match[1].strip.match %r{^/}
                               match[1].strip
                             else
                               File.join(directory_path, match[1].strip)
                             end
        processed_lines += readlines(included_file_path, &block)
      else
        processed_lines.push(line)
        yield line if block_given?
      end
    end

    @file_cache[filename] = processed_lines
  end

  private

  def fetch_lines(filename)
    @fetch_lines_cache[filename] ||= File.readlines(filename, chomp: true)
  end
end

if $PROGRAM_NAME == __FILE__
  require 'minitest/autorun'
  require 'tempfile'

  ##
  # The CachedNestedFileReaderTest class provides testing for
  # the CachedNestedFileReader class.
  #
  class CachedNestedFileReaderTest < Minitest::Test
    def setup
      @file2 = Tempfile.new('test2.txt')
      @file2.write("ImportedLine1\nImportedLine2")
      @file2.rewind

      @file1 = Tempfile.new('test1.txt')
      @file1.write("Line1\nLine2\n #insert #{@file2.path}\nLine3")
      @file1.rewind
      @reader = CachedNestedFileReader.new(import_pattern: /^ *#insert (.+)$/)
    end

    def teardown
      @file1.close
      @file1.unlink

      @file2.close
      @file2.unlink
    end

    def test_readlines_without_imports
      result = []
      @reader.readlines(@file2.path) { |line| result << line }
      assert_equal %w[ImportedLine1 ImportedLine2], result
    end

    def test_readlines_with_imports
      result = []
      @reader.readlines(@file1.path) { |line| result << line }
      assert_equal %w[Line1 Line2 ImportedLine1 ImportedLine2 Line3], result
    end

    def test_caching_functionality
      # First read
      result1 = []
      @reader.readlines(@file2.path) { |line| result1 << line }

      # Simulate file content change
      @file2.reopen(@file2.path, 'w') { |f| f.write('ChangedLine') }

      # Second read (should read from cache, not the changed file)
      result2 = []
      @reader.readlines(@file2.path) { |line| result2 << line }

      assert_equal result1, result2
      assert_equal %w[ImportedLine1 ImportedLine2], result2
    end
  end
end
