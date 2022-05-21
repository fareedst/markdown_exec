#!/usr/bin/env ruby
# frozen_string_literal: true

# encoding=utf-8

require 'English'
require 'clipboard'
require 'open3'
require 'optparse'
require 'tty-prompt'
require 'yaml'

require_relative 'shared'
require_relative 'markdown_exec/version'

$stderr.sync = true
$stdout.sync = true

BLOCK_SIZE = 1024

class Object # rubocop:disable Style/Documentation
  def present?
    case self.class.to_s
    when 'FalseClass', 'TrueClass'
      true
    else
      self && (!respond_to?(:blank?) || !blank?)
    end
  end
end

class String # rubocop:disable Style/Documentation
  BLANK_RE = /\A[[:space:]]*\z/.freeze
  def blank?
    empty? || BLANK_RE.match?(self)
  end
end

public

# display_level values
DISPLAY_LEVEL_BASE = 0 # required output
DISPLAY_LEVEL_ADMIN = 1
DISPLAY_LEVEL_DEBUG = 2
DISPLAY_LEVEL_DEFAULT = DISPLAY_LEVEL_ADMIN
DISPLAY_LEVEL_MAX = DISPLAY_LEVEL_DEBUG

# @execute_files[ind] = @execute_files[ind] + [block]
EF_STDOUT = 0
EF_STDERR = 1
EF_STDIN = 2

