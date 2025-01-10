# frozen_string_literal: true

# encoding=utf-8
require 'pp'
require 'stringio'

LOG_LEVELS = %i[debug info warn error fatal]

$debug = $DEBUG || !ENV['WW'].nil?

# attribution in output unless disabled
if $debug && ENV['WW_MINIMUM'].nil?
  warn "WW Debugging per $DEBUG ('ruby --debug')" if $DEBUG
  warn 'WW Debugging per environment variable WW' unless ENV['WW'].nil?
end

def ww(*objs, **kwargs)
  return unless $debug

  ww0(*objs, **kwargs.merge(locations: caller_locations))
end

def ww0(*objs,
        category: nil,
        full_backtrace: false,
        level: :debug,
        locations: caller_locations[1..-1],
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
  formatted_message = if single_line
                        io = StringIO.new
                        PP.singleline_pp(trace, io)
                        "#{header} #{io.string}"
                      else
                        io = StringIO.new
                        PP.pp(trace, io)
                        "#{header}\n#{io.string}"
                      end

  # Output to $stderr or specified IO object
  output.puts formatted_message
  output.flush

  # Optionally log to a file
  return unless log_file

  File.open(log_file, 'a') do |file|
    file.puts(formatted_message)
  end
end

class Array
  unless defined?(deref)
    def deref
      map(&:deref).select do |line|
        !%r{^/vendor/}.match(line)
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
