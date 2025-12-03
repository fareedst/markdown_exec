#!/usr/bin/env -S bundle exec ruby
# frozen_string_literal: true

# encoding=utf-8
require 'bundler/setup' # Bundler enforces gem versions
require 'pp'
require 'stringio'

# call depth icons
DEPTH_ICON = '›'

# log levels
LOG_LEVELS = %i[debug info warn error fatal].freeze

# is enabled
private def enable_debugging
  ENV.fetch('WW', '0').to_i.positive?
end

# is enabled, not silent
private def env_show_attribution
  ENV['WW'] != '0'
end

private def is_new_alg?
  # use the new algo only if env var is ALG is not empty
  !ENV.fetch('ALG', '').empty?

  # use the new algo if ALG != 0
  # ENV.fetch('ALG', '') != '0'
end

# enable application-wide debugging
$debug = $DEBUG || enable_debugging

# no default category
$ww_category = nil

# no default log file
$ww_log_file = nil

# default output to $stderr
$ww_output = $stderr
unless ($id = ENV.fetch('WW_LOG', '')).empty?
  alg = is_new_alg? ? '1' : '0'
  # local log file with timestamp and algo name
  $ww_log_file = "#{Time.now.utc.strftime '%H-%M-%S'}-#{$id}-#{alg}.log"
end

# attribution in output unless disabled
if env_show_attribution
  if $debug
    # not silent, display notice
    if $DEBUG
      # debugging triggered by Ruby debug
      warn "WW Debugging per $DEBUG ('ruby --debug')"
    else
      # debugging triggered by WW environment variable
      warn 'WW Debugging per environment variable WW'
    end
  end
  if is_new_alg?
    warn "WW Testing a new algorithm. Control with env var 'ALG'"
  end
end

# selectively enabled, for general debugging
# return the last item in the list
def ww(*objs, **kwargs)
  # assume the final item is the significant one
  # allows prefixing to an existing expression and forwarding the result
  return objs.last unless $debug

  locations = kwargs[:locations] || caller_locations
  ww0(*objs, **kwargs.merge(locations: locations))
end

# output the object and backtrace for the error
# abort
def wwa(*objs, **kwargs)
  ww0(*objs,
      **kwargs.merge(full_backtrace: true,
                     locations: caller_locations))

  exit 1
end

# break into the debugger if enabled
def wwb
  binding.irb if $debug
end

# output the object and backtrace for the error
# raise the error for the caller to handle
def wwe(*objs, **kwargs)
  ww0(*objs,
      **kwargs.merge(full_backtrace: true,
                     locations: caller_locations))

  # raise StandardError, objs.first.fetch(:error) || objs.first
  raise StandardError, objs.first
end

# selectively enabled, for process tracking
# output data and the caller's location
def wwp(*objs, **kwargs)
  return objs.last unless $debug

  ww0(*objs,
      **kwargs.merge(
        locations: caller_locations[0..0],
        location_offset: caller_locations.count
      ))
end

# the return value for a function
def wwr(*objs, **kwargs)
  # assume the final item is the significant one
  # allows prefixing to an existing expression and forwarding the result
  return objs.last unless $debug

  ww0(*objs,
      **kwargs.merge(
        locations: caller_locations[0..0],
        location_offset: caller_locations.count
      ))
end

# selectively enabled, for tagged data
# the first item is the tag, the rest is data
# exclude tags in the list of tags to skip
# output data and the caller's location
def wwt(*objs, **kwargs)
  # tags to skip
  return objs.last if !$debug || %i[blocks env fcb].include?(objs.first)

  formatted = ['Tagged', objs.first] + objs[1..]
  ww0(*formatted,
      **kwargs.merge(
        locations: caller_locations[0..0],
        location_offset: caller_locations.count
      ))
end

# enhanced expression wrapper with better context
# usage: wwx { some_expression } or wwx(expression)
def wwx(expression = nil, **kwargs, &block)
  if block_given?
    # Block form: wwx { some_expression }
    result = block.call
    return result unless $debug

    # Capture the source location of the block
    locations = kwargs[:locations] || caller_locations
    ww0(result, **kwargs.merge(locations: locations, context: 'block'))
  elsif expression
    # Direct form: wwx(some_expression)
    return expression unless $debug

    locations = kwargs[:locations] || caller_locations
    ww0(expression, **kwargs.merge(locations: locations, context: 'direct'))
  else
    # No arguments - just return nil
    nil
  end
