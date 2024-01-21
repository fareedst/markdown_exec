#!/usr/bin/env ruby
# frozen_string_literal: true

# encoding=utf-8
module MarkdownExec
  class LinkState
    attr_accessor :block_name, :display_menu, :document_filename,
                  :inherited_block_names, :inherited_dependencies, :inherited_lines,
                  :prior_block_was_link

    # Initialize the LinkState with keyword arguments for each attribute.
    # @param block_name [String, nil] the name of the block.
    # @param document_filename [String, nil] the filename of the document.
    # @param inherited_block_names [Array<String>, nil] the names of the inherited blocks.
    # @param inherited_dependencies [?, nil] the dependecy hierarcy.
    # @param inherited_lines [Array<String>, nil] the inherited lines of code.
    def initialize(block_name: nil, display_menu: nil, document_filename: nil,
                   inherited_block_names: [], inherited_dependencies: nil, inherited_lines: nil,
                   prior_block_was_link: nil)
      @block_name = block_name
      @display_menu = display_menu
      @document_filename = document_filename
      @inherited_block_names = inherited_block_names
      @inherited_dependencies = inherited_dependencies
      @inherited_lines = inherited_lines
      @prior_block_was_link = prior_block_was_link
    end

    # Creates an empty LinkState instance.
    # @return [LinkState] an instance with all attributes set to their default values.
    def self.empty
      new
    end

    # Custom equality method to compare LinkState objects.
    # @param other [LinkState] the other LinkState object to compare with.
    # @return [Boolean] true if the objects are equal, false otherwise.
    def ==(other)
      other.class == self.class &&
        other.block_name == block_name &&
        other.display_menu == display_menu &&
        other.document_filename == document_filename &&
        other.inherited_block_names == inherited_block_names &&
        other.inherited_dependencies == inherited_dependencies &&
        other.inherited_lines == inherited_lines &&
        other.prior_block_was_link == prior_block_was_link
    end
  end

  class LinkHistory
    def initialize
      @history = []
    end

    # Peeks at the most recent LinkState, returns an empty LinkState if stack is empty.
    def peek
      @history.last || LinkState.empty
    end

    # Pops the most recent LinkState off the stack, returns an empty LinkState if stack is empty.
    def pop
      @history.pop || LinkState.empty
    end

    def prior_state_exist?
      peek.document_filename.present?
    end

    # Pushes a LinkState onto the stack.
    def push(link_state)
      @history.push(link_state)
    end
  end
end

if $PROGRAM_NAME == __FILE__
  require 'bundler/setup'
  Bundler.require(:default)

  require 'minitest/autorun'
  require 'mocha/minitest'

  module MarkdownExec
    class TestLinkHistory < Minitest::Test
      def setup
        @link_history = LinkHistory.new
        @link_state1 = LinkState.new(block_name: 'block1', document_filename: 'document1.txt',
                                     inherited_lines: ['code1.rb'])
        @link_state2 = LinkState.new(block_name: 'block2', document_filename: 'document2.txt',
                                     inherited_lines: ['code2.rb'])
      end

      def test_push
        @link_history.push(@link_state1)
        assert_equal @link_state1, @link_history.peek
      end

      def test_pop
        @link_history.push(@link_state1)
        @link_history.push(@link_state2)
        assert_equal @link_state2, @link_history.pop
        assert_equal @link_state1, @link_history.peek
      end

      def test_peek_empty
        assert_equal LinkState.empty, @link_history.peek
      end

      def test_pop_empty
        assert_equal LinkState.empty, @link_history.pop
      end
    end
  end
end

__END__

To generate the Ruby classes `LinkState` and `LinkHistory` with their current features and specifications, including the custom `==` method for object comparison and the implementation to handle empty states, you can use the following prompt:

---

Create Ruby classes `LinkState` and `LinkHistory` with the following specifications:

1. **Class `LinkState`**:
    - Attributes: `block_name`, `document_filename`, `inherited_lines`.
    - Initialize with optional parameters for each attribute, defaulting to `nil`.
    - Include a class method `empty` that creates an instance with all attributes set to `nil`.
    - Implement a custom `==` method for comparing instances based on attribute values.

2. **Class `LinkHistory`**:
    - Use an array to manage a stack of `LinkState` instances.
    - Implement the following methods:
        - `push`: Adds a `LinkState` instance to the top of the stack.
        - `pop`: Removes and returns the most recent `LinkState` from the stack, or returns an empty `LinkState` if the stack is empty.
        - `peek`: Returns the most recent `LinkState` without removing it from the stack, or an empty `LinkState` if the stack is empty.

3. **Testing**:
    - Write Minitest test cases to validate each method in `LinkHistory`. Test scenarios should include pushing and popping `LinkState` instances, and handling an empty `LinkHistory`.

The goal is to create a robust and efficient implementation of these classes, ensuring proper handling of stack operations and object comparisons.
