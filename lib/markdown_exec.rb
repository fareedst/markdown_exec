#!/usr/bin/env ruby
# frozen_string_literal: true

# encoding=utf-8

require 'English'
require 'clipboard'
require 'fileutils'
require 'open3'
require 'optparse'
require 'shellwords'
require 'tty-prompt'
require 'yaml'

require_relative 'cached_nested_file_reader'
require_relative 'cli'
require_relative 'colorize'
require_relative 'env'
require_relative 'shared'
require_relative 'tap'
require_relative 'markdown_exec/version'

include CLI
include Tap

tap_config envvar: MarkdownExec::TAP_DEBUG

$stderr.sync = true
$stdout.sync = true

BLOCK_SIZE = 1024

# custom error: file specified is missing
#
class FileMissingError < StandardError; end

# hash with keys sorted by name
# add Hash.sym_keys
#
class Hash
  unless defined?(sort_by_key)
    def sort_by_key
      keys.sort.to_h { |key| [key, self[key]] }
    end
  end

  unless defined?(sym_keys)
    def sym_keys
      transform_keys(&:to_sym)
    end
  end
end

# stdout manager
#
module FOUT
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

  def approved_fout?(level)
    level <= @options[:display_level]
  end

  # display output at level or lower than filter (DISPLAY_LEVEL_DEFAULT)
  #
  def lout(str, level: DISPLAY_LEVEL_BASE)
    return unless approved_fout? level

    fout level == DISPLAY_LEVEL_BASE ? str : @options[:display_level_xbase_prefix] + str
  end
end

def dp(str)
  lout " => #{str}", level: DISPLAY_LEVEL_DEBUG
end

public

# :reek:UtilityFunction
def list_recent_output(saved_stdout_folder, saved_stdout_glob, list_count)
  Sfiles.new(saved_stdout_folder,
             saved_stdout_glob).most_recent_list(list_count)
end

# :reek:UtilityFunction
def list_recent_scripts(saved_script_folder, saved_script_glob, list_count)
  Sfiles.new(saved_script_folder,
             saved_script_glob).most_recent_list(list_count)
end

# convert regex match groups to a hash with symbol keys
#
# :reek:UtilityFunction
def option_match_groups(str, option)
  str.match(Regexp.new(option))&.named_captures&.sym_keys
end

