#!/usr/bin/env ruby
# frozen_string_literal: true

# encoding=utf-8
require_relative 'namer'
require_relative 'object_present'

module MarkdownExec
  # SavedAsset
  #
  # This class provides utilities to format and derive asset names based on
  # given parameters. The `script_name` method derives a name for a script
  # based on filename, prefix, time, and blockname. Similarly, the `stdout_name`
  # method derives a name for stdout redirection.
  #
  class SavedAsset
    DEFAULT_FTIME = '%F-%H-%M-%S'
    FILE_BLOCK_SEP = ','
    JOIN_STR = '_'
    MARK_STR = '~'

    # @param filename [String] the name of the file
    # @param prefix [String] the prefix to use
    # @param time [Time] the time object for formatting
    # @param blockname [String] the block name to include
    # @param ftime [String] the time format (default: DEFAULT_FTIME)
    # @param exts [String] the extension to append (default: '.sh')
    def initialize(
      saved_asset_format:, blockname: nil, exts: nil,
      filename: nil, ftime: DEFAULT_FTIME, join_str: nil,
      mark: nil, prefix: nil, time: nil
    )
      @filename = filename.present? ? filename.pub_name : '*'
      @prefix = prefix || '*'
      @time = time ? time.strftime(ftime) : '*'
      @blockname = blockname ? blockname.pub_name : '*'
      @exts = exts || '.*'
      @mark = mark || MARK_STR
      @join_str = join_str || JOIN_STR
      @saved_asset_format = saved_asset_format
    end

    # Generates a formatted name based on the provided parameters.
    #
    # @return [String] the generated formatted name
    def generate_name
      format(
        @saved_asset_format,
        {
          blockname: @blockname,
          exts: @exts,
          filename: @filename,
          join: @join_str,
          mark: @mark,
          prefix: @prefix,
          time: @time
        }
      )
    end
  end
end

return if $PROGRAM_NAME != __FILE__

require 'minitest/autorun'

SAVED_ASSET_FORMAT = '%{prefix}%{join}%{time}%{join}%{filename}%{join}' \
                     '%{mark}%{join}%{blockname}%{join}%{exts}'

class SavedAssetTest < Minitest::Test
  def test_script_name_with_special_characters_in_blockname
    filename = 'sample.txt'
    prefix = 'test'
    time = Time.new(2023, 1, 1, 12, 0, 0)
    blockname = 'block/1:2'

    expected_name = 'test_2023-01-01-12-00-00_sample_txt_~_block_1_2_.*'
    assert_equal expected_name, MarkdownExec::SavedAsset.new(
      blockname: blockname, filename: filename, prefix: prefix,
      saved_asset_format: SAVED_ASSET_FORMAT, time: time
    ).generate_name
  end

  def test_stdout_name_with_special_characters_in_blockname
    filename = 'sample.txt'
    prefix = 'test'
    time = Time.new(2023, 1, 1, 12, 0, 0)
    blockname = 'block/1:2'

    expected_name = 'test_2023-01-01-12-00-00_sample_txt_~_block_1_2_.*'
    assert_equal expected_name, MarkdownExec::SavedAsset.new(
      saved_asset_format: SAVED_ASSET_FORMAT,
      filename: filename, prefix: prefix, time: time, blockname: blockname
    ).generate_name
  end

  def test_wildcard_name_with_all_parameters
    filename = 'sample.txt'
    prefix = 'test'
    time = Time.new(2023, 1, 1, 12, 0, 0)
    blockname = 'block/1:2'
    expected_wildcard = 'test_2023-01-01-12-00-00_sample_txt_~_block_1_2_.*'

    assert_equal expected_wildcard, MarkdownExec::SavedAsset.new(
      saved_asset_format: SAVED_ASSET_FORMAT,
      filename: filename, prefix: prefix, time: time, blockname: blockname
    ).generate_name
  end

  def test_wildcard_name_with_missing_time
    filename = 'sample.txt'
    prefix = 'test'
    time = nil
    blockname = 'block/1:2'
    expected_wildcard = 'test_*_sample_txt_~_block_1_2_.*'

    assert_equal expected_wildcard, MarkdownExec::SavedAsset.new(
      saved_asset_format: SAVED_ASSET_FORMAT,
      filename: filename, prefix: prefix, time: time, blockname: blockname
    ).generate_name
  end

  def test_wildcard_name_with_missing_filename
    filename = nil
    prefix = 'test'
    time = Time.new(2023, 1, 1, 12, 0, 0)
    blockname = 'block/1:2'
    expected_wildcard = 'test_2023-01-01-12-00-00_*_~_block_1_2_.*'

    assert_equal expected_wildcard, MarkdownExec::SavedAsset.new(
      saved_asset_format: SAVED_ASSET_FORMAT,
      filename: filename, prefix: prefix, time: time, blockname: blockname
    ).generate_name
  end

  def test_wildcard_name_with_missing_prefix
    filename = 'sample.txt'
    prefix = nil
    time = Time.new(2023, 1, 1, 12, 0, 0)
    blockname = 'block/1:2'
    expected_wildcard = '*_2023-01-01-12-00-00_sample_txt_~_block_1_2_.*'

    assert_equal expected_wildcard, MarkdownExec::SavedAsset.new(
      saved_asset_format: SAVED_ASSET_FORMAT,
      filename: filename, prefix: prefix, time: time, blockname: blockname
    ).generate_name
  end

  def test_wildcard_name_with_missing_blockname
    filename = 'sample.txt'
    prefix = 'test'
    time = Time.new(2023, 1, 1, 12, 0, 0)
    blockname = nil
    expected_wildcard = 'test_2023-01-01-12-00-00_sample_txt_~_*_.*'

    assert_equal expected_wildcard, MarkdownExec::SavedAsset.new(
      saved_asset_format: SAVED_ASSET_FORMAT,
      filename: filename, prefix: prefix, time: time, blockname: blockname
    ).generate_name
  end

  def test_wildcard_name_with_all_missing
    filename = nil
    prefix = nil
    time = nil
    blockname = nil
    expected_wildcard = '*_*_*_~_*_.*'

    assert_equal expected_wildcard, MarkdownExec::SavedAsset.new(
      saved_asset_format: SAVED_ASSET_FORMAT,
      filename: filename, prefix: prefix, time: time, blockname: blockname
    ).generate_name
  end
end