module MarkdownExec
  class Error < StandardError; end

  ##
  #
  class MarkParse
    attr_accessor :options

    def initialize(options = {})
      @options = options
      @prompt = TTY::Prompt.new(interrupt: :exit)
    end

    ##
    # options necessary to start, parse input, defaults for cli options

    def base_options
      menu_iter do |item|
        item.tap_inspect name: :item, format: :yaml
        next unless item[:opt_name].present?

        item_default = item[:default]
        item_default.tap_inspect name: :item_default
        value = if item_default.nil?
                  item_default
                else
                  env_str(item[:env_var], default: value_for_hash(item_default))
                end
        [item[:opt_name], item[:proc1] ? item[:proc1].call(value) : value]
      end.compact.to_h.merge(
        {
          mdheadings: true, # use headings (levels 1,2,3) in block lable
          menu_exit_at_top: true,
          menu_with_exit: true
        }
      ).tap_inspect format: :yaml
    end

    def default_options
      {
        bash: true, # bash block parsing in get_block_summary()
        exclude_expect_blocks: true,
        hide_blocks_by_name: true,
        output_saved_script_filename: false,
        prompt_approve_block: 'Process?',
        prompt_select_block: 'Choose a block:',
        prompt_select_md: 'Choose a file:',
        prompt_select_output: 'Choose a file:',
        saved_script_filename: nil, # calculated
        struct: true # allow get_block_summary()
      }
    end

    # Returns true if all files are EOF
    #
    def all_at_eof(files)
      files.find { |f| !f.eof }.nil?
    end

    def approve_block(opts, blocks_in_file)
      required_blocks = list_recursively_required_blocks(blocks_in_file, opts[:block_name])
      display_command(opts, required_blocks) if opts[:output_script] || opts[:user_must_approve]

      allow = true
      if opts[:user_must_approve]
        loop do
          # (sel = @prompt.select(opts[:prompt_approve_block], %w(Yes No Copy_script_to_clipboard Save_script), cycle: true)).tap_inspect name: :sel
          (sel = @prompt.select(opts[:prompt_approve_block], filter: true) do |menu|
             menu.default 1
             # menu.enum '.'
             # menu.filter true

             menu.choice 'Yes', 1
             menu.choice 'No', 2
             menu.choice 'Copy script to clipboard', 3
             menu.choice 'Save script', 4
           end).tap_inspect name: :sel
          allow = (sel == 1)
          if sel == 3
            text = required_blocks.flatten.join($INPUT_RECORD_SEPARATOR)
            Clipboard.copy(text)
            fout "Clipboard updated: #{required_blocks.count} blocks, #{required_blocks.flatten.count} lines, #{text.length} characters"
          end
          if sel == 4
            # opts[:saved_script_filename] = saved_name_make(opts)
            write_command_file(opts.merge(save_executed_script: true), required_blocks)
            fout "File saved: #{@options[:saved_filespec]}"
          end
          break if [1, 2].include? sel
        end
      end
      (opts[:ir_approve] = allow).tap_inspect name: :allow

      selected = get_block_by_name blocks_in_file, opts[:block_name]

      if opts[:ir_approve]
        write_command_file opts, required_blocks
        command_execute opts, required_blocks.flatten.join("\n")
        save_execution_output
        output_execution_summary
        output_execution_result
      end

      selected[:name]
    end

    def code(table, block)
      all = [block[:name]] + recursively_required(table, block[:reqs])
      all.reverse.map do |req|
        get_block_by_name(table, req).fetch(:body, '')
      end
         .flatten(1)
         .tap_inspect
    end

    def command_execute(opts, cmd2)
      @execute_files = Hash.new([])
      @execute_options = opts
      @execute_started_at = Time.now.utc

      Open3.popen3(@options[:shell], '-c', cmd2) do |stdin, stdout, stderr, exec_thr|
        # pid = exec_thr.pid # pid of the started process

        t1 = Thread.new do
          until (line = stdout.gets).nil?
            @execute_files[EF_STDOUT] = @execute_files[EF_STDOUT] + [line]
            print line if opts[:output_stdout]
            yield nil, line, nil, exec_thr if block_given?
          end
        end

        t2 = Thread.new do
          until (line = stderr.gets).nil?
            @execute_files[EF_STDERR] = @execute_files[EF_STDERR] + [line]
            print line if opts[:output_stdout]
            yield nil, nil, line, exec_thr if block_given?
          end
        end

        in_thr = Thread.new do
          while exec_thr.alive? # reading input until the child process ends
            stdin.puts(line = $stdin.gets)
            @execute_files[EF_STDIN] = @execute_files[EF_STDIN] + [line]
            yield line, nil, nil, exec_thr if block_given?
          end
        end

        exec_thr.join
        in_thr.kill
        # @return_code = exec_thr.value
      end
      @execute_completed_at = Time.now.utc
    rescue Errno::ENOENT => e
      # error triggered by missing command in script
      @execute_aborted_at = Time.now.utc
      @execute_error_message = e.message
      @execute_error = e
      @execute_files[EF_STDERR] += [e.message]
      fout "Error ENOENT: #{e.inspect}"
    end

    def count_blocks_in_filename
      fenced_start_and_end_match = Regexp.new @options[:fenced_start_and_end_match]
      cnt = 0
      File.readlines(@options[:filename]).each do |line|
        cnt += 1 if line.match(fenced_start_and_end_match)
      end
      cnt / 2
    end

    def display_command(_opts, required_blocks)
      fout ' #=#=#'.yellow
      required_blocks.each { |cb| fout cb }
      fout ' #=#=#'.yellow
    end

    def exec_block(options, _block_name = '')
      options = default_options.merge options
      update_options options, over: false

      # document and block reports
      #
      files = list_files_per_options(options)

      simple_commands = {
        doc_glob: -> { fout options[:md_filename_glob] },
        list_blocks: lambda do
                       fout_list (files.map do |file|
                                    make_block_labels(filename: file, struct: true)
                                  end).flatten(1)
                     end,
        list_default_yaml: -> { fout_list list_default_yaml },
        list_docs: -> { fout_list files },
        list_default_env: -> { fout_list list_default_env },
        list_recent_output: -> { fout_list list_recent_output },
        list_recent_scripts: -> { fout_list list_recent_scripts },
        pwd: -> { fout File.expand_path('..', __dir__) },
        run_last_script: -> { run_last_script },
        select_recent_output: -> { select_recent_output },
        select_recent_script: -> { select_recent_script },
        tab_completions: -> { fout tab_completions },
        menu_export: -> { fout menu_export }
      }
      simple_commands.each_key do |key|
        if @options[key]
          simple_commands[key].call
          return # rubocop:disable Lint/NonLocalExitFromIterator
        end
      end

      # process
      #
      @options[:filename] = select_md_file(files)
      select_and_approve_block(
        bash: true,
        struct: true
      )
      fout "saved_filespec: #{@execute_script_filespec}" if @options[:output_saved_script_filename]
    end

    # standard output; not for debug
    #
    def fout(str)
      puts str
    end

    def fout_list(str)
      puts str
    end

    def fout_section(name, data)
      puts "# #{name}"
      puts data.to_yaml
    end

    def get_block_by_name(table, name, default = {})
      table.select { |block| block[:name] == name }.fetch(0, default)
    end

    def get_block_summary(opts, headings, block_title, current)
      return [current] unless opts[:struct]

      return [summarize_block(headings, block_title).merge({ body: current })] unless opts[:bash]

      bm = block_title.match(Regexp.new(opts[:block_name_match]))
      reqs = block_title.scan(Regexp.new(opts[:block_required_scan])).map { |s| s[1..] }

      if bm && bm[1]
        [summarize_block(headings, bm[:title]).merge({ body: current, reqs: reqs })]
      else
        [summarize_block(headings, block_title).merge({ body: current, reqs: reqs })]
      end
    end

    def approved_fout?(level)
      level <= @options[:display_level]
    end

    # display output at level or lower than filter (DISPLAY_LEVEL_DEFAULT)
    #
    def lout(str, level: DISPLAY_LEVEL_BASE)
      return unless approved_fout? level

      # fout level == DISPLAY_LEVEL_BASE ? str : DISPLAY_LEVEL_XBASE_PREFIX + str
      fout level == DISPLAY_LEVEL_BASE ? str : @options[:display_level_xbase_prefix] + str
    end

    def list_blocks_in_file(call_options = {}, &options_block)
      opts = optsmerge call_options, options_block

      unless opts[:filename]&.present?
        fout 'No blocks found.'
        exit 1
      end

      unless File.exist? opts[:filename]
        fout 'Document is missing.'
        exit 1
      end

      fenced_start_and_end_match = Regexp.new opts[:fenced_start_and_end_match]
      fenced_start_ex = Regexp.new opts[:fenced_start_ex_match]
      block_title = ''
      blocks = []
      current = nil
      headings = []
      in_block = false
      File.readlines(opts[:filename]).each do |line|
        continue unless line

        if opts[:mdheadings]
          if (lm = line.match(Regexp.new(opts[:heading3_match])))
            headings = [headings[0], headings[1], lm[:name]]
          elsif (lm = line.match(Regexp.new(opts[:heading2_match])))
            headings = [headings[0], lm[:name]]
          elsif (lm = line.match(Regexp.new(opts[:heading1_match])))
            headings = [lm[:name]]
          end
        end

        if line.match(fenced_start_and_end_match)
          if in_block
            if current
              block_title = current.join(' ').gsub(/  +/, ' ')[0..64] if block_title.nil? || block_title.empty?
              blocks += get_block_summary opts, headings, block_title, current
              current = nil
            end
            in_block = false
            block_title = ''
          else
            # new block
            #
            lm = line.match(fenced_start_ex)
            do1 = false
            if opts[:bash_only]
              do1 = true if lm && (lm[:shell] == 'bash')
            else
              do1 = true
              do1 = !(lm && (lm[:shell] == 'expect')) if opts[:exclude_expect_blocks]
            end

            in_block = true
            if do1 && (!opts[:title_match] || (lm && lm[:name] && lm[:name].match(opts[:title_match])))
              current = []
              block_title = (lm && lm[:name])
            end
          end
        elsif current
          current += [line.chomp]
        end
      end
      blocks.tap_inspect
    end

    def list_default_env
      menu_iter do |item|
        next unless item[:env_var].present?

        [
          "#{item[:env_var]}=#{value_for_cli item[:default]}",
          item[:description].present? ? item[:description] : nil
        ].compact.join('      # ')
      end.compact.sort
    end

    def list_default_yaml
      menu_iter do |item|
        next unless item[:opt_name].present? && item[:default].present?

        [
          "#{item[:opt_name]}: #{value_for_yaml item[:default]}",
          item[:description].present? ? item[:description] : nil
        ].compact.join('      # ')
      end.compact.sort
    end

    def list_files_per_options(options)
      list_files_specified(
        options[:filename]&.present? ? options[:filename] : nil,
        options[:path],
        'README.md',
        '.'
      ).tap_inspect
    end

    def list_files_specified(specified_filename, specified_folder, default_filename, default_folder, filetree = nil)
      fn = File.join(if specified_filename&.present?
                       if specified_folder&.present?
                         [specified_folder, specified_filename]
                       elsif specified_filename.start_with? '/'
                         [specified_filename]
                       else
                         [default_folder, specified_filename]
                       end
                     elsif specified_folder&.present?
                       if filetree
                         [specified_folder, @options[:md_filename_match]]
                       else
                         [specified_folder, @options[:md_filename_glob]]
                       end
                     else
                       [default_folder, default_filename]
                     end)
      if filetree
        filetree.select { |filename| filename == fn || filename.match(/^#{fn}$/) || filename.match(%r{^#{fn}/.+$}) }
      else
        Dir.glob(fn)
      end.tap_inspect
    end

    def list_markdown_files_in_path
      Dir.glob(File.join(@options[:path], @options[:md_filename_glob])).tap_inspect
    end

    def list_named_blocks_in_file(call_options = {}, &options_block)
      opts = optsmerge call_options, options_block
      block_name_excluded_match = Regexp.new opts[:block_name_excluded_match]
      list_blocks_in_file(opts).map do |block|
        next if opts[:hide_blocks_by_name] && block[:name].match(block_name_excluded_match)

        block
      end.compact.tap_inspect
    end

    def list_recursively_required_blocks(table, name)
      name_block = get_block_by_name(table, name)
      raise "Named code block `#{name}` not found." if name_block.nil? || name_block.keys.empty?

      all = [name_block[:name]] + recursively_required(table, name_block[:reqs])

      # in order of appearance in document
      table.select { |block| all.include? block[:name] }
           .map { |block| block.fetch(:body, '') }
           .flatten(1)
           .tap_inspect
    end

    def most_recent(arr)
      return unless arr
      return if arr.count < 1

      arr.max.tap_inspect
    end

    def most_recent_list(arr)
      return unless arr
      return if (ac = arr.count) < 1

      arr.sort[-[ac, options[:list_count]].min..].reverse.tap_inspect
    end

    def list_recent_output
      most_recent_list(Dir.glob(File.join(@options[:saved_stdout_folder],
                                          @options[:saved_stdout_glob]))).tap_inspect
    end

    def list_recent_scripts
      most_recent_list(Dir.glob(File.join(@options[:saved_script_folder],
                                          @options[:saved_script_glob]))).tap_inspect
    end

    def make_block_label(block, call_options = {})
      opts = options.merge(call_options)
      if opts[:mdheadings]
        heads = block.fetch(:headings, []).compact.join(' # ')
        "#{block[:title]}  [#{heads}]  (#{opts[:filename]})"
      else
        "#{block[:title]}  (#{opts[:filename]})"
      end
    end

    def make_block_labels(call_options = {})
      opts = options.merge(call_options)
      list_blocks_in_file(opts).map do |block|
        # next if opts[:hide_blocks_by_name] && block[:name].match(%r{^:\(.+\)$})

        make_block_label block, opts
      end.compact.tap_inspect
    end

    def menu_data1
      val_as_bool = ->(value) { value.class.to_s == 'String' ? (value.chomp != '0') : value }
      val_as_int = ->(value) { value.to_i }
      val_as_str = ->(value) { value.to_s }
      # val_true = ->(_value) { true } # for commands, sets option to true
      set1 = [
        {
          arg_name: 'PATH',
          default: '.',
          description: 'Read configuration file',
          long_name: 'config',
          proc1: lambda { |value|
                   read_configuration_file! options, value
                 }
        },
        {
          arg_name: 'BOOL',
          default: false,
          description: 'Debug output',
          env_var: 'MDE_DEBUG',
          long_name: 'debug',
          short_name: 'd',
          proc1: lambda { |value|
                   $pdebug = value.to_i != 0
                 }
        },
        {
          arg_name: "INT.#{DISPLAY_LEVEL_BASE}-#{DISPLAY_LEVEL_MAX}",
          default: DISPLAY_LEVEL_DEFAULT,
          description: "Output display level (#{DISPLAY_LEVEL_BASE} to #{DISPLAY_LEVEL_MAX})",
          env_var: 'MDE_DISPLAY_LEVEL',
          long_name: 'display-level',
          opt_name: :display_level,
          proc1: val_as_int
        },
        {
          arg_name: 'NAME',
          compreply: false,
          description: 'Name of block',
          env_var: 'MDE_BLOCK_NAME',
          long_name: 'block-name',
          opt_name: :block_name,
          short_name: 'f',
          proc1: val_as_str
        },
        {
          arg_name: 'RELATIVE_PATH',
          compreply: '.',
          description: 'Name of document',
          env_var: 'MDE_FILENAME',
          long_name: 'filename',
          opt_name: :filename,
          short_name: 'f',
          proc1: val_as_str
        },
        {
          description: 'List blocks',
          long_name: 'list-blocks',
          opt_name: :list_blocks,
          proc1: val_as_bool
        },
        {
          arg_name: 'INT.1-',
          default: 32,
          description: 'Max. items to return in list',
          env_var: 'MDE_LIST_COUNT',
          long_name: 'list-count',
          opt_name: :list_count,
          proc1: val_as_int
        },
        {
          description: 'List default configuration as environment variables',
          long_name: 'list-default-env',
          opt_name: :list_default_env
        },
        {
          description: 'List default configuration as YAML',
          long_name: 'list-default-yaml',
          opt_name: :list_default_yaml
        },
        {
          description: 'List docs in current folder',
          long_name: 'list-docs',
          opt_name: :list_docs,
          proc1: val_as_bool
        },
        {
          description: 'List recent saved output',
          long_name: 'list-recent-output',
          opt_name: :list_recent_output,
          proc1: val_as_bool
        },
        {
          description: 'List recent saved scripts',
          long_name: 'list-recent-scripts',
          opt_name: :list_recent_scripts,
          proc1: val_as_bool
        },
        {
          arg_name: 'PREFIX',
          default: MarkdownExec::BIN_NAME,
          description: 'Name prefix for stdout files',
          env_var: 'MDE_LOGGED_STDOUT_FILENAME_PREFIX',
          long_name: 'logged-stdout-filename-prefix',
          opt_name: :logged_stdout_filename_prefix,
          proc1: val_as_str
        },
        {
          arg_name: 'BOOL',
          default: false,
          description: 'Display summary for execution',
          env_var: 'MDE_OUTPUT_EXECUTION_SUMMARY',
          long_name: 'output-execution-summary',
          opt_name: :output_execution_summary,
          proc1: val_as_bool
        },
        {
          arg_name: 'BOOL',
          default: false,
          description: 'Display script prior to execution',
          env_var: 'MDE_OUTPUT_SCRIPT',
          long_name: 'output-script',
          opt_name: :output_script,
          proc1: val_as_bool
        },
        {
          arg_name: 'BOOL',
          default: true,
          description: 'Display standard output from execution',
          env_var: 'MDE_OUTPUT_STDOUT',
          long_name: 'output-stdout',
          opt_name: :output_stdout,
          proc1: val_as_bool
        },
        {
          arg_name: 'RELATIVE_PATH',
          default: '.',
          description: 'Path to documents',
          env_var: 'MDE_PATH',
          long_name: 'path',
          opt_name: :path,
          short_name: 'p',
          proc1: val_as_str
        },
        {
          description: 'Gem home folder',
          long_name: 'pwd',
          opt_name: :pwd,
          proc1: val_as_bool
        },
        {
          description: 'Run most recently saved script',
          long_name: 'run-last-script',
          opt_name: :run_last_script,
          proc1: val_as_bool
        },
        {
          arg_name: 'BOOL',
          default: false,
          description: 'Save executed script',
          env_var: 'MDE_SAVE_EXECUTED_SCRIPT',
          long_name: 'save-executed-script',
          opt_name: :save_executed_script,
          proc1: val_as_bool
        },
        {
          arg_name: 'BOOL',
          default: false,
          description: 'Save standard output of the executed script',
          env_var: 'MDE_SAVE_EXECUTION_OUTPUT',
          long_name: 'save-execution-output',
          opt_name: :save_execution_output,
          proc1: val_as_bool
        },
        {
          arg_name: 'INT',
          default: 0o755,
          description: 'chmod for saved scripts',
          env_var: 'MDE_SAVED_SCRIPT_CHMOD',
          long_name: 'saved-script-chmod',
          opt_name: :saved_script_chmod,
          proc1: val_as_int
        },
        {
          arg_name: 'PREFIX',
          default: MarkdownExec::BIN_NAME,
          description: 'Name prefix for saved scripts',
          env_var: 'MDE_SAVED_SCRIPT_FILENAME_PREFIX',
          long_name: 'saved-script-filename-prefix',
          opt_name: :saved_script_filename_prefix,
          proc1: val_as_str
        },
        {
          arg_name: 'RELATIVE_PATH',
          default: 'logs',
          description: 'Saved script folder',
          env_var: 'MDE_SAVED_SCRIPT_FOLDER',
          long_name: 'saved-script-folder',
          opt_name: :saved_script_folder,
          proc1: val_as_str
        },
        {
          arg_name: 'GLOB',
          default: 'mde_*.sh',
          description: 'Glob matching saved scripts',
          env_var: 'MDE_SAVED_SCRIPT_GLOB',
          long_name: 'saved-script-glob',
          opt_name: :saved_script_glob,
          proc1: val_as_str
        },
        {
          arg_name: 'RELATIVE_PATH',
          default: 'logs',
          description: 'Saved stdout folder',
          env_var: 'MDE_SAVED_STDOUT_FOLDER',
          long_name: 'saved-stdout-folder',
          opt_name: :saved_stdout_folder,
          proc1: val_as_str
        },
        {
          arg_name: 'GLOB',
          default: 'mde_*.out.txt',
          description: 'Glob matching saved outputs',
          env_var: 'MDE_SAVED_STDOUT_GLOB',
          long_name: 'saved-stdout-glob',
          opt_name: :saved_stdout_glob,
          proc1: val_as_str
        },
        {
          description: 'Select and execute a recently saved output',
          long_name: 'select-recent-output',
          opt_name: :select_recent_output,
          proc1: val_as_bool
        },
        {
          description: 'Select and execute a recently saved script',
          long_name: 'select-recent-script',
          opt_name: :select_recent_script,
          proc1: val_as_bool
        },
        {
          description: 'YAML export of menu',
          long_name: 'menu-export',
          opt_name: :menu_export,
          proc1: val_as_bool
        },
        {
          description: 'List tab completions',
          long_name: 'tab-completions',
          opt_name: :tab_completions,
          proc1: val_as_bool
        },
        {
          arg_name: 'BOOL',
          default: true,
          description: 'Pause for user to approve script',
          env_var: 'MDE_USER_MUST_APPROVE',
          long_name: 'user-must-approve',
          opt_name: :user_must_approve,
          proc1: val_as_bool
        },
        {
          description: 'Show current configuration values',
          short_name: '0',
          proc1: lambda { |_|
                   options_finalize options
                   fout sorted_keys(options).to_yaml
                 }
        },
        {
          description: 'App help',
          long_name: 'help',
          short_name: 'h',
          proc1: lambda { |_|
                   fout menu_help
                   exit
                 }
        },
        {
          description: "Print the gem's version",
          long_name: 'version',
          short_name: 'v',
          proc1: lambda { |_|
                   fout MarkdownExec::VERSION
                   exit
                 }
        },
        {
          description: 'Exit app',
          long_name: 'exit',
          short_name: 'x',
          proc1: ->(_) { exit }
        },
        {
          default: '^\(.*\)$',
          description: 'Pattern for blocks to hide from user-selection',
          env_var: 'MDE_BLOCK_NAME_EXCLUDED_MATCH',
          opt_name: :block_name_excluded_match,
          proc1: val_as_str
        },
        {
          default: ':(?<title>\S+)( |$)',
          env_var: 'MDE_BLOCK_NAME_MATCH',
          opt_name: :block_name_match,
          proc1: val_as_str
        },
        {
          default: '\+\S+',
          env_var: 'MDE_BLOCK_REQUIRED_SCAN',
          opt_name: :block_required_scan,
          proc1: val_as_str
        },
        {
          default: '> ',
          env_var: 'MDE_DISPLAY_LEVEL_XBASE_PREFIX',
          opt_name: :display_level_xbase_prefix,
          proc1: val_as_str
        },
        {
          default: '^`{3,}',
          env_var: 'MDE_FENCED_START_AND_END_MATCH',
          opt_name: :fenced_start_and_end_match,
          proc1: val_as_str
        },
        {
          default: '^`{3,}(?<shell>[^`\s]*) *(?<name>.*)$',
          env_var: 'MDE_FENCED_START_EX_MATCH',
          opt_name: :fenced_start_ex_match,
          proc1: val_as_str
        },
        {
          default: '^# *(?<name>[^#]*?) *$',
          env_var: 'MDE_HEADING1_MATCH',
          opt_name: :heading1_match,
          proc1: val_as_str
        },
        {
          default: '^## *(?<name>[^#]*?) *$',
          env_var: 'MDE_HEADING2_MATCH',
          opt_name: :heading2_match,
          proc1: val_as_str
        },
        {
          default: '^### *(?<name>.+?) *$',
          env_var: 'MDE_HEADING3_MATCH',
          opt_name: :heading3_match,
          proc1: val_as_str
        },
        {
          default: '*.[Mm][Dd]',
          env_var: 'MDE_MD_FILENAME_GLOB',
          opt_name: :md_filename_glob,
          proc1: val_as_str
        },
        {
          default: '.+\\.md',
          env_var: 'MDE_MD_FILENAME_MATCH',
          opt_name: :md_filename_match,
          proc1: val_as_str
        },
        {
          description: 'Options for viewing saved output file',
          env_var: 'MDE_OUTPUT_VIEWER_OPTIONS',
          opt_name: :output_viewer_options,
          proc1: val_as_str
        },
        {
          default: 24,
          description: 'Maximum # of rows in select list',
          env_var: 'MDE_SELECT_PAGE_HEIGHT',
          opt_name: :select_page_height,
          proc1: val_as_int
        },
        {
          default: '#!/usr/bin/env',
          description: 'Shebang for saved scripts',
          env_var: 'MDE_SHEBANG',
          opt_name: :shebang,
          proc1: val_as_str
        },
        {
          default: 'bash',
          description: 'Shell for launched scripts',
          env_var: 'MDE_SHELL',
          opt_name: :shell,
          proc1: val_as_str
        }
      ]
      # commands first, options second
      (set1.reject { |v1| v1[:arg_name] }) + (set1.select { |v1| v1[:arg_name] })
    end

    def menu_iter(data = menu_data1, &block)
      data.map(&block)
    end

    def menu_help
      @option_parser.help
    end

    def option_exclude_blocks(opts, blocks)
      block_name_excluded_match = Regexp.new opts[:block_name_excluded_match]
      if opts[:hide_blocks_by_name]
        blocks.reject { |block| block[:name].match(block_name_excluded_match) }
      else
        blocks
      end
    end

    ## post-parse options configuration
    #
    def options_finalize(rest)
      ## position 0: file or folder (optional)
      #
      if (pos = rest.fetch(0, nil))&.present?
        if Dir.exist?(pos)
          @options[:path] = pos
        elsif File.exist?(pos)
          @options[:filename] = pos
        else
          raise "Invalid parameter: #{pos}"
        end
      end

      ## position 1: block name (optional)
      #
      block_name = rest.fetch(1, nil)
      @options[:block_name] = block_name if block_name.present?
    end

    def optsmerge(call_options = {}, options_block = nil)
      class_call_options = @options.merge(call_options || {})
      if options_block
        options_block.call class_call_options
      else
        class_call_options
      end.tap_inspect
    end

    def output_execution_result
      oq = [['Block', @options[:block_name], DISPLAY_LEVEL_ADMIN],
            ['Command',
             [MarkdownExec::BIN_NAME,
              @options[:filename],
              @options[:block_name]].join(' '),
             DISPLAY_LEVEL_ADMIN]]

      [['Script', :saved_filespec],
       ['StdOut', :logged_stdout_filespec]].each do |label, name|
        oq << [label, @options[name], DISPLAY_LEVEL_ADMIN] if @options[name]
      end

      oq.map do |label, value, level|
        lout ["#{label}:".yellow, value.to_s].join(' '), level: level
      end
    end

    def output_execution_summary
      return unless @options[:output_execution_summary]

      fout_section 'summary', {
        execute_aborted_at: @execute_aborted_at,
        execute_completed_at: @execute_completed_at,
        execute_error: @execute_error,
        execute_error_message: @execute_error_message,
        execute_files: @execute_files,
        execute_options: @execute_options,
        execute_started_at: @execute_started_at,
        execute_script_filespec: @execute_script_filespec
      }
    end

    def prompt_with_quit(prompt_text, items, opts = {})
      exit_option = '* Exit'
      all_items = if @options[:menu_exit_at_top]
                    (@options[:menu_with_exit] ? [exit_option] : []) + items
                  else
                    items + (@options[:menu_with_exit] ? [exit_option] : [])
                  end
      sel = @prompt.select(prompt_text, all_items, opts.merge(filter: true))
      sel == exit_option ? nil : sel
    end

    def read_configuration_file!(options, configuration_path)
      return unless File.exist?(configuration_path)

      # rubocop:disable Security/YAMLLoad
      options.merge!((YAML.load(File.open(configuration_path)) || {})
        .transform_keys(&:to_sym))
      # rubocop:enable Security/YAMLLoad
    end

    def recursively_required(table, reqs)
      all = []
      rem = reqs
      while rem.count.positive?
        rem = rem.map do |req|
          next if all.include? req

          all += [req]
          get_block_by_name(table, req).fetch(:reqs, [])
        end
                 .compact
                 .flatten(1)
                 .tap_inspect(name: 'rem')
      end
      all.tap_inspect
    end

    def run
      ## default configuration
      #
      @options = base_options

      ## read local configuration file
      #
      read_configuration_file! @options, ".#{MarkdownExec::APP_NAME.downcase}.yml"

      @option_parser = option_parser = OptionParser.new do |opts|
        executable_name = File.basename($PROGRAM_NAME)
        opts.banner = [
          "#{MarkdownExec::APP_NAME}" \
          " - #{MarkdownExec::APP_DESC} (#{MarkdownExec::VERSION})",
          "Usage: #{executable_name} [(path | filename [block_name])] [options]"
        ].join("\n")

        menu_iter do |item|
          next unless item[:long_name].present? || item[:short_name].present?

          opts.on(*[if item[:long_name].present?
                      "--#{item[:long_name]}#{item[:arg_name].present? ? " #{item[:arg_name]}" : ''}"
                    end,
                    item[:short_name].present? ? "-#{item[:short_name]}" : nil,
                    [item[:description],
                     item[:default].present? ? "[#{value_for_cli item[:default]}]" : nil].compact.join('  '),
                    lambda { |value|
                      # ret = item[:proc1].call(value)
                      ret = item[:proc1] ? item[:proc1].call(value) : value
                      options[item[:opt_name]] = ret if item[:opt_name]
                      ret
                    }].compact)
        end
      end
      option_parser.load # filename defaults to basename of the program without suffix in a directory ~/.options
      option_parser.environment # env defaults to the basename of the program.
      rest = option_parser.parse! # (into: options)

      options_finalize rest

      exec_block options, options[:block_name]
    end

    FNR11 = '/'
    FNR12 = ',~'

    def saved_name_make(opts)
      fne = opts[:filename].gsub(FNR11, FNR12)
      "#{[opts[:saved_script_filename_prefix], Time.now.utc.strftime('%F-%H-%M-%S'), fne,
          ',', opts[:block_name]].join('_')}.sh"
    end

    def saved_name_split(name)
      mf = name.match(/#{@options[:saved_script_filename_prefix]}_(?<time>[0-9\-]+)_(?<file>.+)_,_(?<block>.+)\.sh/)
      return unless mf

      @options[:block_name] = mf[:block].tap_inspect name: :options_block_name
      @options[:filename] = mf[:file].gsub(FNR12, FNR11).tap_inspect name: :options_filename
    end

    def run_last_script
      filename = most_recent Dir.glob(File.join(@options[:saved_script_folder],
                                                @options[:saved_script_glob]))
      return unless filename

      filename.tap_inspect name: filename
      saved_name_split filename
      @options[:save_executed_script] = false
      select_and_approve_block
    end

    def save_execution_output
      return unless @options[:save_execution_output]

      fne = File.basename(@options[:filename], '.*')

      @options[:logged_stdout_filename] =
        "#{[@options[:logged_stdout_filename_prefix], Time.now.utc.strftime('%F-%H-%M-%S'), fne,
            @options[:block_name]].join('_')}.out.txt"
      @options[:logged_stdout_filespec] = File.join @options[:saved_stdout_folder], @options[:logged_stdout_filename]
      @logged_stdout_filespec = @options[:logged_stdout_filespec]
      dirname = File.dirname(@options[:logged_stdout_filespec])
      Dir.mkdir dirname unless File.exist?(dirname)

      # File.write(@options[:logged_stdout_filespec], @execute_files&.fetch(EF_STDOUT, ''))
      ol = ["-STDOUT-\n"]
      ol += @execute_files&.fetch(EF_STDOUT, [])
      ol += ["-STDERR-\n"].tap_inspect name: :ol3
      ol += @execute_files&.fetch(EF_STDERR, [])
      ol += ["-STDIN-\n"]
      ol += @execute_files&.fetch(EF_STDIN, [])
      File.write(@options[:logged_stdout_filespec], ol.join)
    end

    def select_and_approve_block(call_options = {}, &options_block)
      opts = optsmerge call_options, options_block
      blocks_in_file = list_blocks_in_file(opts.merge(struct: true))

      loop1 = true && !opts[:block_name].present?

      loop do
        unless opts[:block_name].present?
          pt = (opts[:prompt_select_block]).to_s
          blocks_in_file.each { |block| block.merge! label: make_block_label(block, opts) }
          block_labels = option_exclude_blocks(opts, blocks_in_file).map { |block| block[:label] }

          return nil if block_labels.count.zero?

          sel = prompt_with_quit pt, block_labels, per_page: opts[:select_page_height]
          return nil if sel.nil?

          # if sel.nil?
          #   loop1 = false
          #   break
          # end

          label_block = blocks_in_file.select { |block| block[:label] == sel }.fetch(0, nil)
          opts[:block_name] = @options[:block_name] = label_block[:name]

        end
        # if loop1
        approve_block opts, blocks_in_file
        # end

        break unless loop1

        opts[:block_name] = ''
      end
    end

    def select_md_file(files_ = nil)
      opts = options
      files = files_ || list_markdown_files_in_path
      if files.count == 1
        files[0]
      elsif files.count >= 2
        prompt_with_quit opts[:prompt_select_md].to_s, files, per_page: opts[:select_page_height]
      end
    end

    def select_recent_output
      filename = prompt_with_quit @options[:prompt_select_output].to_s, list_recent_output,
                                  per_page: @options[:select_page_height]
      return unless filename.present?

      `open #{filename} #{options[:output_viewer_options]}`
    end

    def select_recent_script
      filename = prompt_with_quit @options[:prompt_select_md].to_s, list_recent_scripts,
                                  per_page: @options[:select_page_height]
      return if filename.nil?

      saved_name_split filename
      select_and_approve_block(
        bash: true,
        save_executed_script: false,
        struct: true
      )
    end

    def sorted_keys(hash1)
      hash1.keys.sort.to_h { |k| [k, hash1[k]] }
    end

    def summarize_block(headings, title)
      { headings: headings, name: title, title: title }
    end

    def menu_export(data = menu_data1)
      data.map do |item|
        item.delete(:proc1)
        item
      end.to_yaml
    end

    def tab_completions(data = menu_data1)
      data.map do |item|
        "--#{item[:long_name]}" if item[:long_name]
      end.compact
    end

    def update_options(opts = {}, over: true)
      if over
        @options = @options.merge opts
      else
        @options.merge! opts
      end
      @options.tap_inspect format: :yaml
    end

    def value_for_hash(value, default = nil)
      return default if value.nil?

      case value.class.to_s
      when 'String', 'Integer', 'FalseClass', 'TrueClass'
        value
      when value.empty?
        default
      else
        value.to_s
      end
    end

    def value_for_yaml(value)
      return default if value.nil?

      case value.class.to_s
      when 'String'
        "'#{value}'"
      when 'Integer'
        value
      when 'FalseClass', 'TrueClass'
        value ? true : false
      when value.empty?
        default
      else
        value.to_s
      end
    end

    def write_command_file(opts, required_blocks)
      return unless opts[:save_executed_script]

      opts[:saved_script_filename] = saved_name_make(opts)
      @execute_script_filespec =
        @options[:saved_filespec] =
          File.join opts[:saved_script_folder], opts[:saved_script_filename]

      dirname = File.dirname(@options[:saved_filespec])
      Dir.mkdir dirname unless File.exist?(dirname)
      (shebang = if @options[:shebang]&.present?
                   "#{@options[:shebang]} #{@options[:shell]}\n"
                 else
                   ''
                 end
      ).tap_inspect name: :shebang
      File.write(@options[:saved_filespec], shebang +
                                            "# file_name: #{opts[:filename]}\n" \
                                            "# block_name: #{opts[:block_name]}\n" \
                                            "# time: #{Time.now.utc}\n" \
                                            "#{required_blocks.flatten.join("\n")}\n")

      @options[:saved_script_chmod].tap_inspect name: :@options_saved_script_chmod
      return if @options[:saved_script_chmod].zero?

      @options[:saved_script_chmod].tap_inspect name: :@options_saved_script_chmod
      File.chmod @options[:saved_script_chmod], @options[:saved_filespec]
      @options[:saved_script_chmod].tap_inspect name: :@options_saved_script_chmod
    end
  end
end
