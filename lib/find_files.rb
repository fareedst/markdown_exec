#!/usr/bin/env bundle exec ruby
# frozen_string_literal: true

# encoding=utf-8
# version 2024-01-15

# Finds files matching a given pattern within specified directory paths while optionally excluding
# "." and ".." entries and directory names from the results.
#
# The function takes a pattern (filename or pattern with wildcards), an array of paths, and an
# option to exclude directory entries and special entries "." and "..".
# It searches for files matching the pattern within each of the specified paths. Hidden files
# are included in the search. The search can include subdirectories depending on the
# path specification (e.g., 'dir/**' for recursive search).
#
# Args:
#   pattern (String): A filename or a pattern string with wildcards.
#   paths (Array<String>): An array of directory paths where the search will be performed.
#     Paths can include wildcards for recursive search.
#   exclude_dirs (Boolean): If true, excludes "." and ".." and directory names from the results.
#
# Returns:
#   Array<String>: A unique list of file paths that match the given pattern in the specified paths,
#   excluding directories if exclude_dirs is true.
#
# Example:
#   find_files('version.rb', ['lib/**', 'spec'], true)
#   # This might return file paths like ['lib/markdown_exec/version.rb', 'spec/version_spec.rb'].
def find_files(pattern, paths = ['', Dir.pwd], exclude_dirs: false)
  matched_files = []

  paths.each do |path_with_wildcard|
    # Combine the path with the wildcard and the pattern
    search_pattern = File.join(path_with_wildcard, pattern)

    # Use Dir.glob with the File::FNM_DOTMATCH flag to include hidden files
    files = Dir.glob(search_pattern, File::FNM_DOTMATCH)

    # Optionally exclude "." and ".." and directory names
    files.reject! { |file| file.end_with?('/.', '/..') || File.directory?(file) } if exclude_dirs

    matched_files += files
  end

  matched_files.uniq
end

return if $PROGRAM_NAME != __FILE__

# example CLI
# ruby lib/find_files.rb import1.md 'spec:fixtures/**:examples/**' ':'

if ARGV.length.positive?
  pattern, path_list, sep = ARGV
  puts find_files(pattern, path_list.split(sep || ':'))

  return
end

require 'bundler/setup'
Bundler.require(:default)

require 'minitest/autorun'

class TestFindFiles < Minitest::Test
  def test_find_files_no_recursion
    # Test with no recursive directories
    result = find_files('cli.rb', ['lib'])
    assert_includes result, 'lib/cli.rb'
  end

  def test_find_files_with_recursion
    # Test with recursive directories
    expected_files = [
      'lib/cli.rb',
      'lib/colorize.rb',
      'lib/dev/watchfile.sh',
      'lib/markdown_exec.rb',
      'lib/markdown_exec/version.rb'
    ]
    result = find_files('*', ['lib/**'])
    expected_files.each do |file|
      assert_includes result, file
    end
  end

  def test_find_files_in_multiple_paths
    # Test with multiple paths
    expected_files = [
      'lib/markdown_exec/version.rb',
      'spec/cli_spec.rb',
      'spec/env_spec.rb',
      'spec/markdown_exec_spec.rb',
      'spec/tap_spec.rb'
    ]
    result = find_files('*', ['lib/**', 'spec'])
    expected_files.each do |file|
      assert_includes result, file
    end
  end

  def test_find_files_with_hidden_files
    # Test to ensure hidden files are also found
    result = find_files('.gitignore', ['.'])
    assert_includes result, './.gitignore'
  end
end
