#!/usr/bin/env -S bundle exec ruby
# frozen_string_literal: true

# encoding=utf-8

# version 2023-10-03

require 'fileutils'
require_relative 'constants'
require_relative 'exceptions'
require_relative 'find_files'

##
# The CachedNestedFileReader class provides functionality to read file lines with the ability
# to process '#import filename' directives. When such a directive is encountered in a file,
# the corresponding 'filename' is read and its contents are inserted at that location.
# This class caches read files to avoid re-reading the same file multiple times.
# It allows clients to read lines with or without providing a block.
#
class CachedNestedFileReader
  include Exceptions

  def initialize(import_pattern: /^ *#import (.+)$/)
    @file_cache = {}
    @import_pattern = import_pattern
  end

  def error_handler(name = '', opts = {})
    Exceptions.error_handler(
      "CachedNestedFileReader.#{name} -- #{$!}",
      opts
    )
  end

  def warn_format(name, message, opts = {})
    Exceptions.warn_format(
      "CachedNestedFileReader.#{name} -- #{message}",
      opts
    )
  end

  def readlines(filename, depth = 0, context: '', import_paths: nil,
                indention: '', &block)
    if @file_cache.key?(filename)
      @file_cache[filename].each(&block) if block
      return @file_cache[filename]
    end
    raise Errno::ENOENT, filename unless filename

    directory_path = File.dirname(filename)
    processed_lines = []
    File.readlines(filename, chomp: true).each.with_index do |line, ind|
      if Regexp.new(@import_pattern) =~ line
        name_strip = $~[:name].strip
        import_indention = indention + $~[:indention]
        included_file_path = if name_strip =~ %r{^/}
                               name_strip
                             elsif import_paths
                               find_files(name_strip,
                                          import_paths + [directory_path])&.first
                             else
                               File.join(directory_path, name_strip)
                             end

        raise Errno::ENOENT, name_strip unless included_file_path

        processed_lines += readlines(included_file_path, depth + 1,
                                     context: "#{filename}:#{ind + 1}",
                                     import_paths: import_paths,
                                     indention: import_indention,
                                     &block)
      else
        nested_line = NestedLine.new(line, depth, indention)
        processed_lines.push(nested_line)
        block&.call(nested_line)
      end
    end

    @file_cache[filename] = processed_lines
  rescue Errno::ENOENT => err_filename
    warn_format('readlines', "#{err_filename} @@ #{context}",
                { abort: true })
  end
end

return if $PROGRAM_NAME != __FILE__

require 'minitest/autorun'
require 'tempfile'

class CachedNestedFileReaderTest < Minitest::Test
  def setup
    @file2 = Tempfile.new('test2.txt')
    @file2.write("ImportedLine1\nImportedLine2")
    @file2.rewind

    @file1 = Tempfile.new('test1.txt')
    @file1.write("Line1\nLine2\n #insert #{@file2.path}\nLine3")
    @file1.rewind
    @reader = CachedNestedFileReader.new(import_pattern: /^(?<indention> *)#insert (?'name'.+)$/)
  end

  def teardown
    @file1.close
    @file1.unlink

    @file2.close
    @file2.unlink
  end

  def test_readlines_without_imports
    result = @reader.readlines(@file2.path).map(&:to_s)
    assert_equal %w[ImportedLine1 ImportedLine2], result
  end

  def test_readlines_with_imports
    result = @reader.readlines(@file1.path).map(&:to_s)
    assert_equal ['Line1', 'Line2', ' ImportedLine1', ' ImportedLine2', 'Line3'],
                 result
  end

  def test_caching_functionality
    # First read

    result1 = @reader.readlines(@file2.path).map(&:to_s)

    # Simulate file content change
    @file2.reopen(@file2.path, 'w') { |f| f.write('ChangedLine') }

    # Second read (should read from cache, not the changed file)
    result2 = @reader.readlines(@file2.path).map(&:to_s)

    assert_equal result1, result2
    assert_equal %w[ImportedLine1 ImportedLine2], result2
  end
end
