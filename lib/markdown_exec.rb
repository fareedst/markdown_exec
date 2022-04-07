#!/usr/bin/env ruby
# frozen_string_literal: true

# encoding=utf-8

require 'open3'
require 'optparse'
require 'tty-prompt'
require 'yaml'

##
# default if nil
# false if empty or '0'
# else true

def env_bool(name, default: false)
  return default if name.nil? || (val = ENV[name]).nil?
  return false if val.empty? || val == '0'

  true
end

def env_int(name, default: 0)
  return default if name.nil? || (val = ENV[name]).nil?
  return default if val.empty?

  val.to_i
end

def env_str(name, default: '')
  return default if name.nil? || (val = ENV[name]).nil?

  val || default
end

$pdebug = env_bool 'MDE_DEBUG'

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

# debug output
#
def tap_inspect(format: nil, name: 'return')
  return self unless $pdebug

  fn = case format
       when :json
         :to_json
       when :string
         :to_s
       when :yaml
         :to_yaml
       else
         :inspect
       end

  puts "-> #{caller[0].scan(/in `?(\S+)'$/)[0][0]}()" \
       " #{name}: #{method(fn).call}"

  self
end

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
      menu_data
        .map do |_long_name, _short_name, env_var, _arg_name, _description, opt_name, default, _proc1| # rubocop:disable Metrics/ParameterLists
        next unless opt_name.present?

        [opt_name, env_bool(env_var, default: value_for_hash(default))]
      end.compact.to_h.merge(
        {
          mdheadings: true, # use headings (levels 1,2,3) in block lable
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
      allow = @prompt.yes? opts[:prompt_approve_block] if opts[:user_must_approve]
      opts[:ir_approve] = allow
      selected = get_block_by_name blocks_in_file, opts[:block_name]

      if opts[:ir_approve]
        write_command_file(opts, required_blocks) if opts[:save_executed_script]
        command_execute opts, required_blocks.flatten.join("\n")
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
      Open3.popen3(cmd2) do |stdin, stdout, stderr|
        stdin.close_write
        begin
          files = [stdout, stderr]

          until all_at_eof(files)
            ready = IO.select(files)

            next unless ready

            # readable = ready[0]
            # # writable = ready[1]
            # # exceptions = ready[2]
            ready.each.with_index do |readable, ind|
              readable.each do |f|
                block = f.read_nonblock(BLOCK_SIZE)
                @execute_files[ind] = @execute_files[ind] + [block]
                print block if opts[:output_stdout]
              rescue EOFError #=> e
                # do nothing at EOF
              end
            end
          end
        rescue IOError => e
          fout "IOError: #{e}"
        end
        @execute_completed_at = Time.now.utc
      end
    rescue Errno::ENOENT => e
      # error triggered by missing command in script
      @execute_aborted_at = Time.now.utc
      @execute_error_message = e.message
      @execute_error = e
      @execute_files[1] = e.message
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
      required_blocks.each { |cb| fout cb }
    end

    def exec_block(options, _block_name = '')
      options = default_options.merge options
      update_options options, over: false

      # document and block reports
      #
      files = list_files_per_options(options)
      if @options[:list_blocks]
        fout_list (files.map do |file|
                     make_block_labels(filename: file, struct: true)
                   end).flatten(1)
        return
      end

      if @options[:list_default_yaml]
        fout_list list_default_yaml
        return
      end

      if @options[:list_docs]
        fout_list files
        return
      end

      if @options[:list_default_env]
        fout_list list_default_env
        return
      end

      if @options[:list_recent_scripts]
        fout_list list_recent_scripts
        return
      end

      if @options[:run_last_script]
        run_last_script
        return
      end

      if @options[:select_recent_script]
        select_recent_script
        return
      end

      # process
      #
      @options[:filename] = select_md_file(files)
      select_and_approve_block(
        bash: true,
        struct: true
      )
      fout "saved_filespec: #{@execute_script_filespec}" if @options[:output_saved_script_filename]
      save_execution_output
      output_execution_summary
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

    def list_blocks_in_file(call_options = {}, &options_block)
      opts = optsmerge call_options, options_block

      unless opts[:filename]&.present?
        fout 'No blocks found.'
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
      menu_data
        .map do |_long_name, _short_name, env_var, _arg_name, description, _opt_name, default, _proc1| # rubocop:disable Metrics/ParameterLists
        next unless env_var.present?

        [
          "#{env_var}=#{value_for_cli default}",
          description.present? ? description : nil
        ].compact.join('      # ')
      end.compact.sort
    end

    def list_default_yaml
      menu_data
        .map do |_long_name, _short_name, _env_var, _arg_name, description, opt_name, default, _proc1| # rubocop:disable Metrics/ParameterLists
        next unless opt_name.present? && default.present?

        [
          "#{opt_name}: #{value_for_yaml default}",
          description.present? ? description : nil
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

    def list_recent_scripts
      Dir.glob(File.join(@options[:saved_script_folder],
                         @options[:saved_script_glob])).sort[0..(options[:list_count] - 1)].reverse.tap_inspect
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

    def menu_data
      val_as_bool = ->(value) { value.to_i != 0 }
      val_as_int = ->(value) { value.to_i }
      val_as_str = ->(value) { value.to_s }
      val_true = ->(_) { true }

      summary_head = [
        ['config', nil, nil, 'PATH', 'Read configuration file', nil, '.', lambda { |value|
                                                                            read_configuration_file! options, value
                                                                          }],
        ['debug', 'd', 'MDE_DEBUG', 'BOOL', 'Debug output', nil, false, ->(value) { $pdebug = value.to_i != 0 }]
      ]

      # rubocop:disable Layout/LineLength
      summary_body = [
        ['filename', 'f', 'MDE_FILENAME', 'RELATIVE', 'Name of document', :filename, nil, val_as_str],
        ['list-blocks', nil, nil, nil, 'List blocks', :list_blocks, nil, val_true],
        ['list-count', nil, 'MDE_LIST_COUNT', 'NUM', 'Max. items to return in list', :list_count, 16, val_as_int],
        ['list-default-env', nil, nil, nil, 'List default configuration as environment variables', :list_default_env, nil, val_true],
        ['list-default-yaml', nil, nil, nil, 'List default configuration as YAML', :list_default_yaml, nil, val_true],
        ['list-docs', nil, nil, nil, 'List docs in current folder', :list_docs, nil, val_true],
        ['list-recent-scripts', nil, nil, nil, 'List recent saved scripts', :list_recent_scripts, nil, val_true],
        ['logged-stdout-filename-prefix', nil, 'MDE_LOGGED_STDOUT_FILENAME_PREFIX', 'NAME', 'Name prefix for stdout files', :logged_stdout_filename_prefix, 'mde', val_as_str],
        ['output-execution-summary', nil, 'MDE_OUTPUT_EXECUTION_SUMMARY', 'BOOL', 'Display summary for execution', :output_execution_summary, false, val_as_bool],
        ['output-script', nil, 'MDE_OUTPUT_SCRIPT', 'BOOL', 'Display script prior to execution', :output_script, false, val_as_bool],
        ['output-stdout', nil, 'MDE_OUTPUT_STDOUT', 'BOOL', 'Display standard output from execution', :output_stdout, true, val_as_bool],
        ['path', 'p', 'MDE_PATH', 'PATH', 'Path to documents', :path, nil, val_as_str],
        ['run-last-script', nil, nil, nil, 'Run most recently saved script', :run_last_script, nil, val_true],
        ['select-recent-script', nil, nil, nil, 'Select and execute a recently saved script', :select_recent_script, nil, val_true],
        ['save-executed-script', nil, 'MDE_SAVE_EXECUTED_SCRIPT', 'BOOL', 'Save executed script', :save_executed_script, false, val_as_bool],
        ['save-execution-output', nil, 'MDE_SAVE_EXECUTION_OUTPUT', 'BOOL', 'Save standard output of the executed script', :save_execution_output, false, val_as_bool],
        ['saved-script-filename-prefix', nil, 'MDE_SAVED_SCRIPT_FILENAME_PREFIX', 'NAME', 'Name prefix for saved scripts', :saved_script_filename_prefix, 'mde', val_as_str],
        ['saved-script-folder', nil, 'MDE_SAVED_SCRIPT_FOLDER', 'SPEC', 'Saved script folder', :saved_script_folder, 'logs', val_as_str],
        ['saved-script-glob', nil, 'MDE_SAVED_SCRIPT_GLOB', 'SPEC', 'Glob matching saved scripts', :saved_script_glob, 'mde_*.sh', val_as_str],
        ['saved-stdout-folder', nil, 'MDE_SAVED_STDOUT_FOLDER', 'SPEC', 'Saved stdout folder', :saved_stdout_folder, 'logs', val_as_str],
        ['user-must-approve', nil, 'MDE_USER_MUST_APPROVE', 'BOOL', 'Pause for user to approve script', :user_must_approve, true, val_as_bool]
      ]
      # rubocop:enable Layout/LineLength

      # rubocop:disable Style/Semicolon
      summary_tail = [
        [nil, '0', nil, nil, 'Show current configuration values',
         nil, nil, ->(_) { options_finalize options; fout sorted_keys(options).to_yaml }],
        ['help', 'h', nil, nil, 'App help',
         nil, nil, ->(_) { fout menu_help; exit }],
        ['version', 'v', nil, nil, 'App version',
         nil, nil, ->(_) { fout MarkdownExec::VERSION; exit }],
        ['exit', 'x', nil, nil, 'Exit app',
         nil, nil, ->(_) { exit }]
      ]
      # rubocop:enable Style/Semicolon

      env_vars = [
        [nil, nil, 'MDE_BLOCK_NAME_EXCLUDED_MATCH', nil, 'Pattern for blocks to hide from user-selection',
         :block_name_excluded_match, '^\(.+\)$', nil],
        [nil, nil, 'MDE_BLOCK_NAME_MATCH', nil, '', :block_name_match, ':(?<title>\S+)( |$)', nil],
        [nil, nil, 'MDE_BLOCK_REQUIRED_SCAN', nil, '', :block_required_scan, '\+\S+', nil],
        [nil, nil, 'MDE_FENCED_START_AND_END_MATCH', nil, '', :fenced_start_and_end_match, '^`{3,}', nil],
        [nil, nil, 'MDE_FENCED_START_EX_MATCH', nil, '', :fenced_start_ex_match,
         '^`{3,}(?<shell>[^`\s]*) *(?<name>.*)$', nil],
        [nil, nil, 'MDE_HEADING1_MATCH', nil, '', :heading1_match, '^# *(?<name>[^#]*?) *$', nil],
        [nil, nil, 'MDE_HEADING2_MATCH', nil, '', :heading2_match, '^## *(?<name>[^#]*?) *$', nil],
        [nil, nil, 'MDE_HEADING3_MATCH', nil, '', :heading3_match, '^### *(?<name>.+?) *$', nil],
        [nil, nil, 'MDE_MD_FILENAME_GLOB', nil, '', :md_filename_glob, '*.[Mm][Dd]', nil],
        [nil, nil, 'MDE_MD_FILENAME_MATCH', nil, '', :md_filename_match, '.+\\.md', nil],
        [nil, nil, 'MDE_SELECT_PAGE_HEIGHT', nil, '', :select_page_height, 12, nil]
        # [nil, nil, 'MDE_', nil, '', nil, '', nil],
      ]

      summary_head + summary_body + summary_tail + env_vars
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
      @options[:block_name] = rest.fetch(1, nil)
    end

    def optsmerge(call_options = {}, options_block = nil)
      class_call_options = @options.merge(call_options || {})
      if options_block
        options_block.call class_call_options
      else
        class_call_options
      end.tap_inspect
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
      sel = @prompt.select prompt_text,
                           items + (@options[:menu_with_exit] ? [exit_option] : []),
                           opts
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
          "Usage: #{executable_name} [path] [filename] [options]"
        ].join("\n")

        menu_data
          .map do |long_name, short_name, _env_var, arg_name, description, opt_name, default, proc1| # rubocop:disable Metrics/ParameterLists
          next unless long_name.present? || short_name.present?

          opts.on(*[if long_name.present?
                      "--#{long_name}#{arg_name.present? ? " #{arg_name}" : ''}"
                    end,
                    short_name.present? ? "-#{short_name}" : nil,
                    [description,
                     default.present? ? "[#{value_for_cli default}]" : nil].compact.join('  '),
                    lambda { |value|
                      ret = proc1.call(value)
                      options[opt_name] = ret if opt_name
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

    def run_last_script
      filename = Dir.glob(File.join(@options[:saved_script_folder],
                                    @options[:saved_script_glob])).sort[0..(options[:list_count] - 1)].last
      filename.tap_inspect name: filename
      mf = filename.match(/#{@options[:saved_script_filename_prefix]}_(?<time>[0-9\-]+)_(?<file>.+)_(?<block>.+)\.sh/)

      @options[:block_name] = mf[:block]
      @options[:filename] = "#{mf[:file]}.md" ### other extensions
      @options[:save_executed_script] = false
      select_and_approve_block
      save_execution_output
      output_execution_summary
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
      File.write(@options[:logged_stdout_filespec], @execute_files&.fetch(0, ''))
    end

    def select_and_approve_block(call_options = {}, &options_block)
      opts = optsmerge call_options, options_block
      blocks_in_file = list_blocks_in_file(opts.merge(struct: true))

      unless opts[:block_name].present?
        pt = (opts[:prompt_select_block]).to_s
        blocks_in_file.each { |block| block.merge! label: make_block_label(block, opts) }
        block_labels = option_exclude_blocks(opts, blocks_in_file).map { |block| block[:label] }

        return nil if block_labels.count.zero?

        sel = prompt_with_quit pt, block_labels, per_page: opts[:select_page_height]
        return nil if sel.nil?

        label_block = blocks_in_file.select { |block| block[:label] == sel }.fetch(0, nil)
        opts[:block_name] = @options[:block_name] = label_block[:name]
      end

      approve_block opts, blocks_in_file
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

    def select_recent_script
      filename = prompt_with_quit @options[:prompt_select_md].to_s, list_recent_scripts,
                                  per_page: @options[:select_page_height]
      return if filename.nil?

      mf = filename.match(/#{@options[:saved_script_filename_prefix]}_(?<time>[0-9\-]+)_(?<file>.+)_(?<block>.+)\.sh/)

      @options[:block_name] = mf[:block]
      @options[:filename] = "#{mf[:file]}.md" ### other extensions
      select_and_approve_block(
        bash: true,
        save_executed_script: false,
        struct: true
      )
      save_execution_output
      output_execution_summary
    end

    def sorted_keys(hash1)
      hash1.keys.sort.to_h { |k| [k, hash1[k]] }
    end

    def summarize_block(headings, title)
      { headings: headings, name: title, title: title }
    end

    def update_options(opts = {}, over: true)
      if over
        @options = @options.merge opts
      else
        @options.merge! opts
      end
      @options.tap_inspect format: :yaml
    end

    def value_for_cli(value)
      case value.class.to_s
      when 'String'
        "'#{value}'"
      when 'FalseClass', 'TrueClass'
        value ? '1' : '0'
      when 'Integer'
        value
      else
        value.to_s
      end
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
      fne = File.basename(opts[:filename], '.*')
      opts[:saved_script_filename] =
        "#{[opts[:saved_script_filename_prefix], Time.now.utc.strftime('%F-%H-%M-%S'), fne,
            opts[:block_name]].join('_')}.sh"
      @options[:saved_filespec] = File.join opts[:saved_script_folder], opts[:saved_script_filename]
      @execute_script_filespec = @options[:saved_filespec]
      dirname = File.dirname(@options[:saved_filespec])
      Dir.mkdir dirname unless File.exist?(dirname)
      File.write(@options[:saved_filespec], "#!/usr/bin/env bash\n" \
                                            "# file_name: #{opts[:filename]}\n" \
                                            "# block_name: #{opts[:block_name]}\n" \
                                            "# time: #{Time.now.utc}\n" \
                                            "#{required_blocks.flatten.join("\n")}\n")
    end
  end
end
