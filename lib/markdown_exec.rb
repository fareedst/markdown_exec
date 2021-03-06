#!/usr/bin/env ruby
# frozen_string_literal: true

# encoding=utf-8

require 'English'
require 'clipboard'
require 'open3'
require 'optparse'
require 'shellwords'
require 'tty-prompt'
require 'yaml'

require_relative 'colorize'
require_relative 'env'
require_relative 'shared'
require_relative 'tap'
require_relative 'markdown_exec/version'

include Tap
tap_config envvar: MarkdownExec::TAP_DEBUG

$stderr.sync = true
$stdout.sync = true

BLOCK_SIZE = 1024

# hash with keys sorted by name
#
class Hash
  def sort_by_key
    keys.sort.to_h { |key| [key, self[key]] }
  end
end

# is the value a non-empty string or a binary?
#
# :reek:ManualDispatch ### temp
class Object
  def present?
    case self.class.to_s
    when 'FalseClass', 'TrueClass'
      true
    else
      self && (!respond_to?(:blank?) || !blank?)
    end
  end
end

# is value empty?
#
class String
  BLANK_RE = /\A[[:space:]]*\z/.freeze
  def blank?
    empty? || BLANK_RE.match?(self)
  end
end

public

# execute markdown documents
#
module MarkdownExec
  # :reek:IrresponsibleModule
  class Error < StandardError; end

  ## an imported markdown document
  #
  class MDoc
    def initialize(table)
      @table = table
    end

    def collect_recursively_required_code(name)
      get_required_blocks(name)
        .map do |block|
        block.tap_inspect name: :block, format: :yaml
        body = block[:body].join("\n")

        if block[:cann]
          xcall = block[:cann][1..-2].tap_inspect name: :xcall
          mstdin = xcall.match(/<(?<type>\$)?(?<name>[A-Za-z_-]\S+)/).tap_inspect name: :mstdin
          mstdout = xcall.match(/>(?<type>\$)?(?<name>[A-Za-z_-]\S+)/).tap_inspect name: :mstdout
          yqcmd = if mstdin[:type]
                    "echo \"$#{mstdin[:name]}\" | yq '#{body}'"
                  else
                    "yq e '#{body}' '#{mstdin[:name]}'"
                  end.tap_inspect name: :yqcmd
          if mstdout[:type]
            "export #{mstdout[:name]}=$(#{yqcmd})"
          else
            "#{yqcmd} > '#{mstdout[:name]}'"
          end
        elsif block[:stdout]
          stdout = block[:stdout].tap_inspect name: :stdout
          body = block[:body].join("\n").tap_inspect name: :body
          if stdout[:type]
            # "export #{stdout[:name]}=#{Shellwords.escape body}"
            %(export #{stdout[:name]}=$(cat <<"EOF"\n#{body}\nEOF\n))
          else
            "cat > '#{stdout[:name]}' <<\"EOF\"\n" \
              "#{body}\n" \
              "EOF\n"
          end
        else
          block[:body]
        end
      end.flatten(1)
        .tap_inspect format: :yaml
    end

    def get_block_by_name(name, default = {})
      name.tap_inspect name: :name
      @table.select { |block| block[:name] == name }.fetch(0, default).tap_inspect format: :yaml
    end

    def get_required_blocks(name)
      name_block = get_block_by_name(name)
      raise "Named code block `#{name}` not found." if name_block.nil? || name_block.keys.empty?

      all = [name_block[:name]] + recursively_required(name_block[:reqs])

      # in order of appearance in document
      sel = @table.select { |block| all.include? block[:name] }

      # insert function blocks
      sel.map do |block|
        block.tap_inspect name: :block, format: :yaml
        if (call = block[:call])
          [get_block_by_name("[#{call.match(/^\((\S+) |\)/)[1]}]").merge({ cann: call })]
        else
          []
        end + [block]
      end.flatten(1) # .tap_inspect format: :yaml
    end

    # :reek:UtilityFunction
    def hide_menu_block_per_options(opts, block)
      (opts[:hide_blocks_by_name] &&
              block[:name].match(Regexp.new(opts[:block_name_excluded_match]))).tap_inspect
    end

    def blocks_for_menu(opts)
      if opts[:hide_blocks_by_name]
        @table.reject { |block| hide_menu_block_per_options opts, block }
      else
        @table
      end
    end

    def recursively_required(reqs)
      all = []
      rem = reqs
      while rem.count.positive?
        rem = rem.map do |req|
          next if all.include? req

          all += [req]
          get_block_by_name(req).fetch(:reqs, [])
        end
                 .compact
                 .flatten(1)
      end
      all.tap_inspect format: :yaml
    end
  end # class MDoc

  # format option defaults and values
  #
  # :reek:TooManyInstanceVariables
  class BlockLabel
    def initialize(filename:, headings:, menu_blocks_with_docname:, menu_blocks_with_headings:, title:)
      @filename = filename
      @headings = headings
      @menu_blocks_with_docname = menu_blocks_with_docname
      @menu_blocks_with_headings = menu_blocks_with_headings
      @title = title
    end

    def make
      ([@title] +
        (if @menu_blocks_with_headings
           [@headings.compact.join(' # ')]
         else
           []
         end) +
        (
          if @menu_blocks_with_docname
            [@filename]
          else
            []
          end
        )).join('  ')
    end
  end # class BlockLabel

  FNR11 = '/'
  FNR12 = ',~'

  # format option defaults and values
  #
  class SavedAsset
    def initialize(filename:, prefix:, time:, blockname:)
      @filename = filename
      @prefix = prefix
      @time = time
      @blockname = blockname
    end

    def script_name
      fne = @filename.gsub(FNR11, FNR12)
      "#{[@prefix, @time.strftime('%F-%H-%M-%S'), fne, ',', @blockname].join('_')}.sh".tap_inspect
    end

    def stdout_name
      "#{[@prefix, @time.strftime('%F-%H-%M-%S'), @filename, @blockname].join('_')}.out.txt".tap_inspect
    end
  end # class SavedAsset

  # format option defaults and values
  #
  class OptionValue
    def initialize(value)
      @value = value
    end

    # as default value in env_str()
    #
    def for_hash(default = nil)
      return default if @value.nil?

      case @value.class.to_s
      when 'String', 'Integer'
        @value
      when 'FalseClass', 'TrueClass'
        @value ? true : false
      when @value.empty?
        default
      else
        @value.to_s
      end
    end

    # for output as default value in list_default_yaml()
    #
    def for_yaml(default = nil)
      return default if @value.nil?

      case @value.class.to_s
      when 'String'
        "'#{@value}'"
      when 'Integer'
        @value
      when 'FalseClass', 'TrueClass'
        @value ? true : false
      when @value.empty?
        default
      else
        @value.to_s
      end
    end
  end # class OptionValue

  # a generated list of saved files
  #
  class Sfiles
    def initialize(folder, glob)
      @folder = folder
      @glob = glob
    end

    def list_all
      Dir.glob(File.join(@folder, @glob)).tap_inspect
    end

    def most_recent(arr = nil)
      arr = list_all if arr.nil?
      return if arr.count < 1

      arr.max.tap_inspect
    end

    def most_recent_list(list_count, arr = nil)
      arr = list_all if arr.nil?
      return if (ac = arr.count) < 1

      arr.sort[-[ac, list_count].min..].reverse.tap_inspect
    end
  end # class Sfiles

  ##
  #
  # :reek:DuplicateMethodCall { allow_calls: ['block', 'item', 'lm', 'opts', 'option', '@options', 'required_blocks'] }
  # :reek:MissingSafeMethod { exclude: [ read_configuration_file! ] }
  # :reek:TooManyInstanceVariables ### temp
  # :reek:TooManyMethods ### temp
  class MarkParse
    attr_reader :options

    def initialize(options = {})
      @options = options
      @prompt = TTY::Prompt.new(interrupt: :exit)
      @execute_aborted_at = nil
      @execute_completed_at = nil
      @execute_error = nil
      @execute_error_message = nil
      @execute_files = nil
      @execute_options = nil
      @execute_script_filespec = nil
      @execute_started_at = nil
      @option_parser = nil
    end

    ##
    # options necessary to start, parse input, defaults for cli options

    def base_options
      menu_iter do |item|
        # noisy item.tap_inspect name: :item, format: :yaml
        next unless item[:opt_name].present?

        item_default = item[:default]
        # noisy item_default.tap_inspect name: :item_default
        value = if item_default.nil?
                  item_default
                else
                  env_str(item[:env_var], default: OptionValue.new(item_default).for_hash)
                end
        [item[:opt_name], item[:proc1] ? item[:proc1].call(value) : value]
      end.compact.to_h.merge(
        {
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

    def approve_block(opts, mdoc)
      required_blocks = mdoc.collect_recursively_required_code(opts[:block_name])
      display_command(opts, required_blocks) if opts[:output_script] || opts[:user_must_approve]

      allow = true
      if opts[:user_must_approve]
        loop do
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
            fout "Clipboard updated: #{required_blocks.count} blocks," /
                 " #{required_blocks.flatten.count} lines," /
                 " #{text.length} characters"
          end
          if sel == 4
            write_command_file(opts.merge(save_executed_script: true), required_blocks)
            fout "File saved: #{@options[:saved_filespec]}"
          end
          break if [1, 2].include? sel
        end
      end
      (opts[:ir_approve] = allow).tap_inspect name: :allow

      selected = mdoc.get_block_by_name opts[:block_name]

      if opts[:ir_approve]
        write_command_file opts, required_blocks
        command_execute opts, required_blocks.flatten.join("\n")
        save_execution_output
        output_execution_summary
        output_execution_result
      end

      selected[:name]
    end

    # :reek:DuplicateMethodCall
    # :reek:UncommunicativeVariableName { exclude: [ e ] }
    # :reek:LongYieldList
    def command_execute(opts, command)
      @execute_files = Hash.new([])
      @execute_options = opts
      @execute_started_at = Time.now.utc

      Open3.popen3(@options[:shell], '-c', command) do |stdin, stdout, stderr, exec_thr|
        Thread.new do
          until (line = stdout.gets).nil?
            @execute_files[EF_STDOUT] = @execute_files[EF_STDOUT] + [line]
            print line if opts[:output_stdout]
            yield nil, line, nil, exec_thr if block_given?
          end
        rescue IOError
          # thread killed, do nothing
        end

        Thread.new do
          until (line = stderr.gets).nil?
            @execute_files[EF_STDERR] = @execute_files[EF_STDERR] + [line]
            print line if opts[:output_stdout]
            yield nil, nil, line, exec_thr if block_given?
          end
        rescue IOError
          # thread killed, do nothing
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
      @execute_files[EF_STDERR] += [@execute_error_message]
      fout "Error ENOENT: #{e.inspect}"
    rescue SignalException => e
      # SIGTERM triggered by user or system
      @execute_aborted_at = Time.now.utc
      @execute_error_message = 'SIGTERM'
      @execute_error = e
      @execute_files[EF_STDERR] += [@execute_error_message]
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

    # :reek:DuplicateMethodCall
    def display_command(_opts, required_blocks)
      frame = ' #=#=#'.yellow
      fout frame
      required_blocks.each { |cb| fout cb }
      fout frame
    end

    # :reek:DuplicateMethodCall
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
        list_recent_output: lambda {
                              fout_list list_recent_output(@options[:saved_stdout_folder],
                                                           @options[:saved_stdout_glob], @options[:list_count])
                            },
        list_recent_scripts: lambda {
                               fout_list list_recent_scripts(options[:saved_script_folder],
                                                             options[:saved_script_glob], options[:list_count])
                             },
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

    # :reek:LongParameterList
    def get_block_summary(call_options = {}, headings:, block_title:, block_body:)
      opts = optsmerge call_options
      return [block_body] unless opts[:struct]
      return [summarize_block(headings, block_title).merge({ body: block_body })] unless opts[:bash]

      block_title.tap_inspect name: :block_title
      call = block_title.scan(Regexp.new(opts[:block_calls_scan]))
                        .map { |scanned| scanned[1..] }
                          &.first.tap_inspect name: :call
      (titlexcall = call ? block_title.sub("%#{call}", '') : block_title).tap_inspect name: :titlexcall

      bm = titlexcall.match(Regexp.new(opts[:block_name_match]))
      reqs = titlexcall.scan(Regexp.new(opts[:block_required_scan]))
                       .map { |scanned| scanned[1..] }
      stdin = titlexcall.match(Regexp.new(opts[:block_stdin_scan])).tap_inspect name: :stdin
      stdout = titlexcall.match(Regexp.new(opts[:block_stdout_scan])).tap_inspect name: :stdout

      title = bm && bm[1] ? bm[:title] : titlexcall
      [summarize_block(headings, title).merge({ body: block_body,
                                                call: call,
                                                reqs: reqs,
                                                stdin: stdin,
                                                stdout: stdout })].tap_inspect format: :yaml
    end

    def approved_fout?(level)
      level <= @options[:display_level]
    end

    # display output at level or lower than filter (DISPLAY_LEVEL_DEFAULT)
    #
    def lout(str, level: DISPLAY_LEVEL_BASE)
      return unless approved_fout? level

      fout level == DISPLAY_LEVEL_BASE ? str : @options[:display_level_xbase_prefix] + str
    end

    # :reek:DuplicateMethodCall
    # :reek:LongYieldList
    def iter_blocks_in_file(opts = {})
      # opts = optsmerge call_options, options_block

      unless opts[:filename]&.present?
        fout 'No blocks found.'
        return
      end

      unless File.exist? opts[:filename]
        fout 'Document is missing.'
        return
      end

      fenced_start_and_end_match = Regexp.new opts[:fenced_start_and_end_match]
      fenced_start_ex = Regexp.new opts[:fenced_start_ex_match]
      block_title = ''
      block_body = nil
      headings = []
      in_block = false

      selected_messages = yield :filter

      File.readlines(opts[:filename]).each do |line|
        continue unless line

        if opts[:menu_blocks_with_headings]
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
            if block_body
              # end block
              #
              block_title = block_body.join(' ').gsub(/  +/, ' ')[0..64] if block_title.nil? || block_title.empty?
              yield :blocks, headings, block_title, block_body if block_given? && selected_messages.include?(:blocks)
              block_body = nil
            end
            in_block = false
            block_title = ''
          else
            # start block
            #
            lm = line.match(fenced_start_ex)
            block_allow = false
            if opts[:bash_only]
              block_allow = true if lm && (lm[:shell] == 'bash')
            else
              block_allow = true
              block_allow = !(lm && (lm[:shell] == 'expect')) if opts[:exclude_expect_blocks]
            end

            in_block = true
            if block_allow && (!opts[:title_match] || (lm && lm[:name] && lm[:name].match(opts[:title_match])))
              block_body = []
              block_title = (lm && lm[:name])
            end
          end
        elsif block_body
          block_body += [line.chomp]
        elsif block_given? && selected_messages.include?(:line)
          # text outside of block
          #
          yield :line, nil, nil, line
        end
      end
    end

    def list_blocks_in_file(call_options = {}, &options_block)
      opts = optsmerge call_options, options_block

      blocks = []
      iter_blocks_in_file(opts) do |btype, headings, block_title, body|
        case btype
        when :filter
          %i[blocks line]
        when :line
          if opts[:menu_divider_match] && (mbody = body.match opts[:menu_divider_match])
            blocks += [{ name: (opts[:menu_divider_format] % mbody[:name]), disabled: '' }]
          end
        when :blocks
          blocks += get_block_summary opts, headings: headings, block_title: block_title, block_body: body
        end
      end
      blocks.tap_inspect format: :yaml
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
          "#{item[:opt_name]}: #{OptionValue.new(item[:default]).for_yaml}",
          item[:description].present? ? item[:description] : nil
        ].compact.join('      # ')
      end.compact.sort
    end

    def list_files_per_options(options)
      list_files_specified(
        specified_filename: options[:filename]&.present? ? options[:filename] : nil,
        specified_folder: options[:path],
        default_filename: 'README.md',
        default_folder: '.'
      ).tap_inspect
    end

    # :reek:LongParameterList
    def list_files_specified(specified_filename: nil, specified_folder: nil,
                             default_filename: nil, default_folder: nil, filetree: nil)
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
      blocks_in_file = list_blocks_in_file(opts.merge(struct: true))
      mdoc = MDoc.new(blocks_in_file)

      list_blocks_in_file(opts).map do |block|
        next if mdoc.hide_menu_block_per_options(opts, block)

        block
      end.compact.tap_inspect
    end

    def list_recent_output(saved_stdout_folder, saved_stdout_glob, list_count)
      Sfiles.new(saved_stdout_folder, saved_stdout_glob).most_recent_list(list_count)
    end

    def list_recent_scripts(saved_script_folder, saved_script_glob, list_count)
      Sfiles.new(saved_script_folder, saved_script_glob).most_recent_list(list_count)
    end

    def make_block_labels(call_options = {})
      opts = options.merge(call_options)
      list_blocks_in_file(opts).map do |block|
        BlockLabel.new(filename: opts[:filename],
                       headings: block.fetch(:headings, []),
                       menu_blocks_with_docname: opts[:menu_blocks_with_docname],
                       menu_blocks_with_headings: opts[:menu_blocks_with_headings],
                       title: block[:title]).make
      end.compact.tap_inspect
    end

    # :reek:DuplicateMethodCall
    # :reek:NestedIterators
    def menu_for_optparse
      menu_from_yaml.map do |menu_item|
        menu_item.merge(
          {
            opt_name: menu_item[:opt_name]&.to_sym,
            proc1: case menu_item[:proc1]
                   when 'debug'
                     lambda { |value|
                       tap_config value: value
                     }
                   when 'exit'
                     lambda { |_|
                       exit
                     }
                   when 'help'
                     lambda { |_|
                       fout menu_help
                       exit
                     }
                   when 'path'
                     lambda { |value|
                       read_configuration_file! options, value
                     }
                   when 'show_config'
                     lambda { |_|
                       options_finalize options
                       fout options.sort_by_key.to_yaml
                     }
                   when 'val_as_bool'
                     ->(value) { value.class.to_s == 'String' ? (value.chomp != '0') : value }
                   when 'val_as_int'
                     ->(value) { value.to_i }
                   when 'val_as_str'
                     ->(value) { value.to_s }
                   when 'version'
                     lambda { |_|
                       fout MarkdownExec::VERSION
                       exit
                     }
                   else
                     menu_item[:proc1]
                   end
          }
        )
      end
    end

    def menu_for_blocks(menu_options)
      options = default_options.merge menu_options
      menu = []
      iter_blocks_in_file(options) do |btype, headings, block_title, body|
        case btype
        when :filter
          %i[blocks line]
        when :line
          if options[:menu_divider_match] && (mbody = body.match options[:menu_divider_match])
            menu += [{ name: mbody[:name], disabled: '' }]
          end
        when :blocks
          summ = get_block_summary options, headings: headings, block_title: block_title, block_body: body
          menu += [summ[0][:name]]
        end
      end
      menu.tap_inspect format: :yaml
    end

    def menu_iter(data = menu_for_optparse, &block)
      data.map(&block)
    end

    def menu_help
      @option_parser.help
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

    # :reek:ControlParameter
    def optsmerge(call_options = {}, options_block = nil)
      class_call_options = @options.merge(call_options || {})
      if options_block
        options_block.call class_call_options
      else
        class_call_options
      end
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

    # :reek:UtilityFunction ### temp
    def read_configuration_file!(options, configuration_path)
      return unless File.exist?(configuration_path)

      options.merge!((YAML.load(File.open(configuration_path)) || {})
        .transform_keys(&:to_sym))
    end

    # :reek:NestedIterators
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

    def saved_name_split(name)
      mf = name.match(/#{@options[:saved_script_filename_prefix]}_(?<time>[0-9\-]+)_(?<file>.+)_,_(?<block>.+)\.sh/)
      return unless mf

      @options[:block_name] = mf[:block].tap_inspect name: :options_block_name
      @options[:filename] = mf[:file].gsub(FNR12, FNR11).tap_inspect name: :options_filename
    end

    def run_last_script
      filename = Sfiles.new(@options[:saved_script_folder],
                            @options[:saved_script_glob]).most_recent
      return unless filename

      saved_name_split filename
      @options[:save_executed_script] = false
      select_and_approve_block
    end

    def save_execution_output
      @options.tap_inspect name: :options
      return unless @options[:save_execution_output]

      @options[:logged_stdout_filename] =
        SavedAsset.new(blockname: @options[:block_name],
                       filename: File.basename(@options[:filename], '.*'),
                       prefix: @options[:logged_stdout_filename_prefix],
                       time: Time.now.utc).stdout_name

      @options[:logged_stdout_filespec] = File.join @options[:saved_stdout_folder], @options[:logged_stdout_filename]
      @logged_stdout_filespec = @options[:logged_stdout_filespec]
      (dirname = File.dirname(@options[:logged_stdout_filespec])).tap_inspect name: :dirname
      Dir.mkdir dirname unless File.exist?(dirname)

      ol = ["-STDOUT-\n"]
      ol += @execute_files&.fetch(EF_STDOUT, [])
      ol += ["\n-STDERR-\n"]
      ol += @execute_files&.fetch(EF_STDERR, [])
      ol += ["\n-STDIN-\n"]
      ol += @execute_files&.fetch(EF_STDIN, [])
      ol += ["\n"]
      File.write(@options[:logged_stdout_filespec], ol.join)
    end

    def select_and_approve_block(call_options = {}, &options_block)
      opts = optsmerge call_options, options_block
      blocks_in_file = list_blocks_in_file(opts.merge(struct: true)).tap_inspect name: :blocks_in_file
      mdoc = MDoc.new(blocks_in_file) { |nopts| opts.merge!(nopts).tap_inspect name: :infiled_opts, format: :yaml }
      blocks_menu = mdoc.blocks_for_menu(opts.merge(struct: true)).tap_inspect name: :blocks_menu

      repeat_menu = true && !opts[:block_name].present?
      loop do
        unless opts[:block_name].present?
          pt = (opts[:prompt_select_block]).to_s

          blocks_menu.each do |block|
            next if block.fetch(:disabled, false)

            block.merge! label:
            BlockLabel.new(filename: opts[:filename],
                           headings: block.fetch(:headings, []),
                           menu_blocks_with_docname: opts[:menu_blocks_with_docname],
                           menu_blocks_with_headings: opts[:menu_blocks_with_headings],
                           title: block[:title]).make
          end
          return nil if blocks_menu.count.zero?

          sel = prompt_with_quit pt, blocks_menu, per_page: opts[:select_page_height]
          return nil if sel.nil?

          label_block = blocks_in_file.select { |block| block[:label] == sel }.fetch(0, nil)
          opts[:block_name] = @options[:block_name] = label_block[:name]
        end
        approve_block opts, mdoc
        break unless repeat_menu

        opts[:block_name] = ''
      end
    end

    def select_md_file(files = list_markdown_files_in_path)
      opts = options
      if (count = files.count) == 1
        files[0]
      elsif count >= 2
        prompt_with_quit opts[:prompt_select_md].to_s, files, per_page: opts[:select_page_height]
      end
    end

    def select_recent_output
      filename = prompt_with_quit(
        @options[:prompt_select_output].to_s,
        list_recent_output(
          @options[:saved_stdout_folder],
          @options[:saved_stdout_glob],
          @options[:list_count]
        ),
        { per_page: @options[:select_page_height] }
      )
      return unless filename.present?

      `open #{filename} #{options[:output_viewer_options]}`
    end

    def select_recent_script
      filename = prompt_with_quit(
        @options[:prompt_select_md].to_s,
        list_recent_scripts(
          @options[:saved_script_folder],
          @options[:saved_script_glob],
          @options[:list_count]
        ),
        { per_page: @options[:select_page_height] }
      )
      return if filename.nil?

      saved_name_split(filename)

      select_and_approve_block({
                                 bash: true,
                                 save_executed_script: false,
                                 struct: true
                               })
    end

    def summarize_block(headings, title)
      { headings: headings, name: title, title: title }
    end

    def menu_export(data = menu_for_optparse)
      data.map do |item|
        item.delete(:proc1)
        item
      end.to_yaml
    end

    def tab_completions(data = menu_for_optparse)
      data.map do |item|
        "--#{item[:long_name]}" if item[:long_name]
      end.compact
    end

    # :reek:BooleanParameter
    # :reek:ControlParameter
    def update_options(opts = {}, over: true)
      if over
        @options = @options.merge opts
      else
        @options.merge! opts
      end
      @options.tap_inspect format: :yaml
    end

    def write_command_file(call_options, required_blocks)
      return unless call_options[:save_executed_script]

      time_now = Time.now.utc
      opts = optsmerge call_options
      opts[:saved_script_filename] =
        SavedAsset.new(blockname: opts[:block_name],
                       filename: opts[:filename],
                       prefix: opts[:saved_script_filename_prefix],
                       time: time_now).script_name

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
                                            "# time: #{time_now}\n" \
                                            "#{required_blocks.flatten.join("\n")}\n")
      return if @options[:saved_script_chmod].zero?

      File.chmod @options[:saved_script_chmod], @options[:saved_filespec]
    end
  end # class MarkParse
end # module MarkdownExec
