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
def enable_debugging
  ENV.fetch('WW', '0').to_i.positive?
end

# is enabled, not silent
def env_show_attribution
  ENV['WW'] != '0'
end

def is_new_alg?
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

# output the formatted data and location
def ww0(*objs,
        category: $ww_category,
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

  # Add log level and category prefix
  level_prefix = "[#{level.to_s.upcase}]"
  category_prefix = category ? "[#{category}] " : ''

  # Combine all parts into the final message
  header = "#{time_prefix}#{level_prefix} #{category_prefix}"
  trace = backtrace + objs
  io = StringIO.new
  formatted_message = if single_line
                        PP.singleline_pp(trace, io)
                        "#{header} #{io.string}"
                      else
                        PP.pp(trace, io)
                        "#{header}\n#{io.string}"
                      end

  # Output to $stderr or specified IO object
  output.puts "\033[38;2;128;191;191m#{formatted_message}\033[0m"
  output.flush

  # Optionally log to a file
  return objs.size == 1 ? objs.first : objs unless log_file

  File.open(log_file, 'a') do |file|
    file.puts(formatted_message)
  end

  # return the last item in the list, as the label is usually first
  objs.last
end

# break into the debugger if enabled
def wwb
  binding.irb if $debug
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

    partition { |item| item.respond_to?(method) && item.send(method) == value }
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

      reject { |item| item.respond_to?(method) && item.send(method) == value }
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

      select { |item| item.respond_to?(method) && item.send(method) == value }
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
