#!/usr/bin/env ruby
# frozen_string_literal: true

# encoding=utf-8

module MarkdownExec
  # SavedAsset
  #
  # This class provides utilities to format and derive asset names based on
  # given parameters. The `script_name` method derives a name for a script
  # based on filename, prefix, time, and blockname. Similarly, the `stdout_name`
  # method derives a name for stdout redirection.
  #
  class SavedAsset
    FNR11 = %r{[^!#%\+\-0-9=@A-Z_a-z]}.freeze # characters than can be used in a file name without quotes or escaping
    # except '.', ',', '~' reserved for tokenization
    # / !"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\]^_`abcdefghijklmnopqrstuvwxyz{|}~
    FNR12 = '_'
    DEFAULT_FTIME = '%F-%H-%M-%S'
    FILE_BLOCK_SEP = ','
    JOIN_STR = '_'
    MARK_STR = '~'

    # @param filename [String] the name of the file
    # @param prefix [String] the prefix to use
    # @param time [Time] the time object for formatting
    # @param blockname [String] the block name to include
    # @param ftime [String] the time format (default: DEFAULT_FTIME)
    # @param pattern [Regexp] the pattern to search (default: FNR11)
    # @param replace [String] the string to replace the pattern (default: FNR12)
    # @param exts [String] the extension to append (default: '.sh')
    def initialize(
      saved_asset_format:, filename: nil, prefix: nil, time: nil, blockname: nil,
      ftime: DEFAULT_FTIME, pattern: FNR11, replace: FNR12, exts: nil,
      mark: nil, join_str: nil
    )
      @filename = filename ? filename.gsub(pattern, replace) : '*' # [String] the name of the file
      @prefix = prefix || '*' # [String] the prefix to use
      @time = time ? time.strftime(ftime) : '*' # [Time] the time object for formatting
      @blockname = blockname ? blockname.gsub(pattern, replace) : '*' # [String] the block name to include
      # @ftime = ftime # [String] the time format (default: DEFAULT_FTIME)
      # @pattern = pattern # [Regexp] the pattern to search (default: FNR11)
      # @replace = replace # [String] the string to replace the pattern (default: FNR12)
      @exts = exts || '.*' # [String] the extension to append (default: '.sh')
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

class SavedAssetTest < Minitest::Test
  def test_script_name_with_special_characters_in_blockname
    filename = 'sample.txt'
    prefix = 'test'
    time = Time.new(2023, 1, 1, 12, 0, 0)
    blockname = 'block/1:2'

    expected_name = 'test_2023-01-01-12-00-00_sample_txt_,_block_1_2.sh'
    assert_equal expected_name, MarkdownExec::SavedAsset.script_name(
      filename: filename, prefix: prefix, time: time, blockname: blockname
    )
  end

  def test_stdout_name_with_special_characters_in_blockname
    filename = 'sample.txt'
    prefix = 'test'
    time = Time.new(2023, 1, 1, 12, 0, 0)
    blockname = 'block/1:2'

    expected_name = 'test_2023-01-01-12-00-00_sample_txt_,_block_1_2.out.txt'
    assert_equal expected_name, MarkdownExec::SavedAsset.stdout_name(
      filename: filename, prefix: prefix, time: time, blockname: blockname
    )
  end

  def test_wildcard_name_with_all_parameters
    filename = 'sample.txt'
    prefix = 'test'
    time = Time.new(2023, 1, 1, 12, 0, 0)
    blockname = 'block/1:2'
    expected_wildcard = 'test_2023-01-01-12-00-00_sample_txt_,_block_1_2.sh'

    assert_equal expected_wildcard, MarkdownExec::SavedAsset.wildcard_name(
      filename: filename, prefix: prefix, time: time, blockname: blockname
    )
  end

  def test_wildcard_name_with_missing_time
    filename = 'sample.txt'
    prefix = 'test'
    time = nil
    blockname = 'block/1:2'
    expected_wildcard = 'test_*_sample_txt_,_block_1_2.sh'

    assert_equal expected_wildcard, MarkdownExec::SavedAsset.wildcard_name(
      filename: filename, prefix: prefix, time: time, blockname: blockname
    )
  end

  def test_wildcard_name_with_missing_filename
    filename = nil
    prefix = 'test'
    time = Time.new(2023, 1, 1, 12, 0, 0)
    blockname = 'block/1:2'
    expected_wildcard = 'test_2023-01-01-12-00-00_*_,_block_1_2.sh'

    assert_equal expected_wildcard, MarkdownExec::SavedAsset.wildcard_name(
      filename: filename, prefix: prefix, time: time, blockname: blockname
    )
  end

  def test_wildcard_name_with_missing_prefix
    filename = 'sample.txt'
    prefix = nil
    time = Time.new(2023, 1, 1, 12, 0, 0)
    blockname = 'block/1:2'
    expected_wildcard = '*_2023-01-01-12-00-00_sample_txt_,_block_1_2.sh'

    assert_equal expected_wildcard, MarkdownExec::SavedAsset.wildcard_name(
      filename: filename, prefix: prefix, time: time, blockname: blockname
    )
  end

  def test_wildcard_name_with_missing_blockname
    filename = 'sample.txt'
    prefix = 'test'
    time = Time.new(2023, 1, 1, 12, 0, 0)
    blockname = nil
    expected_wildcard = 'test_2023-01-01-12-00-00_sample_txt_,_*.sh'

    assert_equal expected_wildcard, MarkdownExec::SavedAsset.wildcard_name(
      filename: filename, prefix: prefix, time: time, blockname: blockname
    )
  end

  def test_wildcard_name_with_all_missing
    filename = nil
    prefix = nil
    time = nil
    blockname = nil
    expected_wildcard = '*_*_*_,_*.sh'

    assert_equal expected_wildcard, MarkdownExec::SavedAsset.wildcard_name(
      filename: filename, prefix: prefix, time: time, blockname: blockname
    )
  end
end