# execute markdown documents
#
module MarkdownExec
  # :reek:IrresponsibleModule
  class Error < StandardError; end

  # fenced code block
  #
  class FCB
    def initialize(options = {})
      @attrs = {
        body: nil,
        call: nil,
        headings: [],
        name: nil,
        reqs: [],
        shell: '',
        title: '',
        random: Random.new.rand,
        text: nil # displayable in menu
      }.merge options
    end

    def to_h
      @attrs
    end

    def to_yaml
      @attrs.to_yaml
    end

    private

    # :reek:ManualDispatch
    def method_missing(method, *args, &block)
      method_name = method.to_s

      if @attrs.respond_to?(method_name)
        @attrs.send(method_name, *args, &block)
      elsif method_name[-1] == '='
        @attrs[method_name.chop.to_sym] = args[0]
      else
        @attrs[method_name.to_sym]
      end
    rescue StandardError => err
      warn(error = "ERROR ** FCB.method_missing(method: #{method_name}," \
                   " *args: #{args.inspect}, &block)")
      warn err.inspect
      warn(caller[0..4])
      raise StandardError, error
    end

    # option names are available as methods
    #
    def respond_to_missing?(_method_name, _include_private = false)
      true # recognize all hash methods, rest are treated as hash keys
    end
  end

  # select fcb per options
  #
  # :reek:UtilityFunction
  class Filter
    #     def self.fcb_title_parse(opts, fcb_title)
    #       fcb_title.match(Regexp.new(opts[:fenced_start_ex_match])).named_captures.sym_keys
    #     end

    def self.fcb_select?(options, fcb)
      # options.tap_yaml 'options'
      # fcb.tap_inspect 'fcb'
      name = fcb.fetch(:name, '').tap_inspect 'name'
      shell = fcb.fetch(:shell, '').tap_inspect 'shell'

      ## include hidden blocks for later use
      #
      name_default = true
      name_exclude = nil
      name_select = nil
      shell_default = true
      shell_exclude = nil
      shell_select = nil
      hidden_name = nil

      if name.present? && options[:block_name]
        if name =~ /#{options[:block_name]}/
          '=~ block_name'.tap_puts
          name_select = true
          name_exclude = false
        else
          '!~ block_name'.tap_puts
          name_exclude = true
          name_select = false
        end
      end

      if name.present? && name_select.nil? && options[:select_by_name_regex].present?
        '+select_by_name_regex'.tap_puts
        name_select = (!!(name =~ /#{options[:select_by_name_regex]}/)).tap_inspect 'name_select'
      end

      if shell.present? && options[:select_by_shell_regex].present?
        '+select_by_shell_regex'.tap_puts
        shell_select = (!!(shell =~ /#{options[:select_by_shell_regex]}/)).tap_inspect 'shell_select'
      end

      if name.present? && name_exclude.nil? && options[:exclude_by_name_regex].present?
        '-exclude_by_name_regex'.tap_puts
        name_exclude = (!!(name =~ /#{options[:exclude_by_name_regex]}/)).tap_inspect 'name_exclude'
      end

      if shell.present? && options[:exclude_by_shell_regex].present?
        '-exclude_by_shell_regex'.tap_puts
        shell_exclude = (!!(shell =~ /#{options[:exclude_by_shell_regex]}/)).tap_inspect 'shell_exclude'
      end

      if name.present? && options[:hide_blocks_by_name] &&
         options[:block_name_hidden_match].present?
        '+block_name_hidden_match'.tap_puts
        hidden_name = (!!(name =~ /#{options[:block_name_hidden_match]}/)).tap_inspect 'hidden_name'
      end

      if shell.present? && options[:hide_blocks_by_shell] &&
         options[:block_shell_hidden_match].present?
        '-hide_blocks_by_shell'.tap_puts
        (!!(shell =~ /#{options[:block_shell_hidden_match]}/)).tap_inspect 'hidden_shell'
      end

      if options[:bash_only]
        '-bash_only'.tap_puts
        shell_default = (shell == 'bash').tap_inspect 'shell_default'
      end

      ## name matching does not filter hidden blocks
      #
      case
      when options[:no_chrome] && fcb.fetch(:chrome, false)
        '-no_chrome'.tap_puts
        false
      when options[:exclude_expect_blocks] && shell == 'expect'
        '-exclude_expect_blocks'.tap_puts
        false
      when hidden_name == true
        true
      when name_exclude == true, shell_exclude == true,
           name_select == false, shell_select == false
        false
      when name_select == true, shell_select == true
        true
      when name_default == false, shell_default == false
        false
      else
        true
      end.tap_inspect
    rescue StandardError => err
      warn("ERROR ** Filter::fcb_select?(); #{err.inspect}")
      raise err
    end
  end # class Filter

  ## an imported markdown document
  #
  class MDoc
    attr_reader :table

    # convert block name to fcb_parse
    #
    def initialize(table)
      @table = table
    end

    def collect_recursively_required_code(name)
      get_required_blocks(name)
        .map do |fcb|
        body = fcb[:body].join("\n")

        if fcb[:cann]
          xcall = fcb[:cann][1..-2]
          mstdin = xcall.match(/<(?<type>\$)?(?<name>[A-Za-z_\-.\w]+)/)
          mstdout = xcall.match(/>(?<type>\$)?(?<name>[A-Za-z_\-.\w]+)/)

          yqcmd = if mstdin[:type]
                    "echo \"$#{mstdin[:name]}\" | yq '#{body}'"
                  else
                    "yq e '#{body}' '#{mstdin[:name]}'"
                  end
          if mstdout[:type]
            "export #{mstdout[:name]}=$(#{yqcmd})"
          else
            "#{yqcmd} > '#{mstdout[:name]}'"
          end
        elsif fcb[:stdout]
          stdout = fcb[:stdout]
          body = fcb[:body].join("\n")
          if stdout[:type]
            %(export #{stdout[:name]}=$(cat <<"EOF"\n#{body}\nEOF\n))
          else
            "cat > '#{stdout[:name]}' <<\"EOF\"\n" \
              "#{body}\n" \
              "EOF\n"
          end
        else
          fcb[:body]
        end
      end.flatten(1)
    end

    def get_block_by_name(name, default = {})
      @table.select { |fcb| fcb.fetch(:name, '') == name }.fetch(0, default)
    end

    def get_required_blocks(name)
      name_block = get_block_by_name(name)
      raise "Named code block `#{name}` not found." if name_block.nil? || name_block.keys.empty?

      all = [name_block.fetch(:name, '')] + recursively_required(name_block[:reqs])

      # in order of appearance in document
      # insert function blocks
      @table.select { |fcb| all.include? fcb.fetch(:name, '') }
            .map do |fcb|
        if (call = fcb[:call])
          [get_block_by_name("[#{call.match(/^%\((\S+) |\)/)[1]}]")
            .merge({ cann: call })]
        else
          []
        end + [fcb]
      end.flatten(1)
    end

    # :reek:UtilityFunction
    def hide_menu_block_per_options(opts, block)
      (opts[:hide_blocks_by_name] &&
              block[:name]&.match(Regexp.new(opts[:block_name_hidden_match])) &&
              (block[:name]&.present? || block[:label]&.present?)
      ).tap_inspect
    end

    # def blocks_for_menu(opts)
    #   if opts[:hide_blocks_by_name]
    #     @table.reject { |block| hide_menu_block_per_options opts, block }
    #   else
    #     @table
    #   end
    # end

    def fcbs_per_options(opts = {})
      options = opts.merge(block_name_hidden_match: nil)
      selrows = @table.select do |fcb_title_groups|
        Filter.fcb_select? options, fcb_title_groups
      end

      ### hide rows correctly

      if opts[:hide_blocks_by_name]
        selrows.reject { |block| hide_menu_block_per_options opts, block }
      else
        selrows
      end.map do |block|
        # block[:name] = block[:text] if block[:name].nil?
        block
      end
    end

    def recursively_required(reqs)
      return [] unless reqs

      rem = reqs
      memo = []
      while rem.count.positive?
        rem = rem.map do |req|
          next if memo.include? req

          memo += [req]
          get_block_by_name(req).fetch(:reqs, [])
        end
                 .compact
                 .flatten(1)
      end
      memo
    end
  end # class MDoc

  # format option defaults and values
  #
  # :reek:TooManyInstanceVariables
  class BlockLabel
    def initialize(filename:, headings:, menu_blocks_with_docname:,
                   menu_blocks_with_headings:, title:, body:, text:)
      @filename = filename
      @headings = headings
      @menu_blocks_with_docname = menu_blocks_with_docname
      @menu_blocks_with_headings = menu_blocks_with_headings
      # @title = title.present? ? title : body
      @title = title
      @body = body
      @text = text
    rescue StandardError => err
      warn(error = "ERROR ** BlockLabel.initialize(); #{err.inspect}")
      binding.pry if $tap_enable
      raise ArgumentError, error
    end

    # join title, headings, filename
    #
    def make
      label = @title
      label = @body unless label.present?
      label = @text unless label.present?
      label.tap_inspect
      ([label] +
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
    rescue StandardError => err
      warn(error = "ERROR ** BlockLabel.make(); #{err.inspect}")
      binding.pry if $tap_enable
      raise ArgumentError, error
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
      "#{[@prefix, @time.strftime('%F-%H-%M-%S'), fne, ',',
          @blockname].join('_')}.sh"
    end

    def stdout_name
      "#{[@prefix, @time.strftime('%F-%H-%M-%S'), @filename,
          @blockname].join('_')}.out.txt"
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
      Dir.glob(File.join(@folder, @glob))
    end

    def most_recent(arr = nil)
      arr = list_all if arr.nil?
      return if arr.count < 1

      arr.max
    end

    def most_recent_list(list_count, arr = nil)
      arr = list_all if arr.nil?
      return if (ac = arr.count) < 1

      arr.sort[-[ac, list_count].min..].reverse
    end
  end # class Sfiles

  ##
  #
  # rubocop:disable Layout/LineLength
  # :reek:DuplicateMethodCall { allow_calls: ['block', 'item', 'lm', 'opts', 'option', '@options', 'required_blocks'] }
  # rubocop:enable Layout/LineLength
  # :reek:MissingSafeMethod { exclude: [ read_configuration_file! ] }
  # :reek:TooManyInstanceVariables ### temp
  # :reek:TooManyMethods ### temp
  class MarkParse
    attr_reader :options

    include FOUT

    def initialize(options = {})
      @options = options
      # hide disabled symbol
      @prompt = TTY::Prompt.new(interrupt: :exit, symbols: { cross: ' ' })
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

    # return arguments before `--`
    #
    def arguments_for_mde(argv = ARGV)
      case ind = argv.find_index('--')
      when nil
        argv
      when 0
        []
      else
        argv[0..ind - 1]
      end #.tap_inspect
    end

    # return arguments after `--`
    #
    def arguments_for_child(argv = ARGV)
      case ind = argv.find_index('--')
      when nil, argv.count - 1
        []
      else
        argv[ind + 1..-1]
      end #.tap_inspect
    end

    ##
    # options necessary to start, parse input, defaults for cli options
    #
    def base_options
      menu_iter do |item|
        # noisy item.tap_yaml name: :item
        next unless item[:opt_name].present?

        item_default = item[:default]
        # noisy item_default.tap_inspect name: :item_default
        value = if item_default.nil?
                  item_default
                else
                  env_str(item[:env_var],
                          default: OptionValue.new(item_default).for_hash)
                end
        [item[:opt_name], item[:proccode] ? item[:proccode].call(value) : value]
      end.compact.to_h
    end

    def calculated_options
      {
        bash: true, # bash block parsing in get_block_summary()
        saved_script_filename: nil, # calculated
        struct: true # allow get_block_summary()
      }
    end

    def approve_and_execute_block(opts, mdoc)
      required_blocks = mdoc.collect_recursively_required_code(opts[:block_name])
      if opts[:output_script] || opts[:user_must_approve]
        display_required_code(opts,
                              required_blocks)
      end

      allow = true
      if opts[:user_must_approve]
        loop do
          (sel = @prompt.select(opts[:prompt_approve_block],
                                filter: true) do |menu|
             menu.default 1
             menu.choice opts[:prompt_yes], 1
             menu.choice opts[:prompt_no], 2
             menu.choice opts[:prompt_script_to_clipboard], 3
             menu.choice opts[:prompt_save_script], 4
           end)
          allow = (sel == 1)
          if sel == 3
            text = required_blocks.flatten.join($INPUT_RECORD_SEPARATOR)
            Clipboard.copy(text)
            fout "Clipboard updated: #{required_blocks.count} blocks," /
                 " #{required_blocks.flatten.count} lines," /
                 " #{text.length} characters"
          end
          if sel == 4
            write_command_file(opts.merge(save_executed_script: true),
                               required_blocks)
            fout "File saved: #{@options[:saved_filespec]}"
          end
          break if [1, 2].include? sel
        end
      end
      (opts[:ir_approve] = allow)

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

    def cfile
      @cfile ||= CachedNestedFileReader.new(import_pattern: @options.fetch(:import_pattern))
    end

    # :reek:DuplicateMethodCall
    # :reek:UncommunicativeVariableName { exclude: [ e ] }
    # :reek:LongYieldList
    def command_execute(opts, command)
      #d 'execute command and yield outputs'
      @execute_files = Hash.new([])
      @execute_options = opts
      @execute_started_at = Time.now.utc

      args = []
      Open3.popen3(@options[:shell], '-c',
                   command, ARGV[0], *args) do |stdin, stdout, stderr, exec_thr|
        #d 'command started'
        Thread.new do
          until (line = stdout.gets).nil?
            @execute_files[EF_STDOUT] = @execute_files[EF_STDOUT] + [line]
            print line if opts[:output_stdout]
            yield nil, line, nil, exec_thr if block_given?
          end
        rescue IOError
          #d 'stdout IOError, thread killed, do nothing'
        end

        Thread.new do
          until (line = stderr.gets).nil?
            @execute_files[EF_STDERR] = @execute_files[EF_STDERR] + [line]
            print line if opts[:output_stdout]
            yield nil, nil, line, exec_thr if block_given?
          end
        rescue IOError
          #d 'stderr IOError, thread killed, do nothing'
        end

        in_thr = Thread.new do
          while exec_thr.alive? # reading input until the child process ends
            stdin.puts(line = $stdin.gets)
            @execute_files[EF_STDIN] = @execute_files[EF_STDIN] + [line]
            yield line, nil, nil, exec_thr if block_given?
          end
          #d 'exec_thr now dead'
        rescue StandardError
          #d 'stdin error, thread killed, do nothing'
        end

        #d 'join exec_thr'
        exec_thr.join

        #d 'wait before closing stdin'
        sleep 0.1

        #d 'kill stdin thread'
        in_thr.kill
        # @return_code = exec_thr.value
        #d 'command end'
      end
      #d 'command completed'
      @execute_completed_at = Time.now.utc
    rescue Errno::ENOENT => err
      #d 'command error ENOENT triggered by missing command in script'
      @execute_aborted_at = Time.now.utc
      @execute_error_message = err.message
      @execute_error = err
      @execute_files[EF_STDERR] += [@execute_error_message]
      fout "Error ENOENT: #{err.inspect}"
    rescue SignalException => err
      #d 'command SIGTERM triggered by user or system'
      @execute_aborted_at = Time.now.utc
      @execute_error_message = 'SIGTERM'
      @execute_error = err
      @execute_files[EF_STDERR] += [@execute_error_message]
      fout "Error ENOENT: #{err.inspect}"
    end

    def count_blocks_in_filename
      fenced_start_and_end_match = Regexp.new @options[:fenced_start_and_end_match]
      cnt = 0
      cfile.readlines(@options[:filename]).each do |line|
        cnt += 1 if line.match(fenced_start_and_end_match)
      end
      cnt / 2
    end

    # :reek:DuplicateMethodCall
    def display_required_code(opts, required_blocks)
      frame = opts[:output_divider].send(opts[:output_divider_color].to_sym)
      fout frame
      required_blocks.each { |cb| fout cb }
      fout frame
    end

    # :reek:DuplicateMethodCall
    def exec_block(options, _block_name = '')
      options = calculated_options.merge(options).tap_yaml 'options'
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
                              fout_list list_recent_output(
                                @options[:saved_stdout_folder],
                                @options[:saved_stdout_glob], @options[:list_count]
                              )
                            },
        list_recent_scripts: lambda {
                               fout_list list_recent_scripts(
                                 options[:saved_script_folder],
                                 options[:saved_script_glob], options[:list_count]
                               )
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
      select_approve_and_execute_block({
                                         bash: true,
                                         struct: true
                                       })
      return unless @options[:output_saved_script_filename]

      fout "saved_filespec: #{@execute_script_filespec}"
    rescue StandardError => err
      warn(error = "ERROR ** MarkParse.exec_block(); #{err.inspect}")
      binding.pry if $tap_enable
      raise ArgumentError, error
    end

    ## summarize blocks
    #
    def get_block_summary(call_options, fcb)
      opts = optsmerge call_options
      # return fcb.body unless opts[:struct]

      return fcb unless opts[:bash]

      fcb.call = fcb.title.match(Regexp.new(opts[:block_calls_scan]))&.fetch(1, nil)
      titlexcall = if fcb.call
                     fcb.title.sub("%#{fcb.call}", '')
                   else
                     fcb.title
                   end
      bm = option_match_groups(titlexcall, opts[:block_name_match])
      fcb.stdin = option_match_groups(titlexcall, opts[:block_stdin_scan])
      fcb.stdout = option_match_groups(titlexcall, opts[:block_stdout_scan])
      fcb.title = fcb.name = (bm && bm[1] ? bm[:title] : titlexcall)
      fcb
    end

    # :reek:DuplicateMethodCall
    # :reek:LongYieldList
    # :reek:NestedIterators
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
      fcb = FCB.new
      in_block = false
      headings = []

      ## get type of messages to select
      #
      selected_messages = yield :filter

      cfile.readlines(opts[:filename]).each.with_index do |line, _line_num|
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
            # end fcb
            #
            fcb.name = fcb.title || ''
            if fcb.body
              if fcb.title.nil? || fcb.title.empty?
                fcb.title = fcb.body.join(' ').gsub(/  +/, ' ')[0..64]
              end

              if block_given? && selected_messages.include?(:blocks) &&
                 Filter.fcb_select?(opts, fcb)
                yield :blocks, fcb
              end
            end
            in_block = false
          else
            # start fcb
            #
            in_block = true

            fcb_title_groups = line.match(fenced_start_ex).named_captures.sym_keys
            fcb = FCB.new
            fcb.headings = headings
            fcb.name = fcb_title_groups.fetch(:name, '')
            fcb.shell = fcb_title_groups.fetch(:shell, '')
            fcb.title = fcb_title_groups.fetch(:name, '')

            # selected fcb
            #
            fcb.body = []

            rest = fcb_title_groups.fetch(:rest, '')
            fcb.reqs = rest.scan(/\+[^\s]+/).map { |req| req[1..-1] }

            fcb.call = rest.match(Regexp.new(opts[:block_calls_scan]))&.to_a&.first
            fcb.stdin = if (tn = rest.match(/<(?<type>\$)?(?<name>[A-Za-z_-]\S+)/))
                          tn.named_captures.sym_keys
                        end
            fcb.stdout = if (tn = rest.match(/>(?<type>\$)?(?<name>[A-Za-z_\-.\w]+)/))
                           tn.named_captures.sym_keys
                         end
          end
        elsif in_block && fcb.body
          dp 'append line to fcb body'
          fcb.body += [line.chomp]
        elsif block_given? && selected_messages.include?(:line)
          dp 'text outside of fcb'
          fcb = FCB.new
          fcb.body = [line]
          yield :line, fcb
        end
      end
    end

    # return body, title if option.struct
    # return body if not struct
    #
    def list_blocks_in_file(call_options = {}, &options_block)
      opts = optsmerge(call_options, options_block) #.tap_yaml 'opts'
      blocks = []
      if opts[:menu_initial_divider].present?
        blocks.push FCB.new({
                              # name: '',
                              chrome: true,
                              name: format(
                                opts[:menu_divider_format],
                                opts[:menu_initial_divider]
                              ).send(opts[:menu_divider_color].to_sym),
                              disabled: '' # __LINE__.to_s
                            })
      end

      iter_blocks_in_file(opts) do |btype, fcb|
        case btype
        when :filter
          ## return type of blocks to select
          #
          %i[blocks line]

        when :line
          ## convert line to block
          #
          if opts[:menu_divider_match].present? &&
             (mbody = fcb.body[0].match opts[:menu_divider_match])
            blocks.push FCB.new(
              { chrome: true,
                disabled: '',
                name: format(opts[:menu_divider_format],
                             mbody[:name]).send(opts[:menu_divider_color].to_sym) }
            )
          elsif opts[:menu_task_match].present? &&
                (mbody = fcb.body[0].match opts[:menu_task_match])
            blocks.push FCB.new(
              { chrome: true,
                disabled: '',
                name: format(opts[:menu_task_format],
                             mbody[:name]).send(opts[:menu_task_color].to_sym) }
            )
          else
            # line not added
          end
        when :blocks
          ## enhance fcb with block summary
          #
          blocks.push get_block_summary(opts, fcb) ### if Filter.fcb_select? opts, fcb
        end
      end

      if opts[:menu_divider_format].present? && opts[:menu_final_divider].present?
        blocks.push FCB.new(
          { chrome: true,
            disabled: '',
            name: format(opts[:menu_divider_format],
                         opts[:menu_final_divider])
                                 .send(opts[:menu_divider_color].to_sym) }
        )
      end
      blocks.tap_inspect
    rescue StandardError => err
      warn(error = "ERROR ** MarkParse.list_blocks_in_file(); #{err.inspect}")
      warn(caller[0..4])
      raise StandardError, error
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
      )
    end

    # :reek:LongParameterList
    def list_files_specified(specified_filename: nil, specified_folder: nil,
                             default_filename: nil, default_folder: nil, filetree: nil)
      fn = File.join(if specified_filename&.present?
                       if specified_filename.start_with? '/'
                         [specified_filename]
                       elsif specified_folder&.present?
                         [specified_folder, specified_filename]
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
        filetree.select do |filename|
          filename == fn || filename.match(/^#{fn}$/) || filename.match(%r{^#{fn}/.+$})
        end
      else
        Dir.glob(fn)
      end
    end

    def list_markdown_files_in_path
      Dir.glob(File.join(@options[:path],
                         @options[:md_filename_glob]))
    end

    def blocks_per_opts(blocks, opts)
      if opts[:struct]
        blocks
      else
        # blocks.map(&:name)
        blocks.map do |block|
          block.fetch(:text, nil) || block.fetch(:name, nil)
        end
      end.compact.reject(&:empty?).tap_inspect
    end

    ## output type (body string or full object) per option struct and bash
    #
    def list_named_blocks_in_file(call_options = {}, &options_block)
      opts = optsmerge call_options, options_block

      blocks = list_blocks_in_file(opts.merge(struct: true)).select do |fcb|
        # fcb.fetch(:name, '') != '' && Filter.fcb_select?(opts, fcb)
        Filter.fcb_select?(opts.merge(no_chrome: true), fcb)
      end
      blocks_per_opts(blocks, opts).tap_inspect
    end

    def make_block_labels(call_options = {})
      opts = options.merge(call_options)
      list_blocks_in_file(opts).map do |fcb|
        BlockLabel.new(filename: opts[:filename],
                       headings: fcb.fetch(:headings, []),
                       menu_blocks_with_docname: opts[:menu_blocks_with_docname],
                       menu_blocks_with_headings: opts[:menu_blocks_with_headings],
                       title: fcb[:title],
                       text: fcb[:text],
                       body: fcb[:body]).make
      end.compact
    end

    # :reek:DuplicateMethodCall
    # :reek:NestedIterators
    def menu_for_optparse
      menu_from_yaml.map do |menu_item|
        menu_item.merge(
          {
            opt_name: menu_item[:opt_name]&.to_sym,
            proccode: case menu_item[:procname]
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
                        lambda { |value|
                          value.instance_of?(::String) ? (value.chomp != '0') : value
                        }
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
                        menu_item[:procname]
                      end
          }
        )
      end
    end

    def menu_for_blocks(menu_options)
      options = calculated_options.merge menu_options
      menu = []
      iter_blocks_in_file(options) do |btype, fcb|
        case btype
        when :filter
          %i[blocks line]
        when :line
          if options[:menu_divider_match] &&
             (mbody = fcb.body[0].match(options[:menu_divider_match]))
            menu.push FCB.new({ name: mbody[:name], disabled: '' })
          end
        when :blocks
          menu += [fcb.name]
        end
      end
      menu
    end

    def menu_iter(data = menu_for_optparse, &block)
      data.map(&block)
    end

    def menu_help
      @option_parser.help
    end

    def menu_option_append(opts, options, item)
      return unless item[:long_name].present? || item[:short_name].present?

      opts.on(*[
        # - long name
        if item[:long_name].present?
          "--#{item[:long_name]}#{item[:arg_name].present? ? " #{item[:arg_name]}" : ''}"
        end,

        # - short name
        item[:short_name].present? ? "-#{item[:short_name]}" : nil,

        # - description and default
        [item[:description],
         ("[#{value_for_cli item[:default]}]" if item[:default].present?)].compact.join('  '),

        # apply proccode, if present, to value
        # save value to options hash if option is named
        #
        lambda { |value|
          (item[:proccode] ? item[:proccode].call(value) : value).tap do |converted|
            options[item[:opt_name]] = converted if item[:opt_name]
          end
        }
      ].compact)
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
          raise FileMissingError, pos, caller
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

    ## insert exit option at head or tail
    #
    def prompt_menu_add_exit(_prompt_text, items, exit_option, _opts = {})
      if @options[:menu_exit_at_top]
        (@options[:menu_with_exit] ? [exit_option] : []) + items
      else
        items + (@options[:menu_with_exit] ? [exit_option] : [])
      end
    end

    ## tty prompt to select
    # insert exit option at head or tail
    # return selected option or nil
    #
    def prompt_with_quit(prompt_text, items, opts = {})
      exit_option = '* Exit'
      sel = @prompt.select(prompt_text, prompt_menu_add_exit(prompt_text, items, exit_option, opts),
                           opts.merge(filter: true))
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
      read_configuration_file! @options,
                               ".#{MarkdownExec::APP_NAME.downcase}.yml"

      @option_parser = option_parser = OptionParser.new do |opts|
        executable_name = File.basename($PROGRAM_NAME)
        opts.banner = [
          "#{MarkdownExec::APP_NAME}" \
          " - #{MarkdownExec::APP_DESC} (#{MarkdownExec::VERSION})",
          "Usage: #{executable_name} [(path | filename [block_name])] [options]"
        ].join("\n")

        menu_iter do |item|
          menu_option_append opts, options, item
        end
      end
      option_parser.load # filename defaults to basename of the program
      # without suffix in a directory ~/.options
      option_parser.environment # env defaults to the basename of the program
      # child_argv = arguments_for_child
      rest = option_parser.parse!(arguments_for_mde) # (into: options)

      begin
        options_finalize rest
        exec_block options, options[:block_name]
      rescue FileMissingError => err
        puts "File missing: #{err}"
      end
    rescue StandardError => err
      warn(error = "ERROR ** MarkParse.run(); #{err.inspect}")
      binding.pry if $tap_enable
      raise ArgumentError, error
    end

    def saved_name_split(name)
      # rubocop:disable Layout/LineLength
      mf = /#{@options[:saved_script_filename_prefix]}_(?<time>[0-9\-]+)_(?<file>.+)_,_(?<block>.+)\.sh/.match name
      # rubocop:enable Layout/LineLength
      return unless mf

      @options[:block_name] = mf[:block]
      @options[:filename] = mf[:file].gsub(FNR12, FNR11)
    end

    def run_last_script
      filename = Sfiles.new(@options[:saved_script_folder],
                            @options[:saved_script_glob]).most_recent
      return unless filename

      saved_name_split filename
      @options[:save_executed_script] = false
      select_approve_and_execute_block({})
    end

    def save_execution_output
      return unless @options[:save_execution_output]

      @options[:logged_stdout_filename] =
        SavedAsset.new(blockname: @options[:block_name],
                       filename: File.basename(@options[:filename], '.*'),
                       prefix: @options[:logged_stdout_filename_prefix],
                       time: Time.now.utc).stdout_name

      @options[:logged_stdout_filespec] =
        File.join @options[:saved_stdout_folder],
                  @options[:logged_stdout_filename]
      @logged_stdout_filespec = @options[:logged_stdout_filespec]
      (dirname = File.dirname(@options[:logged_stdout_filespec]))
      FileUtils.mkdir_p dirname

      ol = ["-STDOUT-\n"]
      ol += @execute_files&.fetch(EF_STDOUT, [])
      ol += ["\n-STDERR-\n"]
      ol += @execute_files&.fetch(EF_STDERR, [])
      ol += ["\n-STDIN-\n"]
      ol += @execute_files&.fetch(EF_STDIN, [])
      ol += ["\n"]
      File.write(@options[:logged_stdout_filespec], ol.join)
    end

    def select_approve_and_execute_block(call_options, &options_block)
      opts = optsmerge call_options, options_block
      blocks_in_file = list_blocks_in_file(opts.merge(struct: true)).tap_inspect
      mdoc = MDoc.new(blocks_in_file) do |nopts|
        opts.merge!(nopts)
      end
      blocks_menu = mdoc.fcbs_per_options(opts.merge(struct: true))

      repeat_menu = true && !opts[:block_name].present?
      loop do
        unless opts[:block_name].present?
          pt = (opts[:prompt_select_block]).to_s

          bm = blocks_menu.map do |fcb|
            # next if fcb.fetch(:disabled, false)
            # next unless fcb.fetch(:name, '').present?

            fcb.merge!(
              label: BlockLabel.new(
                body: fcb[:body],
                filename: opts[:filename],
                headings: fcb.fetch(:headings, []),
                menu_blocks_with_docname: opts[:menu_blocks_with_docname],
                menu_blocks_with_headings: opts[:menu_blocks_with_headings],
                text: fcb[:text],
                title: fcb[:title]
              ).make
            )

            fcb.to_h
          end.compact
          return nil if bm.count.zero?

          sel = prompt_with_quit pt, bm,
                                 per_page: opts[:select_page_height]
          return nil if sel.nil?

          ## store selected option
          #
          label_block = blocks_in_file.select do |fcb|
            fcb[:label] == sel
          end.fetch(0, nil)
          opts[:block_name] = @options[:block_name] = label_block.fetch(:name, '')
        end
        approve_and_execute_block opts, mdoc
        break unless repeat_menu

        opts[:block_name] = ''
      end
    rescue StandardError => err
      warn(error = "ERROR ** MarkParse.select_approve_and_execute_block(); #{err.inspect}")
      binding.pry if $tap_enable
      raise ArgumentError, error
    end

    def select_md_file(files = list_markdown_files_in_path)
      opts = options
      if (count = files.count) == 1
        files[0]
      elsif count >= 2
        prompt_with_quit opts[:prompt_select_md].to_s, files,
                         per_page: opts[:select_page_height]
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

      select_approve_and_execute_block({
                                         bash: true,
                                         save_executed_script: false,
                                         struct: true
                                       })
    end

    def menu_export(data = menu_for_optparse)
      data.map do |item|
        item.delete(:procname)
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
      @options
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
      FileUtils.mkdir_p dirname
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