end

# output the formatted data and location
def ww0(*objs,
        category: $ww_category,
        context: nil,
        full_backtrace: false,
        level: :debug,
        locations: caller_locations,
        log_file: $ww_log_file,
        output: $ww_output,
        single_line: false,
        timestamp: false,
        location_offset: 0)
  # Format caller information line
  caller_info_line = lambda do |caller_info, ind|
    [
      DEPTH_ICON * (location_offset + locations.count - ind),
      caller_info.path.deref,
      caller_info.lineno,
      caller_info.label
    ].join(' : ')
  end
  # Validate log level
  raise ArgumentError,
        "Invalid log level: #{level}" unless LOG_LEVELS.include?(level)

  # Generate backtrace
  backtrace = if full_backtrace
                locations.map.with_index do |caller_info, ind|
                  caller_info_line.call(caller_info, ind)
                end
              else
                [caller_info_line.call(locations.first, 0)]
              end

  # Add optional timestamp
  time_prefix = timestamp ? "[#{Time.now.strftime('%Y-%m-%d %H:%M:%S')}] " : ''

  # Add log level, category, and context prefix
  level_prefix = "[#{level.to_s.upcase}]"
  category_prefix = category ? "[#{category}] " : ''
  context_prefix = context ? "[#{context}] " : ''

  # Combine all parts into the final message
  header = "#{time_prefix}#{level_prefix} #{category_prefix}#{context_prefix}"
  trace = backtrace + objs
  io = StringIO.new
  formatted_message = if single_line
                        PP.singleline_pp(trace, io)
                        "#{header} #{io.string}"
                      else
                        PP.pp(trace, io)
                        "#{header}\n#{io.string}"
                      end

  # prefix each line in formatted_message
  prefix = (' ' * 8).freeze
  formatted_message = prefix + formatted_message.gsub("\n", "\n#{prefix}")

  # Output to $stderr or specified IO object
  output.puts "\033[38;2;128;191;191m#{formatted_message}\033[0m"
  output.flush

  # Optionally log to a file
  if log_file
    File.open(log_file, 'a') do |file|
      file.puts(formatted_message)
    end
  end

  # Always return the last item in the list, as the label is usually first
  objs.last
end

class Array
  unless defined?(deref)

    # trim the backtrace to project source files
    # exclude vendor and .bundle directories
    # limit the count to 4
    # replace the home directory with a .
    def deref(count = 4)
      dir_pwd = Dir.pwd
      map(&:deref).reject do |line|
        %r{^/(vendor|\.bundle)/}.match(line)
      end.first(count).map do |line|
        line.sub(dir_pwd, '.')
      end
    end
  end
end

