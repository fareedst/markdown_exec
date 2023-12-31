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
    FNR11 = %r{/|:}.freeze
    FNR12 = '_'
    DEFAULT_FTIME = '%F-%H-%M-%S'

    # Generates a formatted script name based on the provided parameters.
    def self.script_name(filename:, prefix:, time:, blockname:, ftime: DEFAULT_FTIME, join_str: '_', pattern: FNR11, replace: FNR12, exts: '.sh')
      fne = filename.gsub(pattern, replace)
      "#{[prefix, time.strftime(ftime), fne, ',', blockname].join(join_str)}#{exts}"
    end

    # Generates a formatted stdout name based on the provided parameters.
    def self.stdout_name(filename:, prefix:, time:, blockname:, ftime: DEFAULT_FTIME, join_str: '_', pattern: FNR11, replace: FNR12, exts: '.out.txt')
      fne = filename.gsub(pattern, replace)
      "#{[prefix, time.strftime(ftime), fne, ',', blockname].join(join_str)}#{exts}"
    end
  end
end

if $PROGRAM_NAME == __FILE__
  require 'minitest/autorun'

  class SavedAssetTest < Minitest::Test
    def test_script_name
      filename = 'sample.txt'
      prefix = 'test'
      time = Time.new(2023, 1, 1, 12, 0, 0) # Sample date-time for consistency in testing
      blockname = 'block1'

      expected_name = 'test_2023-01-01-12-00-00_sample.txt_,_block1.sh'
      assert_equal expected_name,
                   MarkdownExec::SavedAsset.script_name(filename: filename, prefix: prefix, time: time,
                                                        blockname: blockname)
    end

    def test_stdout_name
      filename = 'sample.txt'
      prefix = 'test'
      time = Time.new(2023, 1, 1, 12, 0, 0)
      blockname = 'block1'

      expected_name = 'test_2023-01-01-12-00-00_sample.txt_,_block1.out.txt'
      assert_equal expected_name,
                   MarkdownExec::SavedAsset.stdout_name(filename: filename, prefix: prefix, time: time,
                                                        blockname: blockname)
    end
  end
end
