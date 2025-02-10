# frozen_string_literal: true

require_relative 'ansi_string'

class TrackedString < String
  attr_accessor :exceeded, :truncated

  def initialize(str)
    super
    @exceeded = false
    @truncated = false
  end
end

# Class representing a hierarchy of substrings stored as Hash nodes
# HierarchyString is a class that represents and manipulates strings based on a hierarchical structure.
# The input to the class can be a single hash or an array of nested hashes, where each hash contains a
# text string and an optional decoration or transformation (like `:downcase`, `:upcase`, etc.).
#
# The primary functionalities of the class include:
#
# - **Initialization**: The class can be initialized with either a single hash or an array of nested hashes.
#   Each hash contains a @text_sym key representing the string and a @style_sym key representing the transformation
#   (optional).
#
# - **Concatenation**: The `concatenate` method concatenates all text strings in the hierarchy into a single string.
#
# - **Decoration**: The `decorate` method applies the specified transformation (like `:downcase`, `:upcase`) to the
#   text in the hierarchy and returns the decorated string.
#
# - **Text Replacement**: The `replace_text!` method allows in-place replacement of text in the hierarchy by applying
#   a block to each text string.
#
# - **Method Delegation**: The class uses `method_missing` and `respond_to_missing?` to delegate undefined method calls
#   to the string object, allowing for dynamic method handling on the concatenated string (e.g., `capitalize`).
#
# This class is useful for situations where strings are represented in a hierarchical or nested structure and need
# to be manipulated or transformed in a consistent and customizable manner.
class HierarchyString
  attr_accessor :substrings

  # Initialize with a single hash or an array of hashes
  def initialize(substrings = [], text_sym: :text, style_sym: :color)
    @substrings = parse_substrings(substrings)
    @text_sym = text_sym
    @style_sym = style_sym
  end

  def map_substring_text_yield(tree, &block)
    case tree
    when Array
      tree.each.with_index do |node, ind|
        case node
        when String
          tree[ind] = yield node
        else
          map_substring_text_yield(node, &block)
        end
      end
    when Hash
      text = yield tree[@text_sym]
      tree[@text_sym] = text

      tree
    when String
      yield tree
    else
      raise ArgumentError, 'Invalid type.'
    end
  end

  # operate on substring
  def replace_text!
    map_substring_text_yield(@substrings) do |node|
      case node
      when Hash
        text = yield node[@text_sym]
        node[@text_sym] = text
      when String
        yield node
      end
    end
  end

  # Method to concatenate all substrings into a single string
  def concatenate
    concatenate_substrings(@substrings)
  end

  # Method to decorate all substrings into a single string
  def decorate
    decorate_substrings(@substrings)
  end

  def padded_width
    concatenate.length
  end

  # Handle string inspection methods and pass them to the concatenated string
  def method_missing(method_name, *arguments, &block)
    if ''.respond_to?(method_name)
      concatenate.send(method_name, *arguments, &block)
    else
      super
    end
  end

  # Ensure proper handling of method checks
  def respond_to_missing?(method_name, include_private = false)
    ''.respond_to?(method_name) || super
  end

  private

  # Parse the input substrings into a nested array of hashes structure
  def parse_substrings(substrings)
    case substrings
    when Hash
      [substrings]
    when Array
      substrings.map { |s| parse_substrings(s) }
    else
      substrings
      # raise ArgumentError, 'Invalid input type. Expected Hash or Array.'
    end
  end

  # Recursively concatenate substrings
  def concatenate_substrings(substrings)
    substrings.map do |s|
      case s
      when Hash
        s[@text_sym]
      when Array
        concatenate_substrings(s)
      end
    end.join
  end

  # Recursively decorate substrings
  def decorate_substrings(substrings, prior_color = '')
    substrings.map do |s|
      case s
      when Hash
        if s[@style_sym]
          AnsiString.new(s[@text_sym]).send(s[@style_sym]) + prior_color
        else
          s[@text_sym]
        end
      when Array
        decorate_substrings(s, prior_color)
      end
    end.join
  end
end

return if $PROGRAM_NAME != __FILE__

require 'minitest/autorun'

class TestHierarchyString < Minitest::Test
  def setup
    text_sym = :text
    style_sym = :color

    @single_hash = { text_sym => 'Hello', style_sym => :downcase }
    @nested_hashes = [
      { text_sym => 'Hello', style_sym => :downcase },
      [
        { text_sym => ' ', style_sym => nil },
        { text_sym => 'World', style_sym => :upcase }
      ]
    ]
    @hierarchy_single = HierarchyString.new(@single_hash)
    @hierarchy_nested = HierarchyString.new(@nested_hashes)
  end

  def test_initialize_single_hash
    text_sym = :text
    style_sym = :color

    assert_equal [{ text_sym => 'Hello', style_sym => :downcase }],
                 @hierarchy_single.substrings
  end

  def test_initialize_nested_hashes
    text_sym = :text
    style_sym = :color

    expected = [
      [{ text_sym => 'Hello', style_sym => :downcase }],
      [
        [{ text_sym => ' ', style_sym => nil }],
        [{ text_sym => 'World', style_sym => :upcase }]
      ]
    ]
    assert_equal expected, @hierarchy_nested.substrings
  end

  def test_concatenate_single_hash
    assert_equal 'Hello', @hierarchy_single.concatenate
  end

  def test_concatenate_nested_hashes
    assert_equal 'Hello World', @hierarchy_nested.concatenate
  end

  def test_decorate_single_hash
    assert_equal 'Hello'.downcase, @hierarchy_single.decorate
  end

  def test_decorate_nested_hashes
    assert_equal "#{'Hello'.downcase} #{'World'.upcase}",
                 @hierarchy_nested.decorate
  end

  def test_replace_text_single_hash
    @hierarchy_single.replace_text!(&:upcase)
    assert_equal 'HELLO', @hierarchy_single.concatenate
  end

  def test_replace_text_nested_hashes
    @hierarchy_nested.replace_text!(&:upcase)
    assert_equal 'HELLO WORLD', @hierarchy_nested.concatenate
  end

  def test_method_missing
    assert_equal 'Hello', @hierarchy_single.capitalize
  end

  def test_respond_to_missing
    assert @hierarchy_single.respond_to?(:capitalize)
    refute @hierarchy_single.respond_to?(:non_existent_method)
  end
end
