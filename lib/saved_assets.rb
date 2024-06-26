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
    FNR11 = %r{[^!#%&()\+,\-0-9=A-Z_a-z~]}.freeze
    # / !"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\]^_`abcdefghijklmnopqrstuvwxyz{|}~
    FNR12 = '_'
    DEFAULT_FTIME = '%F-%H-%M-%S'

    # Generates a formatted script name based on the provided parameters.
    def self.script_name(filename:, prefix:, time:, blockname:, ftime: DEFAULT_FTIME, join_str: '_', pattern: FNR11, replace: FNR12, exts: '.sh')
      fne = filename.gsub(pattern, replace)
      bne = blockname.gsub(pattern, replace)
      "#{[prefix, time.strftime(ftime), fne, ',', bne].join(join_str)}#{exts}"
    end

    # Generates a formatted stdout name based on the provided parameters.
    def self.stdout_name(filename:, prefix:, time:, blockname:, ftime: DEFAULT_FTIME, join_str: '_', pattern: FNR11, replace: FNR12, exts: '.out.txt')
      fne = filename.gsub(pattern, replace)
      bne = blockname.gsub(pattern, replace)
      "#{[prefix, time.strftime(ftime), fne, ',', bne].join(join_str)}#{exts}"
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
end