class String
  unless defined?(deref)
    # replace the app's directory with a .
    def deref
      sub(%r{^#{Dir.pwd}}, '')
    end
  end
end

class Array
  # Count occurrences by method result using tally (Ruby 2.7+)
  #
  # @param method [Symbol, String] The method to call on each element
  # @return [Hash] Hash of method result => count pairs
  def count_by(method)
    raise ArgumentError,
          'Method must be a Symbol or String' unless method.is_a?(Symbol) || method.is_a?(String)

    if respond_to?(:tally) # Ruby 2.7+
      map do |item|
        item.respond_to?(method) ? item.send(method) : nil
      end.compact.tally
    else
      # Fallback for older Ruby versions
      result = Hash.new(0)
      each do |item|
        if item.respond_to?(method)
          value = item.send(method)
          result[value] += 1
        end
      end
      result
    end
  rescue NoMethodError => err
    warn "Method #{method} not available on some items: #{err.message}"
    {}
  end

  # Use filter_map for combined filtering and mapping (Ruby 2.7+)
  # Filters elements and transforms them in one pass
  #
  # @param method [Symbol, String] The method to call on each element
  # @param value [Object] The value to match against
  # @param transform_method [Symbol, String, nil] Optional
  #         method to call on matching elements
  # @return [Array] Array of transformed matching elements
  def filter_map_by(method, value, transform_method = nil)
    raise ArgumentError,
          'Method must be a Symbol or String' unless method.is_a?(Symbol) || method.is_a?(String)

    if respond_to?(:filter_map) # Ruby 2.7+
      filter_map do |item|
        if item.respond_to?(method) && item.send(method) == value
          transform_method ? item.send(transform_method) : item
        end
      end
    else
      # Fallback for older Ruby versions
      result = []
      each do |item|
        if item.respond_to?(method) && item.send(method) == value
          result << (transform_method ? item.send(transform_method) : item)
        end
      end
      result
    end
  rescue NoMethodError => err
    warn "Method #{method} not available on some items: #{err.message}"
    []
  end

  # Find the first element where the specified method matches a value
  # Supports both method-based and block-based filtering
  #
  # @param method [Symbol, String, nil] The method to call on each element
  # @param value [Object, nil] The value to match against
  # @param default [Object, nil] Default value if no match found
  # @param block [Proc, nil] Optional block for custom filtering logic
  # @return [Object, nil] The first matching element or default
  def find_by(method = nil, value = nil, default = nil, &block)
    if block_given?
      find(&block)
    else
      raise ArgumentError,
            'Method must be a Symbol or String' unless method.is_a?(Symbol) || method.is_a?(String)

      find do |item|
        item.respond_to?(method) && item.send(method) == value
      end || default
    end
  rescue NoMethodError => err
    warn "Method #{method} not available on some items: #{err.message}"
    default
  end

  # Find elements using hash-based conditions
  # All conditions must match for an element to be included
  #
  # @param conditions [Hash] Hash of method => value pairs
  # @return [Array] Array of matching elements
  def find_where(conditions = {})
    find do |item|
      conditions.all? do |method, value|
        item.respond_to?(method) && item.send(method) == value
      end
    end
  rescue NoMethodError => err
    warn "Some methods not available on items: #{err.message}"
    nil
  end

  # Match elements using pattern matching (Ruby 2.7+)
  # Uses grep for pattern matching against method results
  #
  # @param method [Symbol, String] The method to call on each element
  # @param pattern [Regexp, Object] Pattern to match against
  # @return [Array] Array of matching elements
  def match_by(method, pattern)
    raise ArgumentError,
          'Method must be a Symbol or String' unless method.is_a?(Symbol) || method.is_a?(String)

    grep { |item| pattern === item.send(method) }
  rescue NoMethodError => err
    warn "Method #{method} not available on some items: #{err.message}"
    []
  end

  # Partition elements based on method result
  #
  # @param method [Symbol, String] The method to call on each element
  # @param value [Object] The value to partition by
  # @return [Array] Array containing [matching_elements, non_matching_elements]
  def partition_by(method, value)
    raise ArgumentError,
          'Method must be a Symbol or String' unless method.is_a?(Symbol) || method.is_a?(String)

    partition do |item|
      item.respond_to?(method) &&
        item.send(method) == value
    end
  rescue NoMethodError => err
    warn "Method #{method} not available on some items: #{err.message}"
    [[], self]
  end

  # Reject elements where the specified method matches a value
  # Supports both method-based and block-based filtering
  #
  # @param method [Symbol, String, nil] The method to call on each element
  # @param value [Object, nil] The value to match against
  # @param block [Proc, nil] Optional block for custom filtering logic
  # @return [Array] Array of non-matching elements
  def reject_by(method = nil, value = nil, &block)
    if block_given?
      reject(&block)
    else
      raise ArgumentError,
            'Method must be a Symbol or String' unless method.is_a?(Symbol) || method.is_a?(String)

      reject do |item|
        item.respond_to?(method) &&
          item.send(method) == value
      end
    end
  rescue NoMethodError => err
    warn "Method #{method} not available on some items: #{err.message}"
    self
  end

  # Select elements where the specified method matches a value
  # Supports both method-based and block-based filtering
  #
  # @param method [Symbol, String, nil] The method to call on each element
  # @param value [Object, nil] The value to match against
  # @param block [Proc, nil] Optional block for custom filtering logic
  # @return [Array] Array of matching elements
  def select_by(method = nil, value = nil, &block)
    if block_given?
      select(&block)
    else
      raise ArgumentError,
            'Method must be a Symbol or String' unless method.is_a?(Symbol) || method.is_a?(String)

      select do |item|
        item.respond_to?(method) &&
          item.send(method) == value
      end
    end
  rescue NoMethodError => err
    warn "Method #{method} not available on some items: #{err.message}"
    []
  end

  # Select elements using hash-based conditions
  # All conditions must match for an element to be included
  #
  # @param conditions [Hash] Hash of method => value pairs
  # @return [Array] Array of matching elements
  def select_where(conditions = {})
    select do |item|
      conditions.all? do |method, value|
        item.respond_to?(method) && item.send(method) == value
      end
    end
  rescue NoMethodError => err
    warn "Some methods not available on items: #{err.message}"
    []
  end
end

return if $PROGRAM_NAME != __FILE__

require 'minitest/autorun'

class TestWwFunction < Minitest::Test
  def setup
    # Save original global state
    @original_debug = $debug
    @original_ww_log_file = $ww_log_file
    @original_ww_output = $ww_output
    @original_ww_category = $ww_category

    # Redirect output to capture it - ensure it's writable
    @output_buffer = StringIO.new
    @output_buffer.sync = true
    $ww_output = @output_buffer
    $ww_category = nil
  end

  def teardown
    # Restore original global state
    $debug = @original_debug
    $ww_log_file = @original_ww_log_file
    $ww_output = @original_ww_output
    $ww_category = @original_ww_category

    # Clean up any test log files
    Dir.glob('test*.log').each { |f| FileUtils.rm_f(f) }
  end

  # Core functionality tests
  def test_ww_returns_last_item_with_debug_disabled
    $debug = false
    $ww_log_file = nil

    # Test with single item
    result = ww('single_item')
    assert_equal 'single_item', result,
                 'ww should return the single item when debug is disabled'

    # Test with multiple items
    result = ww('first', 'second', 'third')
    assert_equal 'third', result,
                 'ww should return the last item when debug is disabled'

    # Test with various data types
    result = ww(1, 'string', :symbol, [1, 2, 3])
    assert_equal [1, 2, 3], result,
                 'ww should return the last item regardless of type'

    # Verify no output when debug is disabled
    assert_empty @output_buffer.string,
                 'No output should be generated when debug is disabled'
  end

  def test_ww_returns_last_item_with_debug_enabled_no_log_file
    $debug = true
    $ww_log_file = nil

    # Test with single item
    result = ww('single_item')
    assert_equal 'single_item', result,
                 'ww should return the single item when debug is enabled and no log file'

    # Test with multiple items
    result = ww('first', 'second', 'third')
    assert_equal 'third', result,
                 'ww should return the last item when debug is enabled and no log file'

    # Test with mixed types
    result = ww(42, 'hello', :world, { key: 'value' })
    assert_equal({ key: 'value' }, result,
                 'ww should return the last item even with hash')

    # Verify output is generated when debug is enabled
    refute_empty @output_buffer.string,
                 'Output should be generated when debug is enabled'
  end

  def test_ww_returns_last_item_with_debug_enabled_with_log_file
    $debug = true
    $ww_log_file = 'test_ww.log'

    begin
      # Test with single item
      result = ww('single_item')
      assert_equal 'single_item', result,
                   'ww should return the single item when debug is enabled with log file'

      # Test with multiple items
      result = ww('first', 'second', 'third')
      assert_equal 'third', result,
                   'ww should return the last item when debug is enabled with log file'

      # Test with various data types
      result = ww(1, 'string', :symbol, [1, 2, 3])
      assert_equal [1, 2, 3], result,
                   'ww should return the last item regardless of type with log file'

      # Verify log file was created and contains content
      assert File.exist?('test_ww.log'), 'Log file should be created'
      refute_empty File.read('test_ww.log'), 'Log file should contain content'
    ensure
      # Clean up test log file
      FileUtils.rm_f('test_ww.log')
    end
  end

  def test_ww_with_named_options
    $debug = false

    # Test that named options don't affect the return value
    result = ww('first', 'second', category: 'test', level: :info)
    assert_equal 'second', result,
                 'ww should return the last item even with named options'

    # Test with single item and options
    result = ww('only_item', timestamp: true, single_line: true)
    assert_equal 'only_item', result,
                 'ww should return the single item even with named options'

    # Test with various option combinations
    result = ww('a', 'b', 'c', category: 'testing', level: :warn,
                               timestamp: true, single_line: false)
    assert_equal 'c', result,
                 'ww should return the last item with complex options'
  end

  # Test all ww function variants
  def test_wwr_function_returns_last_item
    $debug = true
    $ww_log_file = nil

    # Test wwr with multiple items
    result = wwr('first', 'second', 'third')
    assert_equal 'third', result, 'wwr should return the last item'

    # Test wwr with single item
    result = wwr('only_item')
    assert_equal 'only_item', result, 'wwr should return the single item'

    # Test wwr with debug disabled
    $debug = false
    result = wwr('a', 'b', 'c')
    assert_equal 'c', result,
                 'wwr should return the last item even when debug is disabled'
  end

  def test_wwp_function_returns_last_item
    $debug = true
    $ww_log_file = nil

    # Test wwp with multiple items
    result = wwp('first', 'second', 'third')
    assert_equal 'third', result, 'wwp should return the last item'

    # Test wwp with single item
    result = wwp('only_item')
    assert_equal 'only_item', result, 'wwp should return the single item'

    # Test wwp with debug disabled
    $debug = false
    result = wwp('a', 'b', 'c')
    assert_equal 'c', result,
                 'wwp should return the last item even when debug is disabled'
  end

  def test_wwt_function_returns_last_item
    $debug = true
    $ww_log_file = nil

    # Test wwt with multiple items (first item is tag)
    result = wwt(:test_tag, 'first', 'second', 'third')
    assert_equal 'third', result, 'wwt should return the last item'

    # Test wwt with single data item after tag
    result = wwt(:tag, 'only_data_item')
    assert_equal 'only_data_item', result,
                 'wwt should return the single data item'

    # Test wwt with skipped tags
    result = wwt(:blocks, 'data')
    assert_equal 'data', result, 'wwt should return data even for skipped tags'

    # Test wwt with debug disabled
    $debug = false
    result = wwt(:any_tag, 'a', 'b', 'c')
    assert_equal 'c', result,
                 'wwt should return the last item even when debug is disabled'
  end

  def test_wwt_multiline_continuation
    $debug = true
    $ww_log_file = nil

    # Test multiline continuation pattern
    var1 = 'test_value'
    result = wwt :tag1, \
                 var1
    assert_equal 'test_value', result,
                 'wwt should work with multiline continuation'

    # Test with complex expression
    complex_var = [1, 2, 3]
    result = wwt(:processing, \
                 complex_var.map { |x| x * 2 })
    assert_equal [2, 4, 6], result,
                 'wwt should work with complex expressions in multiline'

    # Test with debug disabled
    $debug = false
    simple_var = 'no_debug'
    result = wwt :disabled, \
                 simple_var
    assert_equal 'no_debug', result,
                 'wwt should return correct value even with debug disabled'
  end

  def test_ww_multiline_continuation
    $debug = true
    $ww_log_file = nil

    # Test ww with multiline continuation
    var1 = 'test_value'
    result = ww \
      var1
    assert_equal 'test_value', result,
                 'ww should work with multiline continuation'

    # Test with multiple items in multiline
    result = ww 'prefix', \
                'value'
    assert_equal 'value', result,
                 'ww should work with multiple items in multiline'

    # Test with debug disabled
    $debug = false
    result = ww \
      'no_debug_value'
    assert_equal 'no_debug_value', result,
                 'ww should return correct value with debug disabled'
  end

  def test_wwa_function_behavior
    $debug = true

    # Test that wwa exits (we can't easily test exit behavior in minitest)
    # So we'll just verify it would call ww0 properly by testing the
    # structure
    # Note: wwa calls exit, so we can't test it directly without special
    # handling
    skip 'wwa exits the program, cannot test directly in minitest'
  end

  def test_wwe_function_behavior
    $debug = true

    # Test that wwe raises an error
    assert_raises(StandardError) do
      wwe('error message')
    end

    # Test that wwe raises with the first object as the error message
    error = assert_raises(StandardError) do
      wwe('custom error', 'additional', 'data')
    end
    assert_equal 'custom error', error.message
  end

  # Edge case tests
  def test_edge_cases
    $debug = false

    # Test with nil values
    result = ww(nil, 'not_nil')
    assert_equal 'not_nil', result, 'ww should handle nil values correctly'

    # Test with empty array as last item
    result = ww('first', [])
    assert_equal [], result,
                 'ww should return empty array if it is the last item'

    # Test with false as last item
    result = ww('first', false)
    assert_equal false, result, 'ww should return false if it is the last item'

    # Test with zero as last item
    result = ww('first', 0)
    assert_equal 0, result, 'ww should return zero if it is the last item'

    # Test with empty string as last item
    result = ww('first', '')
    assert_equal '', result,
                 'ww should return empty string if it is the last item'
  end

  def test_complex_data_structures
    $debug = false

    # Test with nested arrays
    nested = [1, [2, [3, 4]], 5]
    result = ww('start', nested)
    assert_equal nested, result, 'ww should handle nested arrays'

    # Test with complex hash
    complex_hash = {
      users: [{ name: 'Alice', age: 30 }, { name: 'Bob', age: 25 }],
      metadata: { created: Time.now, version: '1.0' }
    }
    result = ww('prefix', complex_hash)
    assert_equal complex_hash, result, 'ww should handle complex hashes'

    # Test with objects
    string_obj = String.new('test')
    result = ww('object', string_obj)
    assert_equal string_obj, result, 'ww should handle object instances'
  end

  def test_options_validation
    $debug = true
    $ww_log_file = nil

    # Test valid log levels
    %i[debug info warn error fatal].each do |level|
      result = ww('test', level: level)
      assert_equal 'test', result, "ww should work with log level #{level}"
    end

    # Test invalid log level raises error
    assert_raises(ArgumentError) do
      ww('test', level: :invalid)
    end
  end

  def test_output_formatting_options
    $debug = true
    $ww_log_file = nil

    # Create fresh buffer for this test
    fresh_buffer = StringIO.new
    $ww_output = fresh_buffer

    # Test single_line option
    ww('test', 'data', single_line: true)
    output = fresh_buffer.string
    refute_includes output, "\n        [",
                    'single_line should format output on one line'

    # Reset buffer
    fresh_buffer = StringIO.new
    $ww_output = fresh_buffer

    # Test timestamp option
    ww('test', timestamp: true)
    output = fresh_buffer.string
    assert_match(/\[\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\]/, output,
                 'timestamp should be included in output')

    # Reset buffer
    fresh_buffer = StringIO.new
    $ww_output = fresh_buffer

    # Test category option
    ww('test', category: 'MYCATEGORY')
    output = fresh_buffer.string
    assert_includes output, '[MYCATEGORY]',
                    'category should be included in output'
  end

  def test_location_information
    $debug = true
    $ww_log_file = nil

    # Create fresh buffer for this test
    fresh_buffer = StringIO.new
    $ww_output = fresh_buffer

    # Test that location information is included
    ww('location test')
    output = fresh_buffer.string

    # Should include file path and line number information
    assert_includes output, 'lib/ww.rb', 'output should include filename'
    assert_match(/\s:\s\d+\s:/, output,
                 'output should include line number with format')
  end

  def test_full_backtrace_option
    $debug = true
    $ww_log_file = nil

    # Create fresh buffer for this test
    fresh_buffer = StringIO.new
    $ww_output = fresh_buffer

    # Test full_backtrace option
    ww('test', full_backtrace: true)
    output = fresh_buffer.string

    # With full backtrace, we should see multiple stack levels
    # (This is hard to test precisely since it depends on call stack depth)
    refute_empty output, 'full_backtrace should produce output'
  end

  def test_multiple_consecutive_calls
    $debug = false

    # Test that multiple calls work correctly
    results = []
    results << ww('call1', 'result1')
    results << ww('call2a', 'call2b', 'result2')
    results << ww('call3a', 'call3b', 'call3c', 'result3')

    assert_equal %w[result1 result2 result3], results,
                 'Multiple consecutive calls should work correctly'
  end

  def test_return_value_consistency_across_debug_states
    # Test the same call with debug enabled and disabled
    test_args = %w[first second third]

    # With debug disabled
    $debug = false
    $ww_log_file = nil
    result_no_debug = ww(*test_args)

    # With debug enabled, no log file
    $debug = true
    $ww_log_file = nil
    result_debug_no_log = ww(*test_args)

    # With debug enabled, with log file
    $debug = true
    $ww_log_file = 'consistency_test.log'
    begin
      result_debug_with_log = ww(*test_args)
    ensure
      FileUtils.rm_f('consistency_test.log')
    end

    # All should return the same value
    assert_equal 'third', result_no_debug,
                 'Should return last item with debug disabled'
    assert_equal 'third', result_debug_no_log,
                 'Should return last item with debug enabled, no log'
    assert_equal 'third', result_debug_with_log,
                 'Should return last item with debug enabled, with log'
    assert_equal result_no_debug, result_debug_no_log,
                 'Results should be consistent across debug states'
    assert_equal result_no_debug, result_debug_with_log,
                 'Results should be consistent across log file states'
  end
end
