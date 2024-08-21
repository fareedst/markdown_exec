# frozen_string_literal: true

# Class representing a hierarchy of substrings stored as Hash nodes
class HierarchyString
  attr_accessor :substrings

  # Initialize with a single hash or an array of hashes
  def initialize(substrings)
    @substrings = parse_substrings(substrings)
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
      text = yield tree[:text]
      tree[:text] = text

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
        text = yield node[:text]
        node[:text] = text
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
        s[:text]
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
        if s[:color]
          s[:text].send(s[:color]) + prior_color
        else
          s[:text]
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
    @single_hash = { text: 'Hello', color: :downcase }
    @nested_hashes = [
      { text: 'Hello', color: :downcase },
      [
        { text: ' ', color: nil },
        { text: 'World', color: :upcase }
      ]
    ]
    @hierarchy_single = HierarchyString.new(@single_hash)
    @hierarchy_nested = HierarchyString.new(@nested_hashes)
  end

  def test_initialize_single_hash
    assert_equal [{ text: 'Hello', color: :downcase }],
                 @hierarchy_single.substrings
  end

  def test_initialize_nested_hashes
    expected = [
      [{ text: 'Hello', color: :downcase }],
      [
        [{ text: ' ', color: nil }],
        [{ text: 'World', color: :upcase }]
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
