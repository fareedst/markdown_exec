#!/usr/bin/env bundle exec ruby
# frozen_string_literal: true

# encoding=utf-8

# require_relative 'instance_method_wrapper' # for ImwUx
require_relative 'env'
require_relative 'link_history'

# InputSequencer manages the sequence of menu interactions and block executions based on user input.
class InputSequencer
  # extend ImwUx # This makes imw_indent available as a class method
  # include ImwUx # This makes imw_indent available as a class method

  # self.prepend InstanceMethodWrapper # traps initialize as well
  attr_reader :document_filename, :current_block, :block_queue

  def initialize(document_filename, initial_blocks = nil)
    @document_filename = document_filename
    @current_block = nil
    @block_queue = initial_blocks
    @debug = Env.env_bool('INPUT_SEQUENCER_DEBUG', default: false)
  # rubocop:disable Style/RescueStandardError
  rescue
    pp $!, $@
    exit 1
    # rubocop:enable Style/RescueStandardError
  end

  # Merges the current menu state with the next, prioritizing the next state's values.
  def self.merge_link_state(current, next_state)
    MarkdownExec::LinkState.new(
      block_name: next_state.block_name,
      display_menu: next_state.display_menu.nil? ? current.display_menu : next_state.display_menu,
      document_filename: next_state.document_filename || current.document_filename,
      inherited_block_names: next_state.inherited_block_names,
      inherited_dependencies: next_state.inherited_dependencies,
      inherited_lines: next_state.inherited_lines,
      prior_block_was_link: next_state.prior_block_was_link.nil? ? current.prior_block_was_link : next_state.prior_block_was_link
    )
  # rubocop:disable Style/RescueStandardError
  rescue
    pp $!, $@
    exit 1
    # rubocop:enable Style/RescueStandardError
  end

  # Generates the next menu state based on provided attributes.

  def self.next_link_state(block_name: nil, display_menu: nil, document_filename: nil, prior_block_was_link: false)
    MarkdownExec::LinkState.new(
      block_name: block_name,
      display_menu: display_menu,
      document_filename: document_filename,
      prior_block_was_link: prior_block_was_link
    )
  end

  # Orchestrates the flow of menu states and user interactions.
  def run_yield(sym, *args, &block)
    block.call sym, *args
  # rubocop:disable Style/RescueStandardError
  rescue
    pp $!, $@
    exit 1
    # rubocop:enable Style/RescueStandardError
  end

  def bq_is_empty?
    !@block_queue || @block_queue.empty?
  end

  # Orchestrates the flow of menu states and user interactions.
  def run(&block)
    now_menu = InputSequencer.next_link_state(
      display_menu: bq_is_empty?,
      document_filename: @document_filename,
      prior_block_was_link: false # true bypass_exit when last block was a link (from cli)
    )
    exit_when_bq_empty = !bq_is_empty? # true when running blocks from cli; unless "stay" is used
    loop do
      break if run_yield(:parse_document, now_menu.document_filename, &block) == :break

      # self.imw_ins now_menu, 'now_menu'

      break if exit_when_bq_empty && bq_is_empty? && !now_menu.prior_block_was_link

      if now_menu.display_menu
        exit_when_bq_empty = false
        run_yield :display_menu, &block

        choice = run_yield :user_choice, &block

        raise 'Block not recognized.' if choice.nil?
        break if run_yield(:exit?, choice&.downcase, &block) # Exit loop and method to terminate the app

        next_state = run_yield :execute_block, choice, &block
        # imw_ins next_state, 'next_state'
        return :break if next_state == :break

        next_menu = next_state

      else
        if now_menu.block_name && !now_menu.block_name.empty?
          block_name = now_menu.block_name
        else
          break if bq_is_empty? # Exit loop if no more blocks to process

          block_name = @block_queue.shift
        end
        # self.imw_ins block_name, 'block_name'

        next_menu = if block_name == '.'
                      exit_when_bq_empty = false
                      InputSequencer.next_link_state(display_menu: true)
                    else
                      state = run_yield :execute_block, block_name, &block
                      state.display_menu = bq_is_empty?
                      state
                    end
        next_menu
        # imw_ins next_menu, 'next_menu'
      end
      now_menu = InputSequencer.merge_link_state(now_menu, next_menu)
    end
  # rubocop:disable Style/RescueStandardError
  rescue
    pp $!, $@
    exit 1
    # rubocop:enable Style/RescueStandardError
  end
end

return if __FILE__ != $PROGRAM_NAME

$doc1 = {
  'b1' => 'Content of bash1',
  'b2' => 'Content of bash2',
  'b3' => 'Content of bash3',
  'l1' => { 'block_name' => 'b1', 'document_filename' => 'd1' },
  'l2' => { 'block_name' => 'b2', 'document_filename' => 'd2' },
  'l3' => { 'block_name' => 'b3' }
}.freeze
$stay = '.' # keep menu open (from command line)
$texit = 'x'

class MDE
  # extend ImwUx # This makes imw_indent available as a class method
  # include ImwUx # This makes imw_indent available as a class method

  def initialize(document_filename, initial_blocks = [])
    @inpseq = InputSequencer.new(document_filename, initial_blocks)
  end

  def do_run
    @inpseq.run do |msg, data|
      case msg
      when :parse_document # once for each menu
        # self.imw_ins data, '@ - parse document'
        parse_document(data)
      when :display_menu
        puts "? - Select a block to execute (or type #{$texit} to exit):"
        puts "doc: #{@document_filename}"
        display_menu
      when :user_choice
        $stdin.gets.chomp
      when :execute_block
        # self.imw_ins data, "! - Executing block"
        execute_block(data)
      when :exit?
        data == $texit
      when :stay?
        data == $stay
      else
        raise "Invalid message: #{msg}"
      end
    end
  end

  private

  def display_menu
    @blocks.each_key { |block| puts block }
    puts $texit
  end

  def execute_block(block_name)
    content = @blocks[block_name]
    if content
      puts content
      if block_name.start_with?('l')
        interpret_link_block(content)
      else
        InputSequencer.next_link_state
      end
    else
      puts "! - Block not found: #{block_name}"
      InputSequencer.next_link_state
    end
  end

  def interpret_link_block(content)
    # Stub: Interpret a "Link" block, extracting directives for the next action
    # In a real implementation, this would parse the content for next block or document
    puts "! - Interpreting Link block: #{content}"
    InputSequencer.next_link_state(
      block_name: content.fetch('block_name', nil),
      document_filename: content.fetch('document_filename', nil),
      prior_block_was_link: true
    )
  end

  def load_document(_name)
    # Stub: Load and return the content of the document
    # In a real implementation, this would read the file and return its content
    # "Block 1: Content of block 1\nBlock 2: Content of block 2\nLink: block_name 3, document_filename doc2"
    $doc1.map { |key, value| "#{key}: #{value}" }.join("\n")
  end

  def parse_document(data)
    load_document(data)
    # Stub: Parse document content into blocks
    # In a real implementation, this would split the document into named blocks
    @blocks = $doc1
  end
end
# MDE.singleton_class.prepend(ImwUx)
# MDE.prepend(ImwUx)

def main
  if ARGV.empty?
    puts "Usage: #{__FILE__} document_filename [block_name...]"
    exit(1)
  end
  document_filename = ARGV.shift
  initial_blocks = ARGV
  mde = MDE.new(document_filename, initial_blocks)
  mde.do_run
end

main
