#!/usr/bin/env -S bundle exec ruby
# frozen_string_literal: true

# encoding=utf-8

# version 2023-10-03

require 'fileutils'
require_relative 'constants'
require_relative 'exceptions'
require_relative 'find_files'

##
# The CachedNestedFileReader class provides functionality to read file
# lines with the ability to process '#import filename' directives. When
# such a directive is encountered in a file, the corresponding 'filename'
# is read and its contents are inserted at that location.
# This class caches read files to avoid re-reading the same file multiple
# times.
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

  # yield each line to the block
  # return the processed lines
  def readlines(
    filename, depth = 0, context: '', import_paths: nil,
    indention: '', substitutions: {}, use_template_delimiters: false, &block
  )
    cache_key = build_cache_key(filename, substitutions)
    if @file_cache.key?(cache_key)
      @file_cache[cache_key].each(&block) if block
      return @file_cache[cache_key]
    end
    raise Errno::ENOENT, filename unless filename

    directory_path = File.dirname(filename)
    processed_lines = []
    File.readlines(filename, chomp: true).each.with_index do |line, ind|
      if Regexp.new(@import_pattern) =~ line
        name_strip = $~[:name].strip
        params_string = $~[:params] || ''
        import_indention = indention + $~[:indention]

        # Parse parameters for text substitution
        import_substitutions = parse_import_params(params_string)
        merged_substitutions = substitutions.merge(import_substitutions)

        included_file_path =
          if name_strip =~ %r{^/}
            name_strip
          elsif import_paths
            find_files(name_strip,
                       import_paths + [directory_path])&.first
          else
            File.join(directory_path, name_strip)
          end

        raise Errno::ENOENT, name_strip unless included_file_path

        imported_lines = readlines(
          included_file_path, depth + 1,
          context: "#{filename}:#{ind + 1}",
          import_paths: import_paths,
          indention: import_indention,
          substitutions: merged_substitutions,
          use_template_delimiters: use_template_delimiters,
          &block
        )

        # Apply text substitutions to imported content
        processed_imported_lines = apply_substitutions(
          imported_lines,
          import_substitutions, use_template_delimiters
        )
        processed_lines += processed_imported_lines
      else
        # Apply substitutions to the current line
        substituted_line = apply_line_substitutions(line, substitutions,
                                                    use_template_delimiters)
        nested_line = NestedLine.new(substituted_line, depth, indention,
                                     filename, ind)
        processed_lines.push(nested_line)
        block&.call(nested_line)
      end
    end

    @file_cache[cache_key] = processed_lines
  rescue Errno::ENOENT => err
    warn_format('readlines', "#{err} @@ #{context}",
                { abort: true })
  end

  private

  # Parse key=value parameters from the import line
  def parse_import_params(params_string)
    return {} if params_string.nil? || params_string.strip.empty?

    params = {}
    # Match key=value pairs, handling quoted values
    params_string.scan(
      /([A-Za-z_]\w*)=(?:"([^"]*)"|'([^']*)'|(\S+))/
    ) do |key, quoted_double, quoted_single, unquoted|
      value = quoted_double || quoted_single || unquoted
      # skip replacement of equal values
      # otherwise, the text is not available for other substitutions
      params[key] = value if key != value
    end
    params
  end

  # Apply text substitutions to a collection of NestedLine objects
  def apply_substitutions(
    lines, substitutions, use_template_delimiters = false
  )
    return lines if substitutions.empty?

    lines.map do |nested_line|
      substituted_text = apply_line_substitutions(
        nested_line.text,
        substitutions, use_template_delimiters
      )
      NestedLine.new(substituted_text, nested_line.depth, nested_line.indention,
                     nested_line.filename, nested_line.index)
    end
  end

  # Apply text substitutions to a single line
  def apply_line_substitutions(line, substitutions,
                               use_template_delimiters = false)
    return line if substitutions.empty?

    substituted_line = line.dup
    if use_template_delimiters
      # Replace template-style placeholders: ${KEY} or {{KEY}}
      substitutions.each do |key, value|
        substituted_line = substituted_line.gsub(/\$\{#{Regexp.escape(key)}\}/,
                                                 value)
        substituted_line = substituted_line.gsub(
          /\{\{#{Regexp.escape(key)}\}\}/, value
        )
      end
    else
      # use temporary placeholders to avoid double replacement
      temp_placeholders = {}

      # Replace each key with a unique temporary placeholder
      substitutions.each_with_index do |(key, value), index|
        temp_placeholder = "__MDE_TEMP_#{index}__"
        # pattern = /\b#{Regexp.escape(key)}\b/
        pattern = Regexp.new(Regexp.escape(key))
        substituted_line = substituted_line.gsub(pattern, temp_placeholder)
        temp_placeholders[temp_placeholder] = value
      end

      # Replace temporary placeholders with actual values
      temp_placeholders.each do |placeholder, value|
        substituted_line = substituted_line.gsub(placeholder, value)
      end

    end
    substituted_line
  end

  # Build cache key that includes substitutions to avoid conflicts
  def build_cache_key(filename, substitutions)
    return filename if substitutions.empty?

    substitution_hash = substitutions.sort.to_h.hash
    "#{filename}##{substitution_hash}"
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
    @file1.write("Line1\nLine2\n @import #{@file2.path}\nLine3")
    @file1.rewind
    @reader = CachedNestedFileReader.new(
      import_pattern: /^(?<indention> *)@import +(?<name>\S+)(?<params>(?: +[A-Za-z_]\w*=(?:"[^"]*"|'[^']*'|\S+))*) *$/
    )
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

  def test_readlines_with_imports_and_substitutions
    file_with_substitution = Tempfile.new('test_substitution.txt')
    file_with_substitution.write("Server: HOST\nPort: PORT")
    file_with_substitution.rewind

    file_importing = Tempfile.new('test_importing.txt')
    file_importing.write("Config:\n @import #{file_with_substitution.path} HOST=localhost PORT=8080\nEnd")
    file_importing.rewind

    result = @reader.readlines(file_importing.path).map(&:to_s)
    assert_equal ['Config:', ' Server: localhost', ' Port: 8080', 'End'],
                 result

    file_with_substitution.close
    file_with_substitution.unlink
    file_importing.close
    file_importing.unlink
  end

  def test_readlines_with_template_delimiters
    file_with_template = Tempfile.new('test_template.txt')
    file_with_template.write("API_URL=${API_URL}\nVERSION={{VERSION}}")
    file_with_template.rewind

    file_importing = Tempfile.new('test_importing.txt')
    file_importing.write("Config:\n @import #{file_with_template.path} API_URL=https://api.example.com VERSION=1.2.3\nEnd")
    file_importing.rewind

    result = @reader.readlines(file_importing.path,
                               use_template_delimiters: true).map(&:to_s)
    assert_equal ['Config:', ' API_URL=https://api.example.com', ' VERSION=1.2.3', 'End'],
                 result

    file_with_template.close
    file_with_template.unlink
    file_importing.close
    file_importing.unlink
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
