# frozen_string_literal: true

# encoding=utf-8
require 'bundler/setup' # Bundler enforces gem versions
require 'pp'
require 'stringio'

LOG_LEVELS = %i[debug info warn error fatal].freeze

$debug = $DEBUG || !ENV['WW'].nil?

# attribution in output unless disabled
if $debug && ENV['WW_MINIMUM'].nil?
  warn "WW Debugging per $DEBUG ('ruby --debug')" if $DEBUG
  warn 'WW Debugging per environment variable WW' unless ENV['WW'].nil?
end

def ww(*objs, **kwargs)
  # return the last item in the list, as the label is usually first
  return objs.last unless $debug

  ww0(*objs, **kwargs.merge(locations: caller_locations))
end

# select enabled, for exceptions
# print a data object for the error, and the failing line
def wwe(*objs, **kwargs)
  ww0(*objs, **kwargs.merge(locations: caller_locations[0..0]))

  raise StandardError, objs.first[:error]
end

# selectively enabled, for process tracking
# print the failing line
def wwp(*objs, **kwargs)
  ww(*objs, **kwargs.merge(locations: caller_locations[0..0]))
end

# selectively enabled, for tagged
# print the failing line
# eg wwt :line, 'data:', data
def wwt(*objs, **kwargs)
  # return if [:line].include? objs.first

  formatted = ['Tagged', objs.first] + objs[1..]
  ww(*formatted, **kwargs.merge(locations: caller_locations[0..0]))
end

def ww0(*objs,
        category: nil,
        full_backtrace: false,
        level: :debug,
        locations: caller_locations,
        log_file: nil,
        output: $stderr,
        single_line: false,
        timestamp: false)
  # Format caller information line
  def caller_info_line(caller_info)
    "#{caller_info.lineno} : #{caller_info.path.sub(%r{^#{Dir.pwd}},
                                                    '')} : #{caller_info.label}"
  end
  # Validate log level
  raise ArgumentError,
        "Invalid log level: #{level}" unless LOG_LEVELS.include?(level)

  # Generate backtrace
  backtrace = if full_backtrace
                locations.map { |caller_info| caller_info_line(caller_info) }
              else
                [caller_info_line(locations.first)]
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
  output.puts formatted_message
  output.flush

  # Optionally log to a file
  return objs.size == 1 ? objs.first : objs unless log_file

  File.open(log_file, 'a') do |file|
    file.puts(formatted_message)
  end

  def wwb
    binding.irb if $debug
  end

  # return the last item in the list, as the label is usually first
  objs.last
end

class Array
  unless defined?(deref)
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
    def deref
      sub(%r{^#{Dir.pwd}}, '')
    end
  end
end
