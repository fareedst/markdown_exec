#!/usr/bin/env ruby
# frozen_string_literal: true

# encoding=utf-8

# rubocop:disable Style/GlobalVars
$pdebug = !(ENV['MARKDOWN_EXEC_DEBUG'] || '').empty?

require 'open3'
require 'optparse'
# require 'pathname'
require 'tty-prompt'
require 'yaml'
require_relative 'markdown_exec/version'

BLOCK_SIZE = 1024
SELECT_PAGE_HEIGHT = 12

module MarkdownExec
  class Error < StandardError; end

  ##
  #
  class MarkParse
    attr_accessor :options

    def initialize(options = {})
      @options = options
    end

    def count_blocks
      cnt = 0
      File.readlines(options[:mdfilename]).each do |line|
        cnt += 1 if line.match(/^```/)
      end
      cnt / 2
    end

    def find_files
      puts "pwd: #{`pwd`}" if $pdebug
      # `ls -1 *.md`.split("\n").tap { |ret| puts "find_files() ret: #{ret.inspect}" if $pdebug }
      `ls -1 #{File.join options[:mdfolder], '*.md'}`.split("\n").tap do |ret|
        puts "find_files() ret: #{ret.inspect}" if $pdebug
      end
    end

    def fout(str)
      puts str # to stdout
    end

    def copts(call_options = {}, options_block = nil)
      class_call_options = options.merge(call_options || {})
      if options_block
        options_block.call class_call_options
      else
        class_call_options
      end.tap { |ret| puts "copts() ret: #{ret.inspect}" if $pdebug }
    end

    def bsr(headings, title)
      # puts "bsr() headings: #{headings.inspect}"
      { headings: headings, name: title, title: title }
    end

    def block_summary(opts, headings, block_title, current)
      puts "block_summary() block_title: #{block_title.inspect}" if $pdebug
      return [current] unless opts[:struct]

      # return [{ body: current, name: block_title, title: block_title }] unless opts[:bash]
      return [bsr(headings, block_title).merge({ body: current })] unless opts[:bash]

      bm = block_title.match(/:(\S+)( |$)/)
      reqs = block_title.scan(/\+\S+/).map { |s| s[1..] }

      if $pdebug
        puts ["block_summary() bm: #{bm.inspect}",
              "block_summary() reqs: #{reqs.inspect}"]
      end

      if bm && bm[1]
        # [{ body: current, name: bm[1], reqs: reqs, title: bm[1] }]
        [bsr(headings, bm[1]).merge({ body: current, reqs: reqs })]
      else
        # [{ body: current, name: block_title, reqs: reqs, title: block_title }]
        [bsr(headings, block_title).merge({ body: current, reqs: reqs })]
      end
    end

    def get_blocks(call_options = {}, &options_block)
      opts = copts call_options, options_block

      blocks = []
      current = nil
      in_block = false
      block_title = ''

      headings = []
      File.readlines(opts[:mdfilename]).each do |line|
        puts "get_blocks() line: #{line.inspect}" if $pdebug
        continue unless line

        if opts[:mdheadings]
          if (lm = line.match(/^### *(.+?) *$/))
            headings = [headings[0], headings[1], lm[1]]
          elsif (lm = line.match(/^## *([^#]*?) *$/))
            headings = [headings[0], lm[1]]
          elsif (lm = line.match(/^# *([^#]*?) *$/))
            headings = [lm[1]]
          end
          puts "get_blocks() headings: #{headings.inspect}" if $pdebug
        end

        if line.match(/^`{3,}/)
          if in_block
            puts 'get_blocks() in_block' if $pdebug
            if current

              # block_title ||= current.join(' ').gsub(/  +/, ' ')[0..64]
              block_title = current.join(' ').gsub(/  +/, ' ')[0..64] if block_title.nil? || block_title.empty?

              blocks += block_summary opts, headings, block_title, current
              current = nil
            end
            in_block = false
            block_title = ''
          else
            ## new block
            #

            # lm = line.match(/^`{3,}([^`\s]+)( .+)?$/)
            lm = line.match(/^`{3,}([^`\s]*) *(.*)$/)

            do1 = false
            if opts[:bash_only]
              do1 = true if lm && (lm[1] == 'bash')
            elsif opts[:exclude_expect_blocks]
              do1 = true unless lm && (lm[1] == 'expect')
            else
              do1 = true
            end
            if $pdebug
              puts ["get_blocks() lm: #{lm.inspect}",
                    "get_blocks() opts: #{opts.inspect}",
                    "get_blocks() do1: #{do1}"]
            end

            if do1 && (!opts[:title_match] || (lm && lm[2] && lm[2].match(opts[:title_match])))
              current = []
              in_block = true
              block_title = (lm && lm[2])
            end

          end
        elsif current
          current += [line.chomp]
        end
      end
      blocks.tap { |ret| puts "get_blocks() ret: #{ret.inspect}" if $pdebug }
    end # get_blocks

    def make_block_label(block, call_options = {})
      opts = options.merge(call_options)
      puts "make_block_label() opts: #{opts.inspect}" if $pdebug
      puts "make_block_label() block: #{block.inspect}" if $pdebug
      if opts[:mdheadings]
        heads = block.fetch(:headings, []).compact.join(' # ')
        "#{block[:title]} [#{heads}] (#{opts[:mdfilename]})"
      else
        "#{block[:title]} (#{opts[:mdfilename]})"
      end
    end

    def make_block_labels(call_options = {})
      opts = options.merge(call_options)
      get_blocks(opts).map do |block|
        make_block_label block, opts
      end
    end

    def select_block(call_options = {}, &options_block)
      opts = copts call_options, options_block

      blocks = get_blocks(opts.merge(struct: true))
      puts "select_block() blocks: #{blocks.to_yaml}" if $pdebug

      prompt = TTY::Prompt.new(interrupt: :exit)
      pt = "#{opts.fetch(:prompt, nil) || 'Pick one'}:"
      puts "select_block() pt: #{pt.inspect}" if $pdebug

      blocks.each { |block| block.merge! label: make_block_label(block, opts) }
      block_labels = blocks.map { |block| block[:label] }
      puts "select_block() block_labels: #{block_labels.inspect}" if $pdebug

      if opts[:preview_options]
        select_per_page = 3
        block_labels.each do |bn|
          fout " - #{bn}"
        end
      else
        select_per_page = SELECT_PAGE_HEIGHT
      end

      return nil if block_labels.count.zero?

      sel = prompt.select(pt, block_labels, per_page: select_per_page)
      puts "select_block() sel: #{sel.inspect}" if $pdebug
      # catch
      # # catch TTY::Reader::InputInterrupt
      #   puts "InputInterrupt"
      # end

      label_block = blocks.select { |block| block[:label] == sel }.fetch(0, nil)
      puts "select_block() label_block: #{label_block.inspect}" if $pdebug
      sel = label_block[:name]
      puts "select_block() sel: #{sel.inspect}" if $pdebug

      cbs = code_blocks(blocks, sel)
      puts "select_block() cbs: #{cbs.inspect}" if $pdebug

      ## display code blocks for approval
      #
      cbs.each { |cb| fout cb } if opts[:display] || opts[:approve]

      allow = true
      allow = prompt.yes? 'Process?' if opts[:approve]

      selected = block_by_name blocks, sel
      puts "select_block() selected: #{selected.inspect}" if $pdebug
      if allow && opts[:execute]

        ## process in script, to handle line continuations
        #
        cmd2 = cbs.flatten.join("\n")
        fout "$ #{cmd2.to_yaml}"

        # Open3.popen3(cmd2) do |stdin, stdout, stderr, wait_thr|
        #   cnt += 1
        #   # stdin.puts "This is sent to the command"
        #   # stdin.close                # we're done
        #   stdout_str = stdout.read   # read stdout to string. note that this will block until the command is done!
        #   stderr_str = stderr.read   # read stderr to string
        #   status = wait_thr.value    # will block until the command finishes; returns status that responds to .success?
        #   fout "#{stdout_str}"
        #   fout "#{cnt}: err: #{stderr_str}" if stderr_str != ''
        #   # fout "#{cnt}: stt: #{status}"
        # end

        Open3.popen3(cmd2) do |stdin, stdout, stderr|
          stdin.close_write
          begin
            files = [stdout, stderr]

            until all_eof(files)
              ready = IO.select(files)

              next unless ready

              readable = ready[0]
              # writable = ready[1]
              # exceptions = ready[2]

              readable.each do |f|
                # fileno = f.fileno

                data = f.read_nonblock(BLOCK_SIZE)
                # fout "- fileno: #{fileno}\n#{data}"
                fout data
              rescue EOFError #=> e
                # fout "fileno: #{fileno} EOF"
              end
            end
          rescue IOError => e
            fout "IOError: #{e}"
          end
        end
      end

      selected[:name]
    end # select_block

    def select_md_file
      opts = options
      files = find_files
      if files.count == 1
        sel = files[0]
      elsif files.count >= 2

        if opts[:preview_options]
          select_per_page = 3
          files.each do |file|
            fout " - #{file}"
          end
        else
          select_per_page = SELECT_PAGE_HEIGHT
        end

        prompt = TTY::Prompt.new
        sel = prompt.select("#{opts.fetch(:prompt, 'Pick one')}:", files, per_page: select_per_page)
      end

      sel
    end

    # Returns true if all files are EOF
    #
    def all_eof(files)
      files.find { |f| !f.eof }.nil?
    end

    def code(table, block)
      puts "code() table: #{table.inspect}" if $pdebug
      puts "code() block: #{block.inspect}" if $pdebug
      all = [block[:name]] + unroll(table, block[:reqs])
      puts "code() all: #{all.inspect}" if $pdebug
      all.reverse.map do |req|
        puts "code() req: #{req.inspect}" if $pdebug
        block_by_name(table, req).fetch(:body, '')
      end
         .flatten(1)
         .tap { |ret| puts "code() ret: #{ret.inspect}" if $pdebug }
    end

    def block_by_name(table, name, default = {})
      table.select { |block| block[:name] == name }.fetch(0, default)
    end

    def code_blocks(table, name)
      puts "code_blocks() table: #{table.inspect}" if $pdebug
      puts "code_blocks() name: #{name.inspect}" if $pdebug
      name_block = block_by_name(table, name)
      puts "code_blocks() name_block: #{name_block.inspect}" if $pdebug
      all = [name_block[:name]] + unroll(table, name_block[:reqs])
      puts "code_blocks() all: #{all.inspect}" if $pdebug

      # in order of appearance in document
      table.select { |block| all.include? block[:name] }
           .map { |block| block.fetch(:body, '') }
           .flatten(1)
           .tap { |ret| puts "code_blocks() ret: #{ret.inspect}" if $pdebug }
    end

    def unroll(table, reqs)
      puts "unroll() table: #{table.inspect}" if $pdebug
      puts "unroll() reqs: #{reqs.inspect}" if $pdebug
      all = []
      rem = reqs
      while rem.count.positive?
        puts "unrol() rem: #{rem.inspect}" if $pdebug
        rem = rem.map do |req|
          puts "unrol() req: #{req.inspect}" if $pdebug
          next if all.include? req

          all += [req]
          puts "unrol() all: #{all.inspect}" if $pdebug
          block_by_name(table, req).fetch(:reqs, [])
        end
                 .compact
                 .flatten(1)
                 .tap { |_ret| puts "unroll() rem: #{rem.inspect}" if $pdebug }
      end
      all.tap { |ret| puts "unroll() ret: #{ret.inspect}" if $pdebug }
    end

    # $stderr.sync = true
    # $stdout.sync = true

    ## configuration file
    #
    def read_configuration!(options, configuration_path)
      if File.exist?(configuration_path)
        # rubocop:disable Security/YAMLLoad
        options.merge!((YAML.load(File.open(configuration_path)) || {})
          .transform_keys(&:to_sym))
        # rubocop:enable Security/YAMLLoad
      end
      options
    end

    def run
      ## default configuration
      #
      options = {
        mdheadings: true,
        list_blocks: false,
        list_docs: false,
        mdfilename: 'README.md',
        mdfolder: '.'
      }

      def options_finalize!(options); end

      # puts "MDE run() ARGV: #{ARGV.inspect}"

      # read local configuration file
      #
      read_configuration! options, ".#{MarkdownExec::APP_NAME.downcase}.yml"

      ## read current details for aws resources from app_data_file
      #
      # load_resources! options
      # puts "q31 options: #{options.to_yaml}" if $pdebug

      # rubocop:disable Metrics/BlockLength
      option_parser = OptionParser.new do |opts|
        executable_name = File.basename($PROGRAM_NAME)
        opts.banner = [
          "#{MarkdownExec::APP_NAME} - #{MarkdownExec::APP_DESC} (#{MarkdownExec::VERSION})",
          "Usage: #{executable_name} [options]"
        ].join("\n")

        ## menu top: on_head appear in reverse order added
        #
        opts.on('--config PATH', 'Read configuration file') do |value|
          read_configuration! options, value
        end

        ## menu body: items appear in order added
        #
        opts.on('-f RELATIVE', '--mdfilename', 'Name of document') do |value|
          options[:mdfilename] = value
        end

        opts.on('-p PATH', '--mdfolder', 'Path to documents') do |value|
          options[:mdfolder] = value
        end

        opts.on('--list-blocks', 'List blocks') do |_value|
          options[:list_blocks] = true
        end

        opts.on('--list-docs', 'List docs in current folder') do |_value|
          options[:list_docs] = true
        end

        ## menu bottom: items appear in order added
        #
        opts.on_tail('-h', '--help', 'App help') do |_value|
          puts option_parser.help
          exit
        end

        opts.on_tail('-v', '--version', 'App version') do |_value|
          puts MarkdownExec::VERSION
          exit
        end

        opts.on_tail('-x', '--exit', 'Exit app') do |_value|
          exit
        end

        opts.on_tail('-0', 'Show configuration') do |_v|
          options_finalize! options
          puts options.to_yaml
        end
      end # OptionParser
      # rubocop:enable Metrics/BlockLength

      option_parser.load # filename defaults to basename of the program without suffix in a directory ~/.options
      option_parser.environment # env defaults to the basename of the program.
      option_parser.parse! # (into: options)
      options_finalize! options

      ## process
      #
      # rubocop:disable Metrics/BlockLength
      loop do # once
        mp = MarkParse.new options
        options.merge!(
          {
            approve: true,
            bash: true,
            display: true,
            exclude_expect_blocks: true,
            execute: true,
            prompt: 'Execute',
            struct: true
          }
        )

        ## show
        #
        if options[:list_docs]
          fout mp.find_files
          break
        end

        if options[:list_blocks]
          fout (mp.find_files.map do |file|
                  mp.make_block_labels(mdfilename: file, struct: true)
                end).flatten(1).to_yaml
          break
        end

        ## process
        #
        mp.select_block(bash: true, struct: true) if options[:mdfilename]

# rubocop:disable Style/BlockComments
=begin
  # rescue ArgumentError => e
  #   puts "User abort: #{e}"

  # rescue StandardError => e
  #   puts "ERROR: #{e}"
  #   raise StandardError, e

  # ensure
  #   exit
=end
        # rubocop:enable Style/BlockComments

        break unless false # rubocop:disable Lint/LiteralAsCondition
      end # loop
    end # run
  end # class MarkParse

  # rubocop:enable Metrics/BlockLength
  # rubocop:enable Style/GlobalVars
end # module MarkdownExec
