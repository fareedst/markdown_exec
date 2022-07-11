# frozen_string_literal: true

require 'test_helper'
require_relative '../lib/markdown_exec/version'

include Tap
tap_config envvar: MarkdownExec::TAP_DEBUG

RUN_INTERACTIVE = false # tests requiring user interaction (e.g. selection)

# test MardownExec
#
# :reek:TooManyMethods ### temp
class MarkdownExecTest < Minitest::Test
  extend Minitest::Spec::DSL

  let(:mp) { MarkdownExec::MarkParse.new options }

  let(:options) do
    menu_from_yaml.map do |item|
      next unless item[:opt_name]

      val = env_str(item[:env_var], default: item[:default])
      [item[:opt_name].to_sym, val] if val.present?
    end.compact.sort_by { |key, _v| key }.to_h.merge({ filename: 'fixtures/sample1.md' })
  end

  def test_object_present?
    assert_nil nil.present?
    refute_predicate '', :present?
    assert_predicate 'a', :present?
    assert_predicate true, :present?
    assert_predicate false, :present?
  end

  def test_env_bool
    assert env_bool(nil, default: true)
    refute env_bool('NO_VAR', default: false)
    ENV['X'] = ''
    refute env_bool('X')
    ENV['X0'] = '0'
    refute env_bool('X0')
    ENV['X1'] = '1'
    assert env_bool('X1')
  end

  let(:default_int) { 2 }

  def test_env_int
    assert_equal default_int, env_int(nil, default: default_int)
    assert_equal default_int, env_int('NO_VAR', default: default_int)
    ENV['X'] = ''
    assert_equal default_int, env_int('X', default: default_int)
    ENV['X1'] = '1'
    assert_equal 1, env_int('X1', default: default_int)
  end

  let(:default_str) { 'a' }

  def test_env_str
    assert_equal default_str, env_str(nil, default: default_str)
    assert_equal default_str, env_str('NO_VAR', default: default_str)
    ENV['X'] = ''
    assert_equal '', env_str('X', default: default_str)
    ENV['X1'] = '1'
    assert_equal '1', env_str('X1', default: default_str)
  end

  def test_that_it_has_a_version_number
    refute_nil ::MarkdownExec::VERSION
  end

  ## options
  #
  let(:options_diff) do
    {
      filename: 'diff'
    }
  end

  def test_initial_options_recalled
    assert_equal options, mp.options
  end

  def test_update_options_over
    mp.update_options options_diff
    assert_equal options.merge(options_diff), mp.options
  end

  def test_update_options_under
    mp.update_options options_diff, over: false
    assert_equal options_diff.merge(options), mp.options
  end

  ## code blocks
  #
  def test_exist
    assert_path_exists options[:filename]
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

  def test_list_markdown_files_in_path
    assert_equal ['./CHANGELOG.md', './CODE_OF_CONDUCT.md', './README.md'], mp.list_markdown_files_in_path
  end

  let(:list_blocks_bash1) do
    mp.list_blocks_in_file(
      bash: true,
      filename: 'fixtures/bash1.md',
      struct: true
    )
  end

  def test_called_parse_hidden_get_required_blocks
    assert_equal %w[one two three four],
                 (MarkdownExec::MDoc.new(list_blocks_bash1).get_required_blocks('four').map do |block|
                    block[:name]
                  end)
  end

  def test_called_parse_hidden_get_required_code
    assert_equal %w[a b c d],
                 MarkdownExec::MDoc.new(list_blocks_bash1).collect_recursively_required_code('four')
  end

  def test_list_yield
    assert_equal [['b']], (mp.list_blocks_in_file { |opts| opts.merge(bash_only: true) })
  end

  let(:options_parse_menu_for_blocks) do
    options.merge({ filename: 'fixtures/menu_divs.md' })
  end

  def test_parse_menu_for_blocks
    assert_equal [
      { name: 'menu divider 11', disabled: '' },
      'block11',
      { name: 'menu divider 21', disabled: '' },
      'block21',
      { name: 'menu divider 31', disabled: '' },
      'block31'
    ], mp.menu_for_blocks(options_parse_menu_for_blocks)
  end

  def test_parse_bash_blocks
    assert_equal [
      { name: 'one', reqs: [] },
      { name: 'two', reqs: ['one'] },
      { name: 'three', reqs: %w[two one] },
      { name: 'four', reqs: ['three'] }
    ], (list_blocks_bash1.map { |block| block.slice(:name, :reqs) })
  end

  def test_parse_bash_code
    assert_equal [
      { name: 'one', code: ['a'] },
      { name: 'two', code: %w[a b] },
      { name: 'three', code: %w[a b c] },
      { name: 'four', code: %w[a b c d] }
    ], (list_blocks_bash1.map do |block|
          { name: block[:name],
            code: MarkdownExec::MDoc.new(list_blocks_bash1)
                  .collect_recursively_required_code(block[:name]) }
        end)
  end

  let(:list_blocks_bash2) do
    mp.list_blocks_in_file(
      bash: true,
      filename: 'fixtures/bash2.md',
      struct: true
    )
  end

  # :reek:UncommunicativeMethodName ### temp
  def test_parse_bash2
    assert_equal [
      { name: 'one', code: ['a'] },
      { name: 'two', code: %w[a b] },
      { name: 'three', code: %w[a b c] },
      { name: 'four', code: %w[d] },
      { name: 'five', code: %w[a d e] }
    ], (list_blocks_bash2.map do |block|
          { name: block[:name],
            code: MarkdownExec::MDoc.new(list_blocks_bash2)
                  .collect_recursively_required_code(block[:name]) }
        end)
  end

  let(:list_blocks_exclude_expect_blocks) do
    mp.list_blocks_in_file(
      bash: true,
      exclude_expect_blocks: true,
      filename: 'fixtures/exclude1.md',
      struct: true
    )
  end

  def test_parse_exclude_expect_blocks
    assert_equal [
      { name: 'one', title: 'one' }
    ], (list_blocks_exclude_expect_blocks.map { |block| block.slice(:name, :title) })
  end

  let(:list_blocks_headings) do
    mp.list_blocks_in_file(
      bash: true,
      filename: 'fixtures/heading1.md',
      menu_blocks_with_headings: true,
      struct: true,

      heading1_match: env_str('MDE_HEADING1_MATCH', default: '^# *(?<name>[^#]*?) *$'),
      heading2_match: env_str('MDE_HEADING2_MATCH', default: '^## *(?<name>[^#]*?) *$'),
      heading3_match: env_str('MDE_HEADING3_MATCH', default: '^### *(?<name>.+?) *$')
    )
  end

  def test_parse_headings
    assert_equal [
      { headings: [], name: 'one' },
      { headings: %w[h1], name: 'two' },
      { headings: %w[h1 h2], name: 'three' },
      { headings: %w[h1 h2 h3], name: 'four' },
      { headings: %w[h1 h2 h4], name: 'five' }
    ], (list_blocks_headings.map { |block| block.slice(:headings, :name) })
  end

  let(:list_blocks_hide_blocks_by_name) do
    mp.list_named_blocks_in_file(
      bash: true,
      hide_blocks_by_name: true,
      filename: 'fixtures/exclude2.md',
      struct: true
    )
  end

  def test_parse_hide_blocks_by_name
    assert_equal [
      { name: 'one' },
      { name: 'three' }
    ], (list_blocks_hide_blocks_by_name.map { |block| block.slice(:name) })
  end

  let(:list_blocks_title) do
    mp.list_blocks_in_file(
      bash: true,
      filename: 'fixtures/title1.md',
      struct: true
    )
  end

  def test_parse_title
    assert_equal [
      { name: 'no name', title: 'no name' },
      { name: 'name1', title: 'name1' }
    ], (list_blocks_title.map { |block| block.slice(:name, :title) })
  end

  def test_recursively_required_reqs
    assert_equal [
      { name: 'one', allreqs: [] },
      { name: 'two', allreqs: ['one'] },
      { name: 'three', allreqs: %w[two one] },
      { name: 'four', allreqs: %w[three two one] }
    ], (list_blocks_bash1.map do |block|
          { name: block[:name],
            allreqs: MarkdownExec::MDoc.new(list_blocks_bash1)
                                       .recursively_required(block[:reqs]) }
        end)
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

    def test_select_md_file
      assert_equal 'README.md', mp.select_md_file
    end
  end # RUN_INTERACTIVE

  def test_select_title_match
    assert_equal 'two', mp.select_block(title_match: 'w') if RUN_INTERACTIVE
    assert_equal [['b']], mp.list_blocks_in_file(title_match: 'w')
  end

  let(:menu_data) do
    [
      { long_name: 'aa', short_name: 'a', env_var: 'MDE_A', arg_name: 'TYPE', description: 'A a' },
      { long_name: 'bb', short_name: 'b', env_var: 'MDE_B', arg_name: 'TYPE', description: 'B b' }
    ]
  end

  def test_tab_completions
    assert_equal %w[--aa --bb], mp.tab_completions(menu_data)
  end

  let(:default_filename) { 'file0' }
  let(:default_path) { 'path0' }
  let(:specified_filename) { 'file1' }
  let(:specified_path) { 'path1' }

  # :reek:UncommunicativeMethodName ### temp
  def test_target_default_path_and_default_filename1
    ft = ['./README.md']
    assert_equal ft, mp.list_files_specified(default_filename: 'README.md', default_folder: '.')
  end

  # :reek:UncommunicativeMethodName ### temp
  def test_target_default_path_and_default_filename2
    ft = ['fixtures/bash1.md', 'fixtures/bash2.md',
          'fixtures/block_exclude.md',
          'fixtures/exclude1.md', 'fixtures/exclude2.md',
          'fixtures/exec1.md', 'fixtures/heading1.md',
          'fixtures/infile_config.md',
          'fixtures/menu_divs.md',
          'fixtures/sample1.md', 'fixtures/title1.md',
          'fixtures/yaml1.md', 'fixtures/yaml2.md']
    assert_equal ft,
                 mp.list_files_specified(specified_folder: 'fixtures', default_filename: 'README.md',
                                         default_folder: '.')
  end

  def test_target_default_path_and_default_filename
    ft = ["#{default_path}/#{default_filename}"]
    assert_equal ft,
                 mp.list_files_specified(default_filename: default_filename, default_folder: default_path,
                                         filetree: ft)
  end

  def test_target_default_path_and_specified_filename
    ft = ["#{default_path}/#{specified_filename}"]
    assert_equal ft,
                 mp.list_files_specified(specified_filename: specified_filename,
                                         default_filename: default_filename,
                                         default_folder: default_path,
                                         filetree: ft)
  end

  def test_target_specified_path_and_filename
    ft = ["#{specified_path}/#{specified_filename}"]
    assert_equal ft,
                 mp.list_files_specified(specified_filename: specified_filename,
                                         specified_folder: specified_path,
                                         default_filename: default_filename,
                                         default_folder: default_path,
                                         filetree: ft)
  end

  def test_target_specified_path
    ft = ["#{specified_path}/any.md"]
    assert_equal ft,
                 mp.list_files_specified(specified_folder: specified_path,
                                         default_filename: default_filename,
                                         default_folder: default_path,
                                         filetree: ft)
  end

  def test_value_for_cli
    assert_equal '0', mp.value_for_cli(false)
    assert_equal '1', mp.value_for_cli(true)
    assert_equal '2', mp.value_for_cli(2)
    assert_equal 'a', mp.value_for_cli('a')
    assert_equal 'a\ b', mp.value_for_cli('a b')
  end

  def test_value_for_hash
    refute MarkdownExec::OptionValue.new(false).for_hash
    assert MarkdownExec::OptionValue.new(true).for_hash
    assert_equal 2, MarkdownExec::OptionValue.new(2).for_hash
    assert_equal 'a', MarkdownExec::OptionValue.new('a').for_hash
  end

  def test_value_for_yaml
    refute MarkdownExec::OptionValue.new(false).for_yaml
    assert MarkdownExec::OptionValue.new(true).for_yaml
    assert_equal 2, MarkdownExec::OptionValue.new(2).for_yaml
    assert_equal "'a'", MarkdownExec::OptionValue.new('a').for_yaml
  end

  def test_base_options; end
  def test_list_default_env; end
  def test_list_default_yaml; end

  let(:list_blocks_yaml1) do
    mp.list_blocks_in_file(
      bash: true,
      filename: 'fixtures/yaml1.md',
      hide_blocks_by_name: true,
      struct: true,
      yaml_blocks: true
    )
  end

  let(:mdoc_yaml1) do
    MarkdownExec::MDoc.new(list_blocks_yaml1)
  end

  def test_parse_called_get_named_blocks
    assert_equal [
      { name: '[summarize_fruits]' },
      { name: '(make_fruit_file)' },
      { name: 'show_fruit_yml' }
    ], (list_blocks_yaml1.map { |block| block.slice(:name) })
  end

  def test_parse_called_get_required_blocks
    assert_equal [
      { call: nil, name: '(make_fruit_file)', stdout_name: 'fruit.yml' },
      { call: nil, name: '[summarize_fruits]' },
      { call: '(summarize_fruits <fruit.yml >$fruit_summary)', name: 'show_fruit_yml' }
    ], (mdoc_yaml1.get_required_blocks('show_fruit_yml').map do |block|
      block.slice(:call, :name).merge(block[:stdout] ? { stdout_name: block[:stdout][:name] } : {})
    end)
  end

  def test_parse_called_get_required_code
    assert_equal [
      [
        %q(cat > 'fruit.yml' <<"EOF"),
        'fruit:',
        '  name: apple',
        '  color: green',
        '  price: 1.234',
        'EOF',
        ''
      ].join("\n"),
      "export fruit_summary=$(yq e '[.fruit.name,.fruit.price]' 'fruit.yml')",
      'echo "fruit_summary: ${fruit_summary:-MISSING}"'
    ], mdoc_yaml1.collect_recursively_required_code('show_fruit_yml')
  end

  let(:list_blocks_yaml2) do
    mp.list_blocks_in_file(
      bash: true,
      filename: 'fixtures/yaml2.md',
      hide_blocks_by_name: true,
      struct: true,
      yaml_blocks: true
    )
  end

  let(:mdoc_yaml2) do
    MarkdownExec::MDoc.new(list_blocks_yaml2)
  end

  def test_vars_parse_called_get_named_blocks
    assert_equal [
      { name: '[extract_coins_report]' },
      { name: '(make_coins_file)' },
      { name: 'show_coins_var' },
      { name: 'report_coins_yml' }
    ], (list_blocks_yaml2.map { |block| block.slice(:name) })
  end

  def test_vars_parse_called_get_required_blocks
    assert_equal [
      { call: nil, name: '(make_coins_file)' },
      { call: nil, cann: '(extract_coins_report <$coins >$coins_report)', name: '[extract_coins_report]' },
      { call: '(extract_coins_report <$coins >$coins_report)', name: 'show_coins_var' }
    ], (mdoc_yaml2.get_required_blocks('show_coins_var').map do |block|
          block.slice(:call, :cann, :name)
        end)
  end

  # rubocop:disable Layout/LineLength
  def test_vars_parse_called_get_required_code
    assert_equal [
      %(export coins=$(cat <<"EOF"\ncoins:\n  - name: bitcoin\n    price: 21000\n  - name: ethereum\n    price: 1000\nEOF\n)),
      %q(export coins_report=$(echo "$coins" | yq '.coins | map(. | { "name": .name, "price": .price })')),
      'echo "coins_report:"',
      'echo "${coins_report:-MISSING}"'
    ], mdoc_yaml2.collect_recursively_required_code('show_coins_var')
  end
  # rubocop:enable Layout/LineLength

  ## blocks
  #
  let(:doc_blocks) do
    mp.list_blocks_in_file(
      bash: true,
      filename: 'fixtures/block_exclude.md',
      hide_blocks_by_name: false,
      struct: true,
      yaml_blocks: true
    )
  end

  let(:mdoc_blocks) do
    MarkdownExec::MDoc.new(doc_blocks)
  end

  let(:hide_menu_block_per_options) do
    {
      block_name_excluded_match: '^(?<name>block[13]).*$',
      hide_blocks_by_name: true
    }
  end

  def test_hide_menu_block_per_options
    assert_equal [true, false, true], (doc_blocks.map do |block|
      !!mdoc_blocks.hide_menu_block_per_options(hide_menu_block_per_options, block)
    end)
  end

  def test_blocks_for_menu
    assert_equal ['block21'], (mdoc_blocks.blocks_for_menu(hide_menu_block_per_options).map { |block| block[:name] })
  end
end
