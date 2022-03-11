# frozen_string_literal: true

require 'test_helper'

RUN_INTERACTIVE = false # tests requiring user interaction (e.g. selection)

class MarkdownExecTest < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::MarkdownExec::VERSION
  end

  extend Minitest::Spec::DSL

  let(:options) do
    {
      mdfilename: 'spec/sample1.md',
      mdfolder: '.'
    }
  end
  let(:mp) { MarkdownExec::MarkParse.new options }

  def test_exist
    assert_equal true, File.exist?(options[:mdfilename])
  end

  def test_yield
    assert_equal [['b']], (mp.get_blocks { |opts| opts.merge(bash_only: true) })
  end

  def test_count_blocks
    assert_equal 2, mp.count_blocks
  end

  def test_get_blocks
    assert_equal [['a'], ['b']], mp.get_blocks
  end
  def test_get_blocks_filter
    assert_equal [['b']], mp.get_blocks(bash_only: true)
  end
  def test_get_blocks_struct
    assert_equal [
      { body: ['a'], title: 'one' },
      { body: ['b'], title: 'two' }
    ], (mp.get_blocks(struct: true).map { |block| block.slice(:body, :title) })
  end
  def test_match_block_title
    assert_equal 'two', mp.select_block(title_match: 'w') if RUN_INTERACTIVE
    assert_equal [['b']], mp.get_blocks(title_match: 'w')
  end
  if RUN_INTERACTIVE
    def test_select_block
      assert_equal 'one', mp.select_block
    end
    def test_select_block_approve
      assert_equal 'ls', mp.select_block(
        approve: true,
        display: true,
        execute: true,
        mdfilename: 'spec/exec1.md',
        prompt: 'Execute'
      )
    end

    def test_select_block_display
      assert_equal 'one', mp.select_block(display: true)
    end
    def test_select_block_execute
      mp.select_block(
        display: true,
        execute: true,
        mdfilename: 'spec/exec1.md',
        prompt: 'Execute'
      )
    end
  end

  # test_list_documents_root
  def test_find_files
    # assert_equal `ls -1 *.md`.split("\n"), mp.find_files
    assert_equal ["./CHANGELOG.md", "./CODE_OF_CONDUCT.md", "./README.md"], mp.find_files
  end

  if RUN_INTERACTIVE
    def test_select_md_file
      assert_equal 'README.md', mp.select_md_file
    end
  end
  # def method_missing(meth, *args, &blk); end

  let(:bash1_blocks) do
    mp.get_blocks(
      bash: true,
      mdfilename: 'spec/bash1.md',
      struct: true
    )
  end

  def test_match_bash1_blocks_bash
    assert_equal [
      { name: 'one', reqs: [] },
      { name: 'two', reqs: ['one'] },
      { name: 'three', reqs: %w[two one] },
      { name: 'four', reqs: ['three'] }
    ], (bash1_blocks.map { |block| block.slice(:name, :reqs) })
  end

  def test_unroll_reqs
    assert_equal [
      { name: 'one', allreqs: [] },
      { name: 'two', allreqs: ['one'] },
      { name: 'three', allreqs: %w[two one] },
      { name: 'four', allreqs: %w[three two one] }
    ], (bash1_blocks.map do |block|
          { name: block[:name], allreqs: mp.unroll(bash1_blocks, block[:reqs]) }
        end)
  end

  def test_load_blocks
    assert_equal [
      { name: 'one', code: ['a'] },
      { name: 'two', code: %w[a b] },
      { name: 'three', code: %w[a b c] },
      { name: 'four', code: %w[a b c d] }
    ], (bash1_blocks.map do |block|
          { name: block[:name], code: mp.code(bash1_blocks, block) }
        end)
  end

  def test_code_blocks
    assert_equal %w[a b c d], mp.code_blocks(bash1_blocks, 'four')
  end

  let(:bash2_blocks) do
    mp.get_blocks(
      bash: true,
      mdfilename: 'spec/bash2.md',
      struct: true
    )
  end

  def test_parse_bash2
    assert_equal [
      { name: 'one', code: ['a'] },
      { name: 'two', code: %w[a b] },
      { name: 'three', code: %w[a b c] },
      { name: 'four', code: %w[d] },
      { name: 'five', code: %w[a d e] }
    ], (bash2_blocks.map do |block|
          { name: block[:name], code: mp.code(bash2_blocks, block) }
        end)
  end

  let(:title1_blocks) do
    mp.get_blocks(
      bash: true,
      mdfilename: 'spec/title1.md',
      struct: true
    )
  end

  def test_parse_title1
    assert_equal [
      { name: 'no name', title: 'no name' },
      { name: 'name1', title: 'name1' }
    ], (title1_blocks.map { |block| block.slice(:name, :title) })
  end

  let(:heading1_blocks) do
    mp.get_blocks(
      bash: true,
      mdfilename: 'spec/heading1.md',
      mdheadings: true,
      struct: true
    )
  end

  def test_parse_heading1
    assert_equal [
      { headings: [], name: 'one' },
      { headings: %w[h1], name: 'two' },
      { headings: %w[h1 h2], name: 'three' },
      { headings: %w[h1 h2 h3], name: 'four' },
      { headings: %w[h1 h2 h4], name: 'five' }
    ], (heading1_blocks.map { |block| block.slice(:headings, :name) })
  end

  let(:exclude1_blocks) do
    mp.get_blocks(
      bash: true,
      exclude_expect_blocks: true,
      mdfilename: 'spec/exclude1.md',
      struct: true
    )
  end

  def test_parse_exclude1
    assert_equal [
      { name: 'one', title: 'one' }
    ], (exclude1_blocks.map { |block| block.slice(:name, :title) })
  end
end
