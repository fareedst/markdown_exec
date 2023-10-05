# frozen_string_literal: true

require 'bundler/setup'
Bundler.require(:default)

require_relative '../lib/markdown_exec'

include Tap #; tap_config
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

  let(:fixtures_filename) { 'fixtures/sample1.md' }
  let(:menu_divider_color) { 'plain' }
  let(:menu_divider_format) { ymds[:menu_divider_format] }
  let(:menu_divider_match) { nil }
  let(:menu_final_divider) { nil }
  let(:menu_initial_divider) { nil }
  let(:menu_task_color) { 'plain' }
  let(:menu_task_format) { '-:   %s   :-' }
  let(:menu_task_match) { nil }
  let(:option_bash) { false }
  let(:struct_bash) { true }

  let(:options) do
    ymds.merge(
      { bash: option_bash,
        filename: fixtures_filename,
        menu_divider_color: menu_divider_color,
        menu_divider_format: menu_divider_format,
        menu_divider_match: menu_divider_match,
        menu_final_divider: menu_final_divider,
        menu_initial_divider: menu_initial_divider,
        menu_task_color: menu_task_color,
        menu_task_format: menu_task_format,
        menu_task_match: menu_task_match,
        struct: struct_bash }
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
    MarkdownExec::MDoc.new(doc_fcblocks)
  end
  let(:doc_fcblocks) do
    mp.list_blocks_in_file(doc_blocks_options)
  end
  ## blocks
  #
  let(:doc_blocks_options) do
    {
      bash: true,
      filename: 'fixtures/block_exclude.md',
      hide_blocks_by_name: false,
      struct: true,
      yaml_blocks: true
    }
  end
  let(:mdoc_yaml2) do
    MarkdownExec::MDoc.new(list_blocks_yaml2)
  end
  let(:list_blocks_yaml2) do
    mp.list_blocks_in_file(
      bash: false,
      filename: 'fixtures/yaml2.md',
      hide_blocks_by_name: false,
      struct: true,
      yaml_blocks: true
    )
  end
  let(:mdoc_yaml1) do
    MarkdownExec::MDoc.new(list_blocks_yaml1)
  end
  #  it 'test_base_options; end' do
  #  it 'test_list_default_env; end' do
  #  it 'test_list_default_yaml; end' do

  let(:list_blocks_yaml1) do
    mp.list_blocks_in_file(
      bash: false,
      filename: 'fixtures/yaml1.md',
      hide_blocks_by_name: false,
      struct: true,
      yaml_blocks: true
    )
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
    mp.list_blocks_in_file(
      bash: true,
      filename: 'fixtures/title1.md',
      struct: true
    )
  end
  let(:list_blocks_hide_blocks_by_name) do
    mp.list_named_blocks_in_file(
      bash: true,
      hide_blocks_by_name: true,
      filename: 'fixtures/exclude2.md',
      struct: true
    )
  end
  let(:list_blocks_headings) do
    mp.list_blocks_in_file(
      bash: true,
      filename: 'fixtures/heading1.md',
      menu_blocks_with_headings: true,
      struct: true,

      heading1_match: env_str('MDE_HEADING1_MATCH',
                              default: ymds[:heading1_match]),
      heading2_match: env_str('MDE_HEADING2_MATCH',
                              default: ymds[:heading2_match]),
      heading3_match: env_str('MDE_HEADING3_MATCH',
                              default: ymds[:heading3_match])
    )
  end
  let(:list_blocks_exclude_expect_blocks) do
    mp.list_blocks_in_file(
      bash: true,
      exclude_expect_blocks: true,
      filename: 'fixtures/exclude1.md',
      struct: true
    )
  end
  let(:list_blocks_bash2) do
    mp.list_blocks_in_file(
      bash: true,
      filename: 'fixtures/bash2.md',
      struct: true
    )
  end
  let(:options_parse_menu_for_blocks) do
    options.merge({ filename: 'fixtures/menu_divs.md' })
  end
  let(:list_blocks_bash1) do
    mp.list_blocks_in_file(
      bash: true,
      filename: 'fixtures/bash1.md',
      struct: true
    )
  end
  ## options
  #
  let(:options_diff) do
    { filename: 'diff' }
  end

  context 'with menu divider format' do
    let(:menu_divider_format) { '<%s>' }
    let(:menu_divider_match) { ymds[:menu_divider_match] }
    let(:menu_final_divider) { 'FINDIV' }
    let(:menu_initial_divider) { 'BINDIV' }
    let(:menu_task_match) { nil }

    it 'test_get_blocks' do
      expect(mp.list_named_blocks_in_file.map do |block|
               block[:name]
             end).to eq %w[one two]
    end

    it 'formats dividers' do
      expect(mp.list_blocks_in_file.map { |block| block.slice(:name, :text) }).to eq [
        { name: '<BINDIV>', text: nil },
        { name: 'one', text: nil },
        { name: '<divider>', text: nil },
        { name: 'two', text: nil },
        { name: '<FINDIV>', text: nil }
      ]
    end
  end

  ## presence of menu tasks
  #
  context 'with menu tasks' do
    let(:menu_divider_match) { nil }
    let(:menu_final_divider) { nil }
    let(:menu_task_format) { '<%s>' }
    let(:menu_task_match) { /\[ \] +(?'name'.+) *$/ }

    it '' do
      expect(mp.list_blocks_in_file.map { |block| block.slice(:name, :text) }).to eq [
        { name: 'one', text: nil },
        { name: 'two', text: nil },
        { name: '<task>', text: nil }
      ]
    end
  end

  ## passing arguments to executed script
  #
  describe 'calculates arguments for child script' do
    let(:argv) { %w[one -- b c] }

    it 'passes reserved arguments to executed script' do
      expect(mp.arguments_for_child(argv)).to eq %w[b c]
      expect(mp.arguments_for_mde(argv)).to eq %w[one]
    end

    it 'passes arguments to script' do
      expect_any_instance_of(MarkdownExec::MarkParse).to \
        receive(:command_execute).with({ block_name: 'one', ir_approve: true }, 'a')
      mdoc = MarkdownExec::MDoc.new(
        mp.list_blocks_in_file(bash: true,
                               filename: 'fixtures/bash1.md',
                               struct: true)
      )
      mp.approve_and_execute_block({ block_name: 'one' }, mdoc)
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
    expect(mp.options).to eq options
  end

  it 'test_update_options_over' do
    mp.update_options options_diff, over: true
    expect(mp.options).to eq options.merge(options_diff)
  end

  it 'test_update_options_under' do
    mp.update_options options_diff, over: false
    expect(mp.options).to eq options_diff.merge(options)
  end

  ## code blocks
  #
  it 'test_exist' do
    expect(File.exist?(options[:filename])).to be true
  end

  it 'test_count_blocks_in_filename' do
    expect(mp.count_blocks_in_filename).to eq 2
  end

  it 'test_get_blocks' do
    expect(mp.list_named_blocks_in_file.map do |block|
             block[:name]
           end).to eq %w[one two]
  end

  it 'test_get_blocks_filter' do
    expect(mp.list_named_blocks_in_file(bash_only: true).map do |block|
             block[:name]
           end).to eq %w[two]
  end

  it 'test_get_blocks_struct' do
    expect(mp.list_blocks_in_file(struct: true).map do |block|
             block.slice(:body, :name)
           end).to eq [
             { body: %w[a], name: 'one' },
             { body: %w[b], name: 'two' }
           ]
  end

  it 'test_list_markdown_files_in_path' do
    expect(mp.list_markdown_files_in_path.sort).to \
      include(*%w[./CHANGELOG.md ./CODE_OF_CONDUCT.md ./README.md])
  end

  it 'test_called_parse_hidden_get_required_blocks' do
    expect(
      MarkdownExec::MDoc.new(list_blocks_bash1)
                  .get_required_blocks('four')
                  .map do |block|
                    block[:name]
                  end
    ).to eq %w[one two three four]
  end

  it 'test_called_parse_hidden_get_required_code' do
    expect(MarkdownExec::MDoc.new(list_blocks_bash1)
                                   .collect_recursively_required_code('four')).to \
                                     eq %w[a b c d]
  end

  it 'test_list_yield' do
    expect(mp.list_named_blocks_in_file do |opts|
             opts.merge(bash_only: true)
           end.map do |block|
             block[:name]
           end).to eq %w[two]
  end

  # let(:options_parse_menu_for_blocks_sample1) do
  #   options.merge({ filename: 'fixtures/sample1.md' })
  # end

  it 'test_parse_menu_for_blocks_sample1' do
    expect(mp.menu_for_blocks(options.merge({ filename: 'fixtures/sample1.md' })).map do |block|
      block.is_a?(MarkdownExec::FCB) ? block.slice(:name, :disabled) : block
    end).to \
      eq(%w[
           one
           two
         ])
  end

  # def menu_for_blocks(menu_options)
  #   options = calculated_options.merge menu_options
  #   menu = []
  #   iter_blocks_in_file(options) do |btype, fcb|
  #     case btype
  #     when :filter
  #       %i[blocks line]
  #     when :line
  #       if options[:menu_divider_match] &&
  #          (mbody = fcb.body[0].match(options[:menu_divider_match]))
  #         menu += [FCB.new({ name: mbody[:name], disabled: '' })]
  #       end
  #     when :blocks
  #       menu += [fcb.name]
  #     end
  #   end
  #   menu
  # end

  it 'test_parse_menu_for_blocks' do
    expect(mp.menu_for_blocks(options_parse_menu_for_blocks).map do |block|
      block.is_a?(MarkdownExec::FCB) ? block.slice(:name, :disabled) : block
    end).to \
      eq([
           # { name: 'menu divider 11', disabled: '' },
           'block11',
           # { name: 'menu divider 21', disabled: '' },
           'block21',
           # { name: 'menu divider 31', disabled: '' },
           'block31'
         ])
  end

  it 'test_parse_bash_blocks' do
    expect(list_blocks_bash1.map { |block| block.slice(:name, :reqs) }).to \
      eq([
           { name: 'one', reqs: [] },
           { name: 'two', reqs: ['one'] },
           { name: 'three', reqs: %w[two one] },
           { name: 'four', reqs: ['three'] }
         ])
  end

  it 'test_parse_bash_code' do
    expect(list_blocks_bash1.map do |block|
             { name: block[:name],
               code: MarkdownExec::MDoc.new(list_blocks_bash1)
                     .collect_recursively_required_code(block[:name]) }
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
             { name: block[:name],
               code: MarkdownExec::MDoc.new(list_blocks_bash2)
                     .collect_recursively_required_code(block[:name]) }
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
             block.slice(:name, :title)
           end).to eq([
                        { name: 'one', title: 'one' }
                      ])
  end

  it 'test_parse_headings' do
    expect(list_blocks_headings.map { |block| block.slice(:headings, :name) }).to \
      eq([
           { headings: [], name: 'one' },
           { headings: %w[h1], name: 'two' },
           { headings: %w[h1 h2], name: 'three' },
           { headings: %w[h1 h2 h3], name: 'four' },
           { headings: %w[h1 h2 h4], name: 'five' }
         ])
  end

  it 'test_parse_hide_blocks_by_name' do
    expect(list_blocks_hide_blocks_by_name.map { |block| block.slice(:name) }).to \
      eq([
           { name: 'one' },
           { name: '(two)' },
           { name: 'three' },
           { name: '()' }
         ])
  end

  it 'test_parse_title' do
    expect(list_blocks_title.map { |block| block.slice(:name, :title) }).to \
      eq([
           { name: 'no name', title: 'no name' },
           { name: 'name1', title: 'name1' }
         ])
  end

  it 'test_recursively_required_reqs' do
    expect(list_blocks_bash1.map do |block|
             { name: block[:name],
               allreqs: MarkdownExec::MDoc.new(list_blocks_bash1)
                                          .recursively_required(block[:reqs]) }
           end).to eq([
                        { name: 'one', allreqs: [] },
                        { name: 'two', allreqs: ['one'] },
                        { name: 'three', allreqs: %w[two one] },
                        { name: 'four', allreqs: %w[three two one] }
                      ])
  end

  it 'fcbs_per_options' do
    mdoc = MarkdownExec::MDoc.new(list_blocks_bash1)
    expect(mdoc.fcbs_per_options(options).map(&:name)).to eq %w[one two three four]
  end

  if RUN_INTERACTIVE
    it 'test_select_block_approve' do
      expect(MarkdownExec::Filter.fcb_select?({
                                                approve: true,
                                                display: true,
                                                execute: true,
                                                filename: 'fixtures/exec1.md',
                                                prompt: 'Execute'
                                              }, fcb)).to eq 'ls'
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

    it 'test_select_md_file' do
      expect(mp.select_md_file).to eq 'README.md'
    end
  end # RUN_INTERACTIVE

  it 'test_exclude_by_name_regex' do
    expect(mp.exclude_block(exclude_by_name_regex: 'w')[:name]).to eq 'one' if RUN_INTERACTIVE
    expect(mp.list_named_blocks_in_file(exclude_by_name_regex: 'w').map do |block|
             block[:name]
           end).to eq %w[one]
  end

  it 'test_select_by_name_regex' do
    # fcb.name = 'awe'
    # puts MarkdownExec::Filter.fcb_select?({ select_by_name_regex: 'w' }, fcb) ###
    expect(mp.list_named_blocks_in_file(select_by_name_regex: 'w').map do |block|
             block[:name]
           end).to eq %w[two]
  end

  it 'test_tab_completions' do
    expect(mp.tab_completions(menu_data)).to eq %w[--aa --bb]
  end

  # :reek:UncommunicativeMethodName ### temp
  it 'test_target_default_path_and_default_filename1' do
    expect(mp.list_files_specified(default_filename: 'README.md',
                                   default_folder: '.')).to eq ['./README.md']
  end

  # :reek:UncommunicativeMethodName ### temp
  it 'test_target_default_path_and_default_filename2' do
    ft = ['fixtures/bash1.md', 'fixtures/bash2.md',
          'fixtures/block_exclude.md',
          'fixtures/duplicate_block.md',
          'fixtures/exclude1.md', 'fixtures/exclude2.md',
          'fixtures/exec1.md', 'fixtures/heading1.md',
          'fixtures/import0.md', 'fixtures/import1.md',
          'fixtures/infile_config.md',
          'fixtures/menu_divs.md',
          'fixtures/sample1.md', 'fixtures/title1.md',
          'fixtures/yaml1.md', 'fixtures/yaml2.md']
    expect(mp.list_files_specified(specified_folder: 'fixtures',
                                   default_filename: 'README.md',
                                   default_folder: '.').sort).to eq ft
  end

  it 'test_target_default_path_and_default_filename' do
    ft = ["#{default_path}/#{default_filename}"]
    expect(mp.list_files_specified(default_filename: default_filename,
                                   default_folder: default_path,
                                   filetree: ft)).to eq ft
  end

  it 'test_target_default_path_and_specified_filename' do
    ft = ["#{default_path}/#{specified_filename}"]
    expect(mp.list_files_specified(specified_filename: specified_filename,
                                   default_filename: default_filename,
                                   default_folder: default_path,
                                   filetree: ft)).to eq ft
  end

  it 'test_target_specified_path_and_filename' do
    ft = ["#{specified_path}/#{specified_filename}"]
    expect(mp.list_files_specified(specified_filename: specified_filename,
                                   specified_folder: specified_path,
                                   default_filename: default_filename,
                                   default_folder: default_path,
                                   filetree: ft)).to eq ft
  end

  it 'test_target_specified_path' do
    ft = ["#{specified_path}/any.md"]
    expect(mp.list_files_specified(specified_folder: specified_path,
                                   default_filename: default_filename,
                                   default_folder: default_path,
                                   filetree: ft)).to eq ft
  end

  it 'test_value_for_hash' do
    expect(MarkdownExec::OptionValue.new(false).for_hash).to be false
    expect(MarkdownExec::OptionValue.new(true).for_hash).to be true
    expect(MarkdownExec::OptionValue.new(2).for_hash).to eq 2
    expect(MarkdownExec::OptionValue.new('a').for_hash).to eq 'a'
  end

  it 'test_value_for_yaml' do
    expect(MarkdownExec::OptionValue.new(false).for_yaml).to be false
    expect(MarkdownExec::OptionValue.new(true).for_yaml).to be true
    expect(MarkdownExec::OptionValue.new(2).for_yaml).to eq 2
    expect(MarkdownExec::OptionValue.new('a').for_yaml).to eq "'a'"
  end

  it 'test_parse_called_get_named_blocks' do
    expect(list_blocks_yaml1.map { |block| block.slice(:name) }).to eq [
      { name: '[summarize_fruits]' },
      { name: '(make_fruit_file)' },
      { name: 'show_fruit_yml' }
    ]
  end

  it 'test_parse_called_get_required_blocks' do
    expect(mdoc_yaml1.get_required_blocks('show_fruit_yml').map do |block|
      block.slice(:call, :name)
           .merge(block[:stdout] ? { stdout_name: block[:stdout][:name] } : {})
    end).to eq [
      { call: nil, name: '(make_fruit_file)', stdout_name: 'fruit.yml' },
      { call: nil, name: '[summarize_fruits]' },
      { call: '%(summarize_fruits <fruit.yml >$fruit_summary)',
        name: 'show_fruit_yml',
        stdout_name: 'fruit_summary' }
    ]
  end

  it 'test_parse_called_get_required_code' do
    expect(mdoc_yaml1.collect_recursively_required_code('show_fruit_yml')).to eq [
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
      # rubocop:disable Layout/LineLength
      %(export fruit_summary=$(cat <<"EOF"\necho "fruit_summary: ${fruit_summary:-MISSING}"\nEOF\n))
      # rubocop:enable Layout/LineLength
    ]
  end

  it 'test_vars_parse_called_get_named_blocks' do
    expect(list_blocks_yaml2.map { |block| block.slice(:name) }).to eq [
      { name: '[extract_coins_report]' },
      { name: '(make_coins_file)' },
      { name: 'show_coins_var' },
      { name: 'report_coins_yml' }
    ]
  end

  it 'test_vars_parse_called_get_required_blocks' do
    expect(mdoc_yaml2.get_required_blocks('show_coins_var').map do |block|
             block.slice(:call, :cann, :name)
           end).to eq [
             { call: nil, name: '(make_coins_file)' },
             { call: nil,
               cann: '%(extract_coins_report <$coins >$coins_report)',
               name: '[extract_coins_report]' },
             { call: '%(extract_coins_report <$coins >$coins_report)',
               name: 'show_coins_var' }
           ]
  end

  # rubocop:disable Layout/LineLength
  it 'test_vars_parse_called_get_required_code' do
    expect(mdoc_yaml2.collect_recursively_required_code('show_coins_var')).to eq [
      %(export coins=$(cat <<"EOF"\ncoins:\n  - name: bitcoin\n    price: 21000\n  - name: ethereum\n    price: 1000\nEOF\n)),
      %q(export coins_report=$(echo "$coins" | yq '.coins | map(. | { "name": .name, "price": .price })')),
      %(export coins_report=$(cat <<"EOF"\necho "coins_report:"\necho "${coins_report:-MISSING}"\nEOF\n))
    ]
  end

  it 'test_fcb_select?' do
    expect(doc_fcblocks.map do |fcb|
      MarkdownExec::Filter.fcb_select?(fcb_options, fcb)
    end).to eq [false, true, false, false]
  end

  it 'test_fcbs_per_options' do
    # options.tap_inspect 'options'
    [
      [%w[block21 block22], { exclude_by_name_regex: '^(?<name>block[13].*)$',
                              exclude_expect_blocks: false,
                              filename: 'fixtures/block_exclude.md',
                              hide_blocks_by_name: true,
                              struct: true }],
      [%w[block21 block22], { exclude_by_name_regex: '^(?<name>block[13].*)$',
                              exclude_expect_blocks: false,
                              filename: 'fixtures/block_exclude.md',
                              hide_blocks_by_name: false,
                              struct: true }],
      [%w[block21 block22], { select_by_name_regex: '^(?<name>block2.*)$',
                              exclude_expect_blocks: false,
                              filename: 'fixtures/block_exclude.md',
                              hide_blocks_by_name: false,
                              struct: true }],
      [%w[block11 block21 block31 block32], { exclude_by_shell_regex: '^expect$',
                                              exclude_expect_blocks: false,
                                              filename: 'fixtures/block_exclude.md',
                                              hide_blocks_by_name: false,
                                              struct: true }],
      [%w[block31], { select_by_shell_regex: 'mermaid',
                      exclude_expect_blocks: false,
                      filename: 'fixtures/block_exclude.md',
                      hide_blocks_by_name: false,
                      struct: true }]
    ].each.with_index do |(names, opts), _ind|
      names.tap_inspect 'names'
      opts.tap_inspect 'opts'
      # puts "# #{ind}:"
      mp = MarkdownExec::MarkParse.new(o2 = options.merge(opts))
      doc_fcblocks = mp.list_blocks_in_file(o2)
      mdoc = MarkdownExec::MDoc.new(doc_fcblocks)
      bs = mdoc.fcbs_per_options(o2)
      expect(bs.map(&:name)).to eq names
    end
  end

  ### duplicate blocks, use most recent
  ### import file
  ### namespace file

  describe 'BlockLabel' do
    subject(:bl) { MarkdownExec::BlockLabel.new(**options) }

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
        expect(bl.make).to eq title
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
        expect(bl.make).to eq "#{title}  #{h1} # #{h2}"
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
        expect(bl.make).to eq "#{title}  #{h1} # #{h2}  #{filename}"
      end
    end
  end
end

RSpec.describe MarkdownExec::MarkParse do
  let(:instance) { described_class.new(options) }
  let(:options) { {} }

  describe '#prompt_menu_add_exit' do
    let(:exit_option) { 'Exit' }
    let(:items) { %w[item1 item2 item3] }

    before do
      allow(instance).to receive(:@options).and_return(options)
    end

    context 'when menu_with_exit is false' do
      let(:options) { { menu_with_exit: false, menu_exit_at_top: false } }

      it 'returns the items without the exit option' do
        expect(instance.prompt_menu_add_exit('', items, exit_option)).to eq(items)
      end
    end

    context 'when menu_with_exit is true' do
      let(:options) { { menu_with_exit: true, menu_exit_at_top: menu_exit_at_top } }

      context 'and menu_exit_at_top is true' do
        let(:menu_exit_at_top) { true }

        it 'returns items with exit option at the top' do
          expect(instance.prompt_menu_add_exit('', items, exit_option)).to eq([exit_option] + items)
        end
      end

      context 'and menu_exit_at_top is false' do
        let(:menu_exit_at_top) { false }

        it 'returns items with exit option at the end' do
          expect(instance.prompt_menu_add_exit('', items, exit_option)).to eq(items + [exit_option])
        end
      end
    end
  end
end
