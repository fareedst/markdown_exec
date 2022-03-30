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
  return default if (val = ENV[name]).nil?
  return false if val.empty? || val == '0'

  true
end

def env_int(name, default: 0)
  return default if (val = ENV[name]).nil?
  return default if val.empty?

  val.to_i
end

def env_str(name, default: '')
  ENV[name] || default
end

$pdebug = env_bool 'MDE_DEBUG'

require_relative 'markdown_exec/version'

$stderr.sync = true
$stdout.sync = true

BLOCK_SIZE = 1024

class Object # rubocop:disable Style/Documentation
  def present?
    self && !blank?
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
      {
        # commands
        list_blocks: false, # command
        list_docs: false, # command

        # command options
        filename: env_str('MDE_FILENAME', default: nil), # option Filename to open
        output_execution_summary: env_bool('MDE_OUTPUT_EXECUTION_SUMMARY', default: false), # option
        output_script: env_bool('MDE_OUTPUT_SCRIPT', default: false), # option
        output_stdout: env_bool('MDE_OUTPUT_STDOUT', default: true), # option
        path: env_str('MDE_PATH', default: nil), # option Folder to search for files
        save_executed_script: env_bool('MDE_SAVE_EXECUTED_SCRIPT', default: false), # option
        saved_script_folder: env_str('MDE_SAVED_SCRIPT_FOLDER', default: 'logs'), # option
        user_must_approve: env_bool('MDE_USER_MUST_APPROVE', default: true), # option Pause for user to approve script

        # configuration options
        block_name_excluded_match: env_str('MDE_BLOCK_NAME_EXCLUDED_MATCH', default: '^\(.+\)$'),
        block_name_match: env_str('MDE_BLOCK_NAME_MATCH', default: ':(?<title>\S+)( |$)'),
        block_required_scan: env_str('MDE_BLOCK_REQUIRED_SCAN', default: '\+\S+'),
        fenced_start_and_end_match: env_str('MDE_FENCED_START_AND_END_MATCH', default: '^`{3,}'),
        fenced_start_ex_match: env_str('MDE_FENCED_START_EX_MATCH', default: '^`{3,}(?<shell>[^`\s]*) *(?<name>.*)$'),
        heading1_match: env_str('MDE_HEADING1_MATCH', default: '^# *(?<name>[^#]*?) *$'),
        heading2_match: env_str('MDE_HEADING2_MATCH', default: '^## *(?<name>[^#]*?) *$'),
        heading3_match: env_str('MDE_HEADING3_MATCH', default: '^### *(?<name>.+?) *$'),
        md_filename_glob: env_str('MDE_MD_FILENAME_GLOB', default: '*.[Mm][Dd]'),
        md_filename_match: env_str('MDE_MD_FILENAME_MATCH', default: '.+\\.md'),
        mdheadings: true, # use headings (levels 1,2,3) in block lable
        select_page_height: env_int('MDE_SELECT_PAGE_HEIGHT', default: 12)
      }
    end

    def default_options
      {
        bash: true, # bash block parsing in get_block_summary()
        exclude_expect_blocks: true,
        exclude_matching_block_names: true, # exclude hidden blocks
        output_saved_script_filename: false,
        prompt_select_block: 'Choose a block:', # in select_and_approve_block()
        prompt_select_md: 'Choose a file:', # in select_md_file()
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
      allow = @prompt.yes? 'Process?' if opts[:user_must_approve]
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
            @execute_files = Hash.new([])
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
      @execute_aborted_at = Time.now.utc
      @execute_error_message = e.message
      @execute_error = e
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

    def exec_block(options, block_name = '')
      options = default_options.merge options
      update_options options, over: false

      # document and block reports
      #
      files = list_files_per_options(options)
      if @options[:list_docs]
        fout_list files
        return
      end

      if @options[:list_blocks]
        fout_list (files.map do |file|
                     make_block_labels(filename: file, struct: true)
                   end).flatten(1)
        return
      end

      # process
      #
      select_and_approve_block(
        bash: true,
        block_name: block_name,
        filename: select_md_file(files),
        struct: true
      )

      fout "saved_filespec: #{@execute_script_filespec}" if @options[:output_saved_script_filename]

      output_execution_summary if @options[:output_execution_summary]
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

    def list_files_per_options(options)
      default_filename = 'README.md'
      default_folder = '.'
      if options[:filename]&.present?
        list_files_specified(options[:filename], options[:path], default_filename, default_folder)
      else
        list_files_specified(nil, options[:path], default_filename, default_folder)
      end.tap_inspect
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
        next if opts[:exclude_matching_block_names] && block[:name].match(block_name_excluded_match)

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
        # next if opts[:exclude_matching_block_names] && block[:name].match(%r{^:\(.+\)$})

        make_block_label block, opts
      end.compact.tap_inspect
    end

    def option_exclude_blocks(opts, blocks)
      block_name_excluded_match = Regexp.new opts[:block_name_excluded_match]
      if opts[:exclude_matching_block_names]
        blocks.reject { |block| block[:name].match(block_name_excluded_match) }
      else
        blocks
      end
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

      ## post-parse options configuration
      #
      options_finalize = ->(_options) {}

      proc_self = ->(value) { value }
      proc_to_i = ->(value) { value.to_i != 0 }
      proc_true = ->(_) { true }

      # read local configuration file
      #
      read_configuration_file! @options, ".#{MarkdownExec::APP_NAME.downcase}.yml"

      option_parser = OptionParser.new do |opts|
        executable_name = File.basename($PROGRAM_NAME)
        opts.banner = [
          "#{MarkdownExec::APP_NAME}" \
          " - #{MarkdownExec::APP_DESC} (#{MarkdownExec::VERSION})",
          "Usage: #{executable_name} [path] [filename] [options]"
        ].join("\n")

        summary_head = [
          ['config', nil, nil, 'PATH', 'Read configuration file',
           nil, ->(value) { read_configuration_file! options, value }],
          ['debug', 'd', 'MDE_DEBUG', 'BOOL', 'Debug output',
           nil, ->(value) { $pdebug = value.to_i != 0 }]
        ]

        summary_body = [
          ['filename', 'f', 'MDE_FILENAME', 'RELATIVE', 'Name of document',
           :filename, proc_self],
          ['list-blocks', nil, nil, nil, 'List blocks',
           :list_blocks, proc_true],
          ['list-docs', nil, nil, nil, 'List docs in current folder',
           :list_docs, proc_true],
          ['output-execution-summary', nil, 'MDE_OUTPUT_EXECUTION_SUMMARY', 'BOOL', 'Display summary for execution',
           :output_execution_summary, proc_to_i],
          ['output-script', nil, 'MDE_OUTPUT_SCRIPT', 'BOOL', 'Display script',
           :output_script, proc_to_i],
          ['output-stdout', nil, 'MDE_OUTPUT_STDOUT', 'BOOL', 'Display standard output from execution',
           :output_stdout, proc_to_i],
          ['path', 'p', 'MDE_PATH', 'PATH', 'Path to documents',
           :path, proc_self],
          ['save-executed-script', nil, 'MDE_SAVE_EXECUTED_SCRIPT', 'BOOL', 'Save executed script',
           :save_executed_script, proc_to_i],
          ['saved-script-folder', nil, 'MDE_SAVED_SCRIPT_FOLDER', 'SPEC', 'Saved script folder',
           :saved_script_folder, proc_self],
          ['user-must-approve', nil, 'MDE_USER_MUST_APPROVE', 'BOOL', 'Pause to approve execution',
           :user_must_approve, proc_to_i]
        ]

        # rubocop:disable Style/Semicolon
        summary_tail = [
          [nil, '0', nil, nil, 'Show configuration',
           nil, ->(_) { options_finalize.call options; fout options.to_yaml }],
          ['help', 'h', nil, nil, 'App help',
           nil, ->(_) { fout option_parser.help; exit }],
          ['version', 'v', nil, nil, 'App version',
           nil, ->(_) { fout MarkdownExec::VERSION; exit }],
          ['exit', 'x', nil, nil, 'Exit app',
           nil, ->(_) { exit }]
        ]
        # rubocop:enable Style/Semicolon

        (summary_head + summary_body + summary_tail)
          .map do |long_name, short_name, env_var, arg_name, description, opt_name, proc1| # rubocop:disable Metrics/ParameterLists
          opts.on(*[long_name.present? ? "--#{long_name}#{arg_name.present? ? (' ' + arg_name) : ''}" : nil,
                    short_name.present? ? "-#{short_name}" : nil,
                    [description,
                     env_var.present? ? "env: #{env_var}" : nil].compact.join(' - '),
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

      ## finalize configuration
      #
      options_finalize.call options

      ## position 0: file or folder (optional)
      #
      if (pos = rest.fetch(0, nil))&.present?
        if Dir.exist?(pos)
          options[:path] = pos
        elsif File.exist?(pos)
          options[:filename] = pos
        else
          raise "Invalid parameter: #{pos}"
        end
      end

      ## position 1: block name (optional)
      #
      block_name = rest.fetch(1, nil)

      exec_block options, block_name
    end

    def select_and_approve_block(call_options = {}, &options_block)
      opts = optsmerge call_options, options_block
      blocks_in_file = list_blocks_in_file(opts.merge(struct: true))

      unless opts[:block_name].present?
        pt = (opts[:prompt_select_block]).to_s
        blocks_in_file.each { |block| block.merge! label: make_block_label(block, opts) }
        block_labels = option_exclude_blocks(opts, blocks_in_file).map { |block| block[:label] }

        return nil if block_labels.count.zero?

        sel = @prompt.select(pt, block_labels, per_page: opts[:select_page_height])
        label_block = blocks_in_file.select { |block| block[:label] == sel }.fetch(0, nil)
        opts[:block_name] = label_block[:name]
      end

      approve_block opts, blocks_in_file
    end

    def select_md_file(files_ = nil)
      opts = options
      files = files_ || list_markdown_files_in_path
      if files.count == 1
        files[0]
      elsif files.count >= 2
        @prompt.select(opts[:prompt_select_md].to_s, files, per_page: opts[:select_page_height])
      end
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
      @options
    end

    def write_command_file(opts, required_blocks)
      return unless opts[:saved_script_filename].present?

      fne = File.basename(opts[:filename], '.*').gsub(/[^a-z0-9]/i, '-') # scan(/[a-z0-9]/i).join
      bne = opts[:block_name].gsub(/[^a-z0-9]/i, '-') # scan(/[a-z0-9]/i).join
      opts[:saved_script_filename] = "mde_#{Time.now.utc.strftime '%F-%H-%M-%S'}_#{fne}_#{bne}.sh"

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
