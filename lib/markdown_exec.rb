#!/usr/bin/env ruby
# frozen_string_literal: true

# encoding=utf-8

$pdebug = !(ENV['MARKDOWN_EXEC_DEBUG'] || '').empty?

require 'open3'
require 'optparse'
require 'tty-prompt'
require 'yaml'

require_relative 'markdown_exec/version'

$stderr.sync = true
$stdout.sync = true

BLOCK_SIZE = 1024
SELECT_PAGE_HEIGHT = 12

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

module MarkdownExec
  class Error < StandardError; end

  ##
  #
  class MarkParse
    attr_accessor :options

    def initialize(options = {})
      @options = options
    end

    # Returns true if all files are EOF
    #
    def all_at_eof(files)
      files.find { |f| !f.eof }.nil?
    end

    def count_blocks_in_filename
      cnt = 0
      File.readlines(options[:filename]).each do |line|
        cnt += 1 if line.match(/^```/)
      end
      cnt / 2
    end

    def fout(str)
      puts str # to stdout
    end

    def get_block_by_name(table, name, default = {})
      table.select { |block| block[:name] == name }.fetch(0, default)
    end

    def get_block_summary(opts, headings, block_title, current)
      return [current] unless opts[:struct]

      return [summarize_block(headings, block_title).merge({ body: current })] unless opts[:bash]

      bm = block_title.match(/:(\S+)( |$)/)
      reqs = block_title.scan(/\+\S+/).map { |s| s[1..] }

      if bm && bm[1]
        [summarize_block(headings, bm[1]).merge({ body: current, reqs: reqs })]
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

      blocks = []
      current = nil
      in_block = false
      block_title = ''

      headings = []
      File.readlines(opts[:filename]).each do |line|
        continue unless line

        if opts[:mdheadings]
          if (lm = line.match(/^### *(.+?) *$/))
            headings = [headings[0], headings[1], lm[1]]
          elsif (lm = line.match(/^## *([^#]*?) *$/))
            headings = [headings[0], lm[1]]
          elsif (lm = line.match(/^# *([^#]*?) *$/))
            headings = [lm[1]]
          end
        end

        if line.match(/^`{3,}/)
          if in_block
            if current

              block_title = current.join(' ').gsub(/  +/, ' ')[0..64] if block_title.nil? || block_title.empty?

              blocks += get_block_summary opts, headings, block_title, current
              current = nil
            end
            in_block = false
            block_title = ''
          else
            ## new block
            #

            lm = line.match(/^`{3,}([^`\s]*) *(.*)$/)

            do1 = false
            if opts[:bash_only]
              do1 = true if lm && (lm[1] == 'bash')
            elsif opts[:exclude_expect_blocks]
              do1 = true unless lm && (lm[1] == 'expect')
            else
              do1 = true
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
      blocks.tap { |ret| puts "list_blocks_in_file() ret: #{ret.inspect}" if $pdebug }
    end

    def list_files_per_options(options)
      default_filename = 'README.md'
      default_folder = '.'
      if options[:filename]&.present?
        list_files_specified(options[:filename], options[:folder], default_filename, default_folder)
      else
        list_files_specified(nil, options[:folder], default_filename, default_folder)
      end
    end

    def list_files_specified(specified_filename, specified_folder, default_filename, default_folder, filetree = nil)
      fn = if specified_filename&.present?
             if specified_folder&.present?
               "#{specified_folder}/#{specified_filename}"
             else
               "#{default_folder}/#{specified_filename}"
             end
           elsif specified_folder&.present?
             if filetree
               "#{specified_folder}/.+\\.md"
             else
               "#{specified_folder}/*.[Mm][Dd]"
             end
           else
             "#{default_folder}/#{default_filename}"
           end
      if filetree
        filetree.select { |filename| filename == fn || filename.match(/^#{fn}$/) || filename.match(%r{^#{fn}/.+$}) }
      else
        Dir.glob(fn)
      end.tap { |ret| puts "list_files_specified() ret: #{ret.inspect}" if $pdebug }
    end

    def list_markdown_files_in_folder
      Dir.glob(File.join(options[:folder], '*.md'))
    end

    def code(table, block)
      all = [block[:name]] + recursively_required(table, block[:reqs])
      all.reverse.map do |req|
        get_block_by_name(table, req).fetch(:body, '')
      end
         .flatten(1)
         .tap { |ret| puts "code() ret: #{ret.inspect}" if $pdebug }
    end

    def list_recursively_required_blocks(table, name)
      name_block = get_block_by_name(table, name)
      all = [name_block[:name]] + recursively_required(table, name_block[:reqs])

      # in order of appearance in document
      table.select { |block| all.include? block[:name] }
           .map { |block| block.fetch(:body, '') }
           .flatten(1)
           .tap { |ret| puts "list_recursively_required_blocks() ret: #{ret.inspect}" if $pdebug }
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
        make_block_label block, opts
      end
    end

    def optsmerge(call_options = {}, options_block = nil)
      class_call_options = options.merge(call_options || {})
      if options_block
        options_block.call class_call_options
      else
        class_call_options
      end.tap { |ret| puts "optsmerge() ret: #{ret.inspect}" if $pdebug }
    end

    def read_configuration_file!(options, configuration_path)
      if File.exist?(configuration_path)
        # rubocop:disable Security/YAMLLoad
        options.merge!((YAML.load(File.open(configuration_path)) || {})
          .transform_keys(&:to_sym))
        # rubocop:enable Security/YAMLLoad
      end
      options
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
                 .tap { |_ret| puts "recursively_required() rem: #{rem.inspect}" if $pdebug }
      end
      all.tap { |ret| puts "recursively_required() ret: #{ret.inspect}" if $pdebug }
    end

    def run
      ## default configuration
      #
      options = {
        mdheadings: true,
        list_blocks: false,
        list_docs: false
      }

      ## post-parse options configuration
      #
      options_finalize = ->(_options) {}

      # read local configuration file
      #
      read_configuration_file! options, ".#{MarkdownExec::APP_NAME.downcase}.yml"

      option_parser = OptionParser.new do |opts|
        executable_name = File.basename($PROGRAM_NAME)
        opts.banner = [
          "#{MarkdownExec::APP_NAME} - #{MarkdownExec::APP_DESC} (#{MarkdownExec::VERSION})",
          "Usage: #{executable_name} [options]"
        ].join("\n")

        ## menu top: items appear in reverse order added
        #
        opts.on('--config PATH', 'Read configuration file') do |value|
          read_configuration_file! options, value
        end

        ## menu body: items appear in order added
        #
        opts.on('-f RELATIVE', '--filename', 'Name of document') do |value|
          options[:filename] = value
        end

        opts.on('-p PATH', '--folder', 'Path to documents') do |value|
          options[:folder] = value
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
          fout option_parser.help
          exit
        end

        opts.on_tail('-v', '--version', 'App version') do |_value|
          fout MarkdownExec::VERSION
          exit
        end

        opts.on_tail('-x', '--exit', 'Exit app') do |_value|
          exit
        end

        opts.on_tail('-0', 'Show configuration') do |_v|
          options_finalize.call options
          fout options.to_yaml
        end
      end
      option_parser.load # filename defaults to basename of the program without suffix in a directory ~/.options
      option_parser.environment # env defaults to the basename of the program.
      option_parser.parse! # (into: options)
      options_finalize.call options

      ## process
      #
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
      mp = MarkParse.new options

      ## show
      #
      if options[:list_docs]
        fout mp.list_files_per_options options
        return
      end

      if options[:list_blocks]
        fout (mp.list_files_per_options(options).map do |file|
                mp.make_block_labels(filename: file, struct: true)
              end).flatten(1)
        return
      end

      mp.select_block(
        bash: true,
        filename: select_md_file(list_files_per_options(options)),
        struct: true
      )
    end

    def select_block(call_options = {}, &options_block)
      opts = optsmerge call_options, options_block

      blocks = list_blocks_in_file(opts.merge(struct: true))

      prompt = TTY::Prompt.new(interrupt: :exit)
      pt = "#{opts.fetch(:prompt, nil) || 'Pick one'}:"

      blocks.each { |block| block.merge! label: make_block_label(block, opts) }
      block_labels = blocks.map { |block| block[:label] }

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

      label_block = blocks.select { |block| block[:label] == sel }.fetch(0, nil)
      sel = label_block[:name]

      cbs = list_recursively_required_blocks(blocks, sel)

      ## display code blocks for approval
      #
      cbs.each { |cb| fout cb } if opts[:display] || opts[:approve]

      allow = true
      allow = prompt.yes? 'Process?' if opts[:approve]

      selected = get_block_by_name blocks, sel
      if allow && opts[:execute]

        ## process in script, to handle line continuations
        #
        cmd2 = cbs.flatten.join("\n")

        Open3.popen3(cmd2) do |stdin, stdout, stderr|
          stdin.close_write
          begin
            files = [stdout, stderr]

            until all_at_eof(files)
              ready = IO.select(files)

              next unless ready

              readable = ready[0]
              # writable = ready[1]
              # exceptions = ready[2]

              readable.each do |f|
                print f.read_nonblock(BLOCK_SIZE)
              rescue EOFError #=> e
                # do nothing at EOF
              end
            end
          rescue IOError => e
            fout "IOError: #{e}"
          end
        end
      end

      selected[:name]
    end

    def select_md_file(files_ = nil)
      opts = options
      files = files_ || list_markdown_files_in_folder
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

    def summarize_block(headings, title)
      { headings: headings, name: title, title: title }
    end
  end
end
