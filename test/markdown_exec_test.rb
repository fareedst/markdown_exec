# frozen_string_literal: true

require 'test_helper'

RUN_INTERACTIVE = false # tests requiring user interaction (e.g. selection)

class MarkdownExecTest < Minitest::Test
  extend Minitest::Spec::DSL

  def test_that_it_has_a_version_number
    refute_nil ::MarkdownExec::VERSION
  end

  let(:mp) { MarkdownExec::MarkParse.new options }
  let(:options) do
    {
      filename: 'fixtures/sample1.md',
      path: '.'
    }
  end

  def test_exist
    assert_equal true, File.exist?(options[:filename])
  end

  def test_yield
    assert_equal [['b']], (mp.list_blocks_in_file { |opts| opts.merge(bash_only: true) })
  end

  def test_count_blocks_in_filename
    assert_equal 2, mp.count_blocks_in_filename
  end

  def test_get_blocks
    assert_equal [['a'], ['b']], mp.list_blocks_in_file
  end

  def test_get_blocks_filter
    assert_equal [['b']], mp.list_blocks_in_file(bash_only: true)
  end

  def test_get_blocks_struct
    assert_equal [
      { body: ['a'], title: 'one' },
      { body: ['b'], title: 'two' }
    ], (mp.list_blocks_in_file(struct: true).map { |block| block.slice(:body, :title) })
  end

  def test_match_block_title
    assert_equal 'two', mp.select_block(title_match: 'w') if RUN_INTERACTIVE
    assert_equal [['b']], mp.list_blocks_in_file(title_match: 'w')
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
        filename: 'fixtures/exec1.md',
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
        filename: 'fixtures/exec1.md',
        prompt: 'Execute'
      )
    end
  end

  # test_list_documents_root
  def test_list_markdown_files_in_folder
    assert_equal ['./CHANGELOG.md', './CODE_OF_CONDUCT.md', './README.md'], mp.list_markdown_files_in_folder
  end

  if RUN_INTERACTIVE
    def test_select_md_file
      assert_equal 'README.md', mp.select_md_file
    end
  end
  # def method_missing(meth, *args, &blk); end

  let(:bash1_blocks) do
    mp.list_blocks_in_file(
      bash: true,
      filename: 'fixtures/bash1.md',
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

  def test_recursively_required_reqs
    assert_equal [
      { name: 'one', allreqs: [] },
      { name: 'two', allreqs: ['one'] },
      { name: 'three', allreqs: %w[two one] },
      { name: 'four', allreqs: %w[three two one] }
    ], (bash1_blocks.map do |block|
          { name: block[:name], allreqs: mp.recursively_required(bash1_blocks, block[:reqs]) }
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
    assert_equal %w[a b c d], mp.list_recursively_required_blocks(bash1_blocks, 'four')
  end

  let(:bash2_blocks) do
    mp.list_blocks_in_file(
      bash: true,
      filename: 'fixtures/bash2.md',
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
    mp.list_blocks_in_file(
      bash: true,
      filename: 'fixtures/title1.md',
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
    mp.list_blocks_in_file(
      bash: true,
      filename: 'fixtures/heading1.md',
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
    mp.list_blocks_in_file(
      bash: true,
      exclude_expect_blocks: true,
      filename: 'fixtures/exclude1.md',
      struct: true
    )
  end

  def test_parse_exclude1
    assert_equal [
      { name: 'one', title: 'one' }
    ], (exclude1_blocks.map { |block| block.slice(:name, :title) })
  end

  ###
  let(:exclude2_blocks) do
    mp.list_named_blocks_in_file(
      bash: true,
      exclude_matching_block_names: true,
      filename: 'fixtures/exclude2.md',
      struct: true
    )
  end

  def test_parse_exclude2
    assert_equal [
      { name: 'one' },
      { name: 'three' }
    ], (exclude2_blocks.map { |block| block.slice(:name) })
  end

  let(:default_filename) { 'file0' }
  let(:default_folder) { 'folder0' }
  let(:specified_filename) { 'file1' }
  let(:specified_folder) { 'folder1' }

  def test_target_default_folder_and_default_filename1
    ft = ['./README.md']
    assert_equal ft, mp.list_files_specified(nil, nil, 'README.md', '.')
  end

  def test_target_default_folder_and_default_filename2
    ft = ['fixtures/bash1.md', 'fixtures/bash2.md',
          'fixtures/exclude1.md', 'fixtures/exclude2.md',
          'fixtures/exec1.md', 'fixtures/heading1.md',
          'fixtures/sample1.md', 'fixtures/title1.md']
    assert_equal ft, mp.list_files_specified(nil, 'fixtures', 'README.md', '.')
  end

  def test_target_default_folder_and_default_filename
    ft = ["#{default_folder}/#{default_filename}"]
    assert_equal ft, mp.list_files_specified(nil, nil, default_filename, default_folder, ft)
  end

  def test_target_default_folder_and_specified_filename
    ft = ["#{default_folder}/#{specified_filename}"]
    assert_equal ft, mp.list_files_specified(specified_filename, nil, default_filename, default_folder, ft)
  end

  def test_target_specified_folder_and_filename
    ft = ["#{specified_folder}/#{specified_filename}"]
    assert_equal ft,
                 mp.list_files_specified(specified_filename, specified_folder, default_filename, default_folder, ft)
  end

  def test_target_specified_folder
    ft = ["#{specified_folder}/any.md"]
    assert_equal ft, mp.list_files_specified(nil, specified_folder, default_filename, default_folder, ft)
  end
end
