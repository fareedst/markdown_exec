# frozen_string_literal: true

require 'bundler/setup'
Bundler.require(:default)

require_relative '../lib/markdown_exec'

include Tap #; tap_config
require_relative '../lib/link_history'
require_relative '../lib/rspec_helpers'
spec_source __FILE__

RUN_INTERACTIVE = false # tests requiring user interaction (e.g. selection)

RSpec.describe 'MarkdownExec' do
  let(:mp) { MarkdownExec::MarkParse.new options }

  ## option defaults read from yaml
  # customized in tests
  #
  let(:ymds) do
    menu_from_yaml.map do |item|
      next unless item[:opt_name]

      val = env_str(item[:env_var], default: item[:default])
      [item[:opt_name].to_sym, val] if val.present?
    end.compact.sort_by { |key, _v| key }.to_h
  end

  let(:block_calls_scan) { '%\\([^\\)]+\\)' }
  let(:block_name_match) { ':(?<title>\\S+)( |$)' }
  let(:block_name_wrapper_match) { '^{.+}$' }
  let(:block_source) { { document_filename: '' } }
  let(:block_stdin_scan) do
    '<(?<full>(?<type>\\$)?(?<name>[A-Za-z_\\-\\.\\w]+))'
  end
  let(:block_stdout_scan) do
    '>(?<full>(?<type>\\$)?(?<name>[A-Za-z_\\-\\.\\w]+))'
  end
  let(:fixtures_filename) { 'fixtures/sample1.md' }
  let(:import_pattern) { '^ *@import +(?<name>.+?) *$' }
  let(:menu_divider_color) { 'plain' }
  let(:menu_divider_format) { ymds[:menu_divider_format] }
  let(:divider_match) { nil }
  let(:menu_final_divider) { nil }
  let(:menu_initial_divider) { nil }
  let(:menu_note_match) { nil }
  let(:menu_task_color) { 'plain' }
  let(:menu_task_format) { '-:   %s   :-' }
  let(:menu_task_match) { nil }
  let(:no_chrome) { false }
  let(:option_bash) { false }
  let(:struct_bash) { true }
  let(:fenced_start_and_end_regex) { "^(?<indent>[ \t]*)`{3,}" }
  let(:fenced_start_extended_regex) do
    "^(?<indent>[ \t]*)`{3,}(?<type>[^`\\s]*) *(:(?<name>[^\\s]*))? *(?<rest>.*) *$"
  end

  let(:options) do
    ymds.merge(
      {
        bash: option_bash,
        bash_only: false,
        fenced_start_and_end_regex: fenced_start_and_end_regex,
        fenced_start_extended_regex: fenced_start_extended_regex,
        filename: fixtures_filename,
        menu_divider_color: menu_divider_color,
        menu_divider_format: menu_divider_format,
        divider_match: divider_match,
        menu_final_divider: menu_final_divider,
        menu_initial_divider: menu_initial_divider,
        menu_note_match: menu_note_match,
        menu_task_color: menu_task_color,
        menu_task_format: menu_task_format,
        menu_task_match: menu_task_match,
        no_chrome: no_chrome
      }
    )
  end

  ## presence of menu dividers
  #
  let(:fcb_options) do
    {
      select_by_name_regex: '^(?<name>block2).*$',
      exclude_by_name_regex: '^(?<name>block[13]).*$',
      exclude_expect_blocks: false,
      hide_blocks_by_name: true
    }
  end
  let(:mdoc_blocks) do
    MarkdownExec::MDoc.new(doc_block_options_blocks_from_nested_files.to_h)
  end
  let(:doc_block_options_blocks_from_nested_files) do
    MarkdownExec::HashDelegator.new(doc_blocks_options).blocks_from_nested_files.blocks
  end
  ## blocks
  #
  let(:doc_blocks_options) do
    {
      bash: true,
      block_calls_scan: block_calls_scan,
      block_name_match: block_name_match,
      block_name_wrapper_match: block_name_wrapper_match,
      block_stdin_scan: block_stdin_scan,
      block_stdout_scan: block_stdout_scan,
      fenced_start_and_end_regex: fenced_start_and_end_regex,
      fenced_start_extended_regex: fenced_start_extended_regex,
      filename: 'fixtures/block_exclude.md',
      hide_blocks_by_name: false,
      import_pattern: import_pattern,
      yaml_blocks: true
    }
  end
  let(:mdoc_yaml2) do
    MarkdownExec::MDoc.new(list_blocks_yaml2)
  end
  let(:list_blocks_yaml2) do
    MarkdownExec::HashDelegator.new(
      bash: false,
      block_calls_scan: block_calls_scan,
      block_name_match: block_name_match,
      block_name_wrapper_match: block_name_wrapper_match,
      block_stdin_scan: block_stdin_scan,
      block_stdout_scan: block_stdout_scan,
      fenced_start_and_end_regex: fenced_start_and_end_regex,
      fenced_start_extended_regex: fenced_start_extended_regex,
      filename: 'fixtures/yaml2.md',
      hide_blocks_by_name: false,
      import_pattern: import_pattern,
      yaml_blocks: true
    ).blocks_from_nested_files.blocks
  end
  let(:mdoc_yaml1) do
    MarkdownExec::MDoc.new(list_blocks_yaml1)
  end
  #  it 'test_base_options; end' do
  #  it 'test_list_default_env; end' do
  #  it 'test_list_default_yaml; end' do

  let(:list_blocks_yaml1) do
    MarkdownExec::HashDelegator.new(
      bash: false,
      block_calls_scan: block_calls_scan,
      block_name_match: block_name_match,
      block_name_wrapper_match: block_name_wrapper_match,
      block_stdin_scan: block_stdin_scan,
      block_stdout_scan: block_stdout_scan,
      fenced_start_and_end_regex: fenced_start_and_end_regex,
      fenced_start_extended_regex: fenced_start_extended_regex,
      filename: 'fixtures/yaml1.md',
      hide_blocks_by_name: false,
      import_pattern: import_pattern,
      yaml_blocks: true
    ).blocks_from_nested_files.blocks
  end
  let(:specified_path) { 'path1' }
  let(:specified_filename) { 'file1' }
  let(:default_path) { 'path0' }
  let(:default_filename) { 'file0' }
  let(:menu_data) do
    [
      { long_name: 'aa', short_name: 'a', env_var: 'MDE_A', arg_name: 'TYPE',
        description: 'A a' },
      { long_name: 'bb', short_name: 'b', env_var: 'MDE_B', arg_name: 'TYPE',
        description: 'B b' }
    ]
  end
  let(:fcb) { MarkdownExec::FCB.new }
  let(:list_blocks_title) do
    MarkdownExec::HashDelegator.new(
      bash: true,
      block_calls_scan: block_calls_scan,
      block_name_match: block_name_match,
      block_name_wrapper_match: block_name_wrapper_match,
      block_stdin_scan: block_stdin_scan,
      block_stdout_scan: block_stdout_scan,
      fenced_start_and_end_regex: fenced_start_and_end_regex,
      fenced_start_extended_regex: fenced_start_extended_regex,
      filename: 'fixtures/title1.md',
      import_pattern: import_pattern
    ).blocks_from_nested_files.blocks
  end
  let(:list_blocks_headings) do
    MarkdownExec::HashDelegator.new(
      bash: true,
      block_calls_scan: block_calls_scan,
      block_name_match: block_name_match,
      block_name_wrapper_match: block_name_wrapper_match,
      block_stdin_scan: block_stdin_scan,
      block_stdout_scan: block_stdout_scan,
      fenced_start_and_end_regex: fenced_start_and_end_regex,
      fenced_start_extended_regex: fenced_start_extended_regex,
      filename: 'fixtures/heading1.md',
      menu_blocks_with_headings: true,

      heading1_match: env_str('MDE_HEADING1_MATCH',
                              default: ymds[:heading1_match]),
      heading2_match: env_str('MDE_HEADING2_MATCH',
                              default: ymds[:heading2_match]),
      heading3_match: env_str('MDE_HEADING3_MATCH',
                              default: ymds[:heading3_match]),
      import_pattern: import_pattern
    ).blocks_from_nested_files.blocks
  end
  let(:list_blocks_exclude_expect_blocks) do
    MarkdownExec::HashDelegator.new(
      bash: true,
      block_calls_scan: block_calls_scan,
      block_name_match: block_name_match,
      block_name_wrapper_match: block_name_wrapper_match,
      block_stdin_scan: block_stdin_scan,
      block_stdout_scan: block_stdout_scan,
      exclude_expect_blocks: true,
      fenced_start_and_end_regex: fenced_start_and_end_regex,
      fenced_start_extended_regex: fenced_start_extended_regex,
      filename: 'fixtures/exclude1.md',
      import_pattern: import_pattern
    ).blocks_from_nested_files.blocks
  end
  let(:list_blocks_bash2) do
    MarkdownExec::HashDelegator.new(
      bash: true,
      block_calls_scan: block_calls_scan,
      block_name_match: block_name_match,
      block_name_wrapper_match: block_name_wrapper_match,
      block_stdin_scan: block_stdin_scan,
      block_stdout_scan: block_stdout_scan,
      fenced_start_and_end_regex: fenced_start_and_end_regex,
      fenced_start_extended_regex: fenced_start_extended_regex,
      filename: 'fixtures/bash2.md',
      import_pattern: import_pattern
    ).blocks_from_nested_files.blocks
  end
  let(:options_parse_) do
    options.merge({ filename: 'fixtures/menu_divs.md' })
  end
  let(:list_blocks_bash1) do
    MarkdownExec::HashDelegator.new(
      bash: true,
      block_calls_scan: block_calls_scan,
      block_name_match: block_name_match,
      block_name_wrapper_match: block_name_wrapper_match,
      block_stdin_scan: block_stdin_scan,
      block_stdout_scan: block_stdout_scan,
      fenced_start_and_end_regex: fenced_start_and_end_regex,
      fenced_start_extended_regex: fenced_start_extended_regex,
      filename: 'fixtures/bash1.md',
      import_pattern: import_pattern
    ).blocks_from_nested_files.blocks
  end
  ## options
  #
  let(:options_diff) do
    { filename: 'diff' }
  end

  context 'with task match' do
    let(:divider_match) { nil }
    let(:menu_task_format) { '<%{name}>' }
    let(:menu_task_match) { /^ *\[(?<status>.{0,4})\] *(?<name>.*) *$/ }

    it 'formats tasks' do
      expect(MarkdownExec::HashDelegator.new(mp.options).blocks_from_nested_files.blocks.map do |block|
               [block.dname, block.text]
             end).to eq [
               ['one', nil],
               ['two', nil],
               ['<task>', '']
             ]
    end
  end

  context 'with menu divider format' do
    let(:menu_divider_format) { '<%s>' }
    let(:divider_match) { ymds[:divider_match] }
    let(:menu_final_divider) { "'FINDIV'" }
    let(:menu_initial_divider) { "'BINDIV'" }
    let(:menu_task_match) { nil }

    xit 'test_get_blocks' do
      expect(mp.list_named_blocks_in_file.map(&:oname)).to eq %w[one two]
    end

    xit 'formats dividers' do
      expect(MarkdownExec::HashDelegator.new(mp.options).blocks_from_nested_files.blocks.map do |block|
               [block.dname, block.text]
             end).to eq [
               ['one', nil],
               ['<{:line=>"divider", :indent=>"", :text=>"divider"}>', nil],
               ['two', nil]
             ]
    end
  end

  ## presence of chrome
  #
  describe 'presence of chrome' do
    subject(:blocks) do
      MarkdownExec::HashDelegator.new(mp.options).blocks_from_nested_files.blocks.map do |block|
        [block.dname, block.text]
      end
    end

    let(:menu_divider_format) { '<%s>' }
    let(:menu_initial_divider) { "'BINDIV'" }

    context 'with chrome' do
      let(:no_chrome) { false }

      it '' do
        expect(blocks).to eq [
          ['one', nil],
          ['two', nil]
        ]
      end
    end

    context 'without chrome' do
      let(:no_chrome) { true }

      it '' do
        expect(blocks).to eq [
          ['one', nil],
          ['two', nil]
        ]
      end
    end
  end

  ## presence of menu tasks
  #
  context 'with menu tasks' do
    let(:divider_match) { nil }
    let(:menu_final_divider) { nil }
    let(:menu_task_format) { '<%{name}>' }
    let(:menu_task_match) { /\[ \] +(?'name'.+) *$/ }

    it '' do
      expect(MarkdownExec::HashDelegator.new(mp.options).blocks_from_nested_files.blocks.map do |block|
               [block.dname, block.text]
             end).to eq [
               ['one', nil],
               ['two', nil],
               ['<task>', '']
             ]
    end
  end

  ## passing arguments to executed script
  #
  describe 'calculates arguments for child script' do
    let(:argv) { %w[one -- b c] }

    # it 'passes reserved arguments to executed script' do
    #   expect(mp.arguments_for_child(argv)).to eq %w[b c]
    #   expect(mp.arguments_for_mde(argv)).to eq %w[one]
    # end

    it 'passes arguments to script' do
      expect_any_instance_of(MarkdownExec::HashDelegator).to \
        receive(:command_execute).with(
          'a',
          { args: [], erls: { play_bin: 'play', shell: 'bash' }, shell: 'bash' }
        )
      opts = mp.options.merge(
        bash: true,
        filename: 'fixtures/bash1.md',
        shell_code_label_format_above: nil,
        shell_code_label_format_below: nil,
        user_must_approve: false
      )
      hopts = MarkdownExec::HashDelegator.new(opts)
      mdoc = MarkdownExec::MDoc.new(hopts.blocks_from_nested_files.blocks)

      opts.merge!(block_name: 'one')
      hopts = MarkdownExec::HashDelegator.new(opts)
      hopts.execute_block_for_state_and_name(
        selected: MarkdownExec::FCB.new,
        mdoc: mdoc,
        link_state: MarkdownExec::LinkState.new
      )
    end
  end

  it 'test_object_present?' do
    expect(nil.present?).to be_nil
    expect(''.present?).to be false
    expect('a'.present?).to be true
    expect(true.present?).to be true
    expect(false.present?).to be true
  end

  it 'test_that_it_has_a_version_number' do
    expect(MarkdownExec::VERSION).not_to be_nil
  end

  it 'test_initial_options_recalled' do
    expect(mp.options.to_h).to eq options
  end

  it 'test_update_options_over' do
    mp.update_options options_diff, over: true
    expect(mp.options.to_h).to eq options.merge(options_diff)
  end

  it 'test_update_options_under' do
    mp.update_options options_diff, over: false
    expect(mp.options.to_h).to eq options_diff.merge(options)
  end

  ## code blocks
  #
  it 'test_exist' do
    expect(File.exist?(options[:filename])).to be true
  end

  it 'test_count_blocks_in_filename' do
    expect(MarkdownExec::HashDelegator.new(mp.options).count_blocks_in_filename).to eq 2
  end

  xit 'test_get_blocks' do
    expect(mp.list_named_blocks_in_file.map(&:oname)).to eq %w[one two]
  end

  xit 'test_get_blocks_filter' do
    expect(mp.list_named_blocks_in_file(bash_only: true).map(&:oname)).to eq %w[two]
  end

  it 'test_get_blocks_struct' do
    expect(MarkdownExec::HashDelegator.new(mp.options).blocks_from_nested_files(
      link_state: MarkdownExec::LinkState.new
    ).blocks.map do |block|
             [block.body, block.oname]
           end).to eq [
             [['a'], 'one'],
             [['b'], 'two']
           ]
  end

  it 'test_list_markdown_files_in_path' do
    expect(mp.list_markdown_files_in_path.sort).to \
      include(*%w[./CHANGELOG.md ./CODE_OF_CONDUCT.md ./README.md])
  end

  it 'test_called_parse_hidden_collect_block_dependencies' do
    expect(
      MarkdownExec::MDoc.new(list_blocks_bash1)
                  .collect_block_dependencies(anyname: 'four')[:blocks]
                  .map(&:oname)
    ).to eq %w[one two three four]
  end

  it 'test_called_parse_hidden_get_required_code' do
    expect(MarkdownExec::MDoc.new(list_blocks_bash1)
                                   .collect_recursively_required_code(
                                     anyname: 'four',
                                     block_source: block_source
                                   )[:code]).to eq %w[a b c d]
  end

  xit 'test_list_yield' do
    expect(mp.list_named_blocks_in_file do |opts|
             opts.merge(bash_only: true)
           end.map(&:oname)).to eq %w[two]
  end

  it 'test_parse_bash_blocks' do
    expect(list_blocks_bash1.map do |block|
      [block.oname, block.reqs]
    end).to eq([
                 ['one', []],
                 ['two', %w[one]],
                 ['three', %w[two one]],
                 ['four', ['three']]
               ])
  end

  it 'test_parse_bash_code' do
    expect(list_blocks_bash1.map do |block|
             { name: block.oname,
               code: MarkdownExec::MDoc.new(list_blocks_bash1)
                     .collect_recursively_required_code(
                       anyname: block.oname,
                       block_source: block_source
                     )[:code] }
           end).to eq([
                        { name: 'one', code: ['a'] },
                        { name: 'two', code: %w[a b] },
                        { name: 'three', code: %w[a b c] },
                        { name: 'four', code: %w[a b c d] }
                      ])
  end

  # :reek:UncommunicativeMethodName ### temp
  it 'test_parse_bash2' do
    expect(list_blocks_bash2.map do |block|
             { name: block.oname,
               code: MarkdownExec::MDoc.new(list_blocks_bash2)
                     .collect_recursively_required_code(
                       anyname: block.oname,
                       block_source: block_source
                     )[:code] }
           end).to eq([
                        { name: 'one', code: %w[a] },
                        { name: 'two', code: %w[a b] },
                        { name: 'three', code: %w[a b c] },
                        { name: 'four', code: %w[d] },
                        { name: 'five', code: %w[a d e] }
                      ])
  end

  it 'test_parse_exclude_expect_blocks' do
    expect(list_blocks_exclude_expect_blocks.map do |block|
             [block.oname, block.title]
           end).to eq([%w[one one]])
  end

  xit 'test_parse_headings' do
    expect(list_blocks_headings.map do |block|
             [block.headings, block.oname]
           end).to \
             eq([
                  [[], 'one'],
                  [%w[h1], 'two'],
                  [%w[h1 h2], 'three'],
                  [%w[h1 h2 h3], 'four'],
                  [%w[h1 h2 h4], 'five']
                ])
  end

  xit 'test_parse_hide_blocks_by_name' do
    expect(list_blocks_hide_blocks_by_name.map(&:oname)).to
    eq(['one', '(two)', 'three', '()'])
  end

  it 'test_parse_title' do
    expect(list_blocks_title.map do |block|
             [block.oname, block.title]
           end).to eq([
                        ['no name', 'no name'],
                        ['name1', 'name1']
                      ])
  end

  it 'test_recursively_required_reqs' do
    expect(list_blocks_bash1.map do |block|
             { name: block.oname,
               allreqs: MarkdownExec::MDoc.new(list_blocks_bash1)
                                          .recursively_required(block.reqs) }
           end).to eq([
                        { name: 'one', allreqs: [] },
                        { name: 'two', allreqs: %w[one] },
                        { name: 'three', allreqs: %w[two one] },
                        { name: 'four', allreqs: %w[three two one] }
                      ])
  end

  it 'fcbs_per_options' do
    mdoc = MarkdownExec::MDoc.new(list_blocks_bash1)
    expect(mdoc.fcbs_per_options(options)
               .map(&:oname)).to eq %w[one two three four]
  end

  if RUN_INTERACTIVE
    it 'test_select_block_approve' do
      expect(
        MarkdownExec::Filter.fcb_select?({
                                           approve: true,
                                           display: true,
                                           execute: true,
                                           filename: 'fixtures/exec1.md',
                                           prompt: 'Execute'
                                         }, fcb)
      ).to eq 'ls'
    end

    it 'test_select_block_display' do
      expect(mp.select_block(display: true)).to eq 'one'
    end

    it 'test_select_block_execute' do
      mp.select_block(
        display: true,
        execute: true,
        filename: 'fixtures/exec1.md',
        prompt: 'Execute'
      )
    end

    it 'test_select_document_if_multiple' do
      expect(mp.select_document_if_multiple).to eq 'README.md'
    end
  end # RUN_INTERACTIVE

  it 'test_exclude_by_name_regex' do
    expect(mp.exclude_block(exclude_by_name_regex: 'w').oname).to eq 'one' if RUN_INTERACTIVE
  end

  xit 'test_select_by_name_regex' do
    expect(mp.list_named_blocks_in_file(
      select_by_name_regex: 'w'
    ).map(&:oname)).to eq %w[two]
  end

  it 'test_tab_completions' do
    expect(mp.tab_completions(menu_data)).to eq %w[--aa --bb]
  end

  # :reek:UncommunicativeMethodName ### temp
  it 'test_target_default_path_and_default_filename1' do
    expect(mp.list_files_specified(
             mp.determine_filename(
               default_filename: 'README.md',
               default_folder: '.'
             )
           )).to eq ['./README.md']
  end

  # :reek:UncommunicativeMethodName ### temp
  it 'test_target_default_path_and_default_filename2' do
    ft = ['fixtures/bash1.md', 'fixtures/bash2.md',
          'fixtures/block_exclude.md',
          'fixtures/exclude1.md', 'fixtures/exclude2.md',
          'fixtures/exec1.md', 'fixtures/heading1.md',
          'fixtures/menu_divs.md',
          'fixtures/sample1.md', 'fixtures/title1.md',
          'fixtures/yaml1.md', 'fixtures/yaml2.md']
    rs = mp.list_files_specified(
      mp.determine_filename(
        specified_folder: 'fixtures',
        default_filename: 'README.md',
        default_folder: '.'
      )
    ).sort
    expect(rs).to eq ft.sort
  end

  it 'test_target_default_path_and_default_filename' do
    ft = ["#{default_path}/#{default_filename}"]
    expect(mp.list_files_specified(
             mp.determine_filename(
               default_filename: default_filename,
               default_folder: default_path,
               filetree: ft
             ),
             ft
           )).to eq ft
  end

  it 'test_target_default_path_and_specified_filename' do
    ft = ["#{default_path}/#{specified_filename}"]
    expect(mp.list_files_specified(
             mp.determine_filename(
               specified_filename: specified_filename,
               default_filename: default_filename,
               default_folder: default_path,
               filetree: ft
             ),
             ft
           )).to eq ft
  end

  it 'test_target_specified_path_and_filename' do
    ft = ["#{specified_path}/#{specified_filename}"]
    expect(mp.list_files_specified(
             mp.determine_filename(
               specified_filename: specified_filename,
               specified_folder: specified_path,
               default_filename: default_filename,
               default_folder: default_path,
               filetree: ft
             ),
             ft
           )).to eq ft
  end

  it 'test_target_specified_path' do
    ft = ["#{specified_path}/any.md"]
    expect(mp.list_files_specified(
             mp.determine_filename(
               specified_folder: specified_path,
               default_filename: default_filename,
               default_folder: default_path,
               filetree: ft
             ),
             ft
           )).to eq ft
  end

  it 'test_value_for_hash' do
    expect(MarkdownExec::OptionValue.for_hash(false)).to be false
    expect(MarkdownExec::OptionValue.for_hash(true)).to be true
    expect(MarkdownExec::OptionValue.for_hash(2)).to eq 2
    expect(MarkdownExec::OptionValue.for_hash('a')).to eq 'a'
  end

  it 'test_value_for_yaml' do
    expect(MarkdownExec::OptionValue.for_yaml(false)).to be false
    expect(MarkdownExec::OptionValue.for_yaml(true)).to be true
    expect(MarkdownExec::OptionValue.for_yaml(2)).to eq 2
    expect(MarkdownExec::OptionValue.for_yaml('a')).to eq "'a'"
  end

  it 'test_parse_called_get_named_blocks' do
    expect(list_blocks_yaml1.map(&:oname)).to eq [
      '[summarize_fruits]',
      '(make_fruit_file)',
      'show_fruit_yml'
    ]
  end

  it 'test_parse_called_collect_block_dependencies' do
    expect(mdoc_yaml1.collect_block_dependencies(anyname: 'show_fruit_yml')[:blocks].map do |block|
      { call: block.call,
        oname: block.oname }.merge(block[:stdout] ? { stdout_name: block[:stdout][:name] } : {})
    end).to eq [
      { call: nil, oname: '(make_fruit_file)', stdout_name: 'fruit.yml' },
      { call: nil, oname: '[summarize_fruits]' },
      { call: '%(summarize_fruits <fruit.yml >$fruit_summary)',
        oname: 'show_fruit_yml',
        stdout_name: 'fruit_summary' }
    ]
  end

  it 'test_parse_called_get_required_code' do
    expect(mdoc_yaml1.collect_recursively_required_code(
      anyname: 'show_fruit_yml',
      block_source: block_source
    )[:code]).to eq [
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
      %(export fruit_summary=$(cat <<"EOF"\necho "fruit_summary: ${fruit_summary:-MISSING}"\nEOF\n))
    ]
  end

  it 'test_vars_parse_called_get_named_blocks' do
    expect(list_blocks_yaml2.map(&:oname)).to eq [
      '[extract_coins_report]',
      '(make_coins_file)',
      'show_coins_var',
      'report_coins_yml'
    ]
  end

  it 'test_vars_parse_called_collect_block_dependencies' do
    expect(mdoc_yaml2.collect_block_dependencies(anyname: 'show_coins_var')[:blocks].map do |block|
             { call: block.call, cann: block.cann, oname: block.oname }
           end).to eq [
             { call: nil, cann: nil, oname: '(make_coins_file)' },
             { call: nil,
               cann: '%(extract_coins_report <$coins >$coins_report)',
               oname: '[extract_coins_report]' },
             { call: '%(extract_coins_report <$coins >$coins_report)',
               cann: nil,
               oname: 'show_coins_var' }
           ]
  end

  # rubocop:disable Layout/LineLength
  it 'test_vars_parse_called_get_required_code' do
    expect(mdoc_yaml2.collect_recursively_required_code(
      anyname: 'show_coins_var',
      block_source: block_source
    )[:code]).to eq [
      %(export coins=$(cat <<"EOF"\ncoins:\n  - name: bitcoin\n    price: 21000\n  - name: ethereum\n    price: 1000\nEOF\n)),
      %q(export coins_report=$(echo "$coins" | yq '.coins | map(. | { "name": .name, "price": .price })')),
      %(export coins_report=$(cat <<"EOF"\necho "coins_report:"\necho "${coins_report:-MISSING}"\nEOF\n))
    ]
  end

  # 2024-05-31
  # expected: ["# divider 11", "block11", "# divider 21", "block21", "# divider 31", "block31", "block32"]
  # got: ["                                 DIVIDER 11", "block11", "                                 DIVIDER 21", "block21", "                                 DIVIDER 31", "block31", "block32"]
  # due to new heading formatting
  # hold testing until specification is finalized
  xit 'test_fcbs_per_options' do
    [
      [['# divider 11', 'block11', '# divider 21', 'block21', '# divider 31', 'block31', 'block32'],
       { exclude_by_shell_regex: '^expect$',
         exclude_expect_blocks: false,
         filename: 'fixtures/block_exclude.md',
         hide_blocks_by_name: false }],
      [['# divider 11', '# divider 21', '# divider 31', 'block31'],
       { select_by_shell_regex: 'mermaid',
         exclude_expect_blocks: false,
         filename: 'fixtures/block_exclude.md',
         hide_blocks_by_name: false }]
    ].each.with_index do |(names, opts), _ind|
      MarkdownExec::MarkParse.new(o2 = options.merge(opts))
      hd_doc_block_options_blocks_from_nested_files = MarkdownExec::HashDelegator.new(o2).blocks_from_nested_files.blocks
      mdoc = MarkdownExec::MDoc.new(hd_doc_block_options_blocks_from_nested_files)
      bs = mdoc.fcbs_per_options(o2)
      expect(bs.map(&:oname)).to eq names
    end
  end

  ### duplicate blocks, use most recent
  ### import file
  ### namespace file

  xdescribe 'BlockLabel' do
    subject(:bl_make) { BlockLabel.make(**options) }

    let(:filename) { 'filename' }
    let(:h1) { 'h1' }
    let(:h2) { 'h2' }
    let(:title) { 'title' }

    context 'with title_only' do
      let(:options) do
        {
          filename: filename,
          headings: [],
          menu_blocks_with_docname: false,
          menu_blocks_with_headings: false,
          title: title,
          body: nil,
          text: nil
        }
      end

      it 'makes label' do
        expect(bl_make).to eq title
      end
    end

    context 'with title and headings' do
      let(:options) do
        {
          filename: filename,
          headings: [h1, h2],
          menu_blocks_with_docname: false,
          menu_blocks_with_headings: true,
          title: title,
          body: nil,
          text: nil
        }
      end

      it 'makes label' do
        expect(bl_make).to eq "#{title}  #{h1} # #{h2}"
      end
    end

    context 'with title, headings, docname' do
      let(:options) do
        {
          filename: filename,
          headings: [h1, h2],
          menu_blocks_with_docname: true,
          menu_blocks_with_headings: true,
          title: title,
          body: nil,
          text: nil
        }
      end

      it 'makes label' do
        expect(bl_make).to eq "#{title}  #{h1} # #{h2}  #{filename}"
      end
    end
  end
end
