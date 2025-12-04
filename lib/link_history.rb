#!/usr/bin/env -S bundle exec ruby
# frozen_string_literal: true

# encoding=utf-8

$pd = false unless defined?($pd)

module MarkdownExec
  class LinkState
    attr_accessor :block_name, :display_menu, :document_filename,
                  :inherited_block_names, :inherited_dependencies,
                  :keep_code, :prior_block_was_link

    # Initialize the LinkState with keyword arguments for each attribute.
    # @param block_name [String, nil] the name of the block.
    # @param document_filename [String, nil] the filename of the document.
    # @param inherited_block_names [Array<String>, nil] the names of
    # the inherited blocks.
    # @param inherited_dependencies [?, nil] the dependecy hierarcy.
    # @param context_code [Array<String>, nil] the context code (shell code that provides
    #   the necessary code and data for the evaluation of individual blocks).
    # @param context_code [Array<String>, nil] Deprecated: Use context_code instead.
    def initialize(
      block_name: nil, display_menu: nil, document_filename: nil,
      inherited_block_names: [], inherited_dependencies: nil,
      context_code: nil, keep_code: false, prior_block_was_link: nil
    )
      @block_name = block_name
      @display_menu = display_menu
      @document_filename = document_filename
      @inherited_block_names = inherited_block_names
      @inherited_dependencies = inherited_dependencies
      # Support both new and deprecated parameter names
      @context_code = context_code
      @keep_code = keep_code
      @prior_block_was_link = prior_block_was_link
      wwt :link_state, self, caller.deref
    end

    # Creates an empty LinkState instance.
    # @return [LinkState] an instance with all attributes
    # set to their default values.
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
        other.context_code == context_code &&
        other.keep_code == keep_code &&
        other.prior_block_was_link == prior_block_was_link
    end

    def context_code
      @context_code.tap do |ret|
        pp ['LinkState.context_code() ->', ret] if $pd
      end
    end

    def context_code=(value)
      @context_code = value.tap do |ret|
        pp ['LinkState.context_code=() ->', ret, caller.deref(3).last] if $pd
      end
    end

    def context_code_append(value)
      @context_code = ((@context_code || []) + value).tap do |ret|
        pp ['LinkState.context_code_append() ->', ret] if $pd
      end
    end

    def context_code_block
      (@context_code || []).join("\n").tap do |ret|
        pp ['LinkState.context_code_block() ->', ret] if $pd
      end
    end

    def context_code_count
      (@context_code&.count || 0).tap do |ret|
        pp ['LinkState.context_code_count() ->', ret] if $pd
      end
    end

    def context_code_map(&block)
      @context_code.map(&block).tap do |ret|
        pp ['LinkState.context_code_map() ->', ret] if $pd
      end
    end

    def context_code_present?
      @context_code.present?.tap do |ret|
        pp ['LinkState.context_code_present?() ->', ret] if $pd
      end
    end
  end

  class LinkHistory
    def initialize
      @history = []
    end

    # Peeks at the most recent LinkState, returns an empty LinkState
    # if stack is empty.
    def peek
      @history.last || LinkState.empty
    end

    # Pops the most recent LinkState off the stack, returns an empty LinkState
    # if stack is empty.
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
        @link_state1 = LinkState.new(
          block_name: 'block1', document_filename: 'document1.txt',
          context_code: ['code1.rb']
        )
        @link_state2 = LinkState.new(
          block_name: 'block2', document_filename: 'document2.txt',
          context_code: ['code2.rb']
        )
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

      def test_context_code_accessor
        state = LinkState.new(context_code: %w[line1 line2])
        assert_equal %w[line1 line2], state.context_code
      end

      def test_context_code_block
        state = LinkState.new(context_code: %w[line1 line2])
        assert_equal "line1\nline2", state.context_code_block
      end

      def test_context_code_append
        state = LinkState.new(context_code: ['line1'])
        state.context_code_append(['line2'])
        assert_equal %w[line1 line2], state.context_code
      end

      def test_context_code_count
        state = LinkState.new(context_code: %w[line1 line2 line3])
        assert_equal 3, state.context_code_count
      end

      def test_context_code_present?
        state_with_code = LinkState.new(context_code: ['line1'])
        state_without_code = LinkState.new(context_code: nil)
        assert state_with_code.context_code_present?
        refute state_without_code.context_code_present?
      end

      def test_context_code_equality
        state1 = LinkState.new(context_code: ['line1'])
        state2 = LinkState.new(context_code: ['line1'])
        state3 = LinkState.new(context_code: ['line2'])
        assert_equal state1, state2
        refute_equal state1, state3
      end

      def test_deprecated_context_code_methods
        state = LinkState.new(context_code: %w[line1 line2])
        # Test backward compatibility
        assert_equal %w[line1 line2], state.context_code
        assert_equal "line1\nline2", state.context_code_block
        assert_equal 2, state.context_code_count
        assert state.context_code_present?
      end
    end
  end
end

__END__

To generate the Ruby classes `LinkState` and `LinkHistory` with their current features and specifications, including the custom `==` method for object comparison and the implementation to handle empty states, you can use the following prompt:

---

Create Ruby classes `LinkState` and `LinkHistory` with the following specifications:

1. **Class `LinkState`**:
    - Attributes: `block_name`, `document_filename`, `context_code`.
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
