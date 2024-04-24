#!/usr/bin/env -S bundle exec ruby
# frozen_string_literal: true

# encoding=utf-8
require 'logger'

# Logger::LogDevice is used by Logger, the parent class of StdOutErrLogger
class Logger::LogDevice
  # remove header
  def add_log_header(file); end
end

# Custom logger to direct info to stdout and warn and above to stderr
#
class StdOutErrLogger < Logger
  attr_reader :file

  # def initialize(file = nil)
  def initialize(file = "#{__dir__}/../tmp/hash_delegator_next_link_state.yaml")
    @file = file
    super(file || $stdout)
    self.formatter = proc do |_severity, _datetime, _progname, msg|
      "#{msg}\n"
    end
  end

  def add(severity, message = nil, progname = nil, &block)
    message = (message || block&.call || progname) if message.nil?
    message = "- #{message.to_json}\n"
    ### message = message.join("\n") if message.is_a? Array
    out = format_message(format_severity(severity), Time.now, progname, message)
    if severity == Logger::UNKNOWN # does not follow spec, outputs to stderr for IO
      # $stderr.puts(out)
      super
    elsif severity >= Logger::WARN
      if @file
        super
      else
        warn(out)
      end
    elsif @file
      super
    else
      $stdout.puts(out)
    end
  end
end

return if $PROGRAM_NAME != __FILE__

require 'minitest/autorun'

class StdOutErrLoggerTest < Minitest::Test
  # Redirect STDOUT and STDERR to capture them for assertions
  def setup
    @original_stdout = $stdout
    @original_stderr = $stderr
    $stdout = StringIO.new
    $stderr = StringIO.new
  end

  def teardown
    $stdout = @original_stdout
    $stderr = @original_stderr
  end

  def test_initialize_without_file
    logger = StdOutErrLogger.new
    assert_nil logger.file
    assert_equal Logger::DEBUG, logger.level
  end

  def test_initialize_with_file
    Tempfile.open do |file|
      logger = StdOutErrLogger.new(file.path)
      assert_equal file.path, logger.file
    end
  end

  def test_logging_info
    logger = StdOutErrLogger.new
    logger.info('Info message')
    assert_equal "Info message\n", $stdout.string
    assert_empty $stderr.string
  end

  def test_logging_warning
    logger = StdOutErrLogger.new
    logger.warn('Warning message')
    assert_empty $stdout.string
    assert_equal "Warning message\n", $stderr.string
  end

  def test_logging_error
    logger = StdOutErrLogger.new
    logger.error('Error message')
    assert_empty $stdout.string
    assert_equal "Error message\n", $stderr.string
  end

  def test_logging_with_array
    logger = StdOutErrLogger.new
    logger.info(['Message line 1', 'Message line 2'])
    assert_equal "Message line 1\nMessage line 2\n", $stdout.string
  end

  def test_logging_with_block
    logger = StdOutErrLogger.new
    logger.info { 'Block message' }
    assert_equal "Block message\n", $stdout.string
  end

  def test_logging_unknown_severity
    logger = StdOutErrLogger.new
    logger.add(Logger::UNKNOWN, 'Unknown severity message')
    assert_empty $stdout.string
    assert_equal "Unknown severity message\n", $stderr.string
  end
end
