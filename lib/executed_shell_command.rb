#!/usr/bin/env -S bundle exec ruby
# frozen_string_literal: true

# encoding=utf-8

require 'open3'

##
# ExecutedShellCommand wraps the execution of a shell command and captures:
#
# * The original command string
# * STDOUT and STDERR
# * Exit status (Process::Status and numeric exit code)
# * Success / failure convenience predicates
# * Start and finish timestamps and derived duration
# * PID of the spawned process
# * Optional environment and working directory
#
# The command is executed automatically during initialization. The result
# is memoized and can be accessed immediately. Subsequent calls to `run`
# will re-execute by default (force: true), unless `force: false` is
# explicitly passed to use the memoized result.
#
# Basic usage:
#
#   cmd = ExecutedShellCommand.new("ls -l /tmp")  # executes immediately
#   result = cmd.result                            # access memoized result
#   fresh  = cmd.run                              # re-executes (force: true by default)
#   cached = cmd.run(force: false)                # returns memoized result
#
class ExecutedShellCommand
  ##
  # Immutable value object representing the outcome of a command execution.
  #
  Result = Struct.new(
    :command,
    :stdout,
    :stderr,
    :status,
    :started_at,
    :finished_at,
    :pid,
    :env,
    :chdir,
    keyword_init: true
  ) do
    def success?
      status&.success?
    end

    def exit_code
      status&.exitstatus
    end

    def duration
      return nil unless started_at && finished_at

      finished_at - started_at
    end

    def signaled?
      status&.signaled?
    end

    def termsig
      status&.termsig
    end

    def to_h
      {
        command: command,
        stdout: stdout,
        stderr: stderr,
        exit_code: exit_code,
        success: success?,
        started_at: started_at,
        finished_at: finished_at,
        duration: duration,
        pid: pid,
        env: env,
        chdir: chdir,
        status: status
      }
    end
  end

  attr_reader :command, :env, :chdir, :result

  def initialize(command, chdir: nil, env: {})
    @command = command
    @chdir   = chdir
    @env     = env
    @result  = nil
    run # Execute command immediately during initialization
  end

  ##
  # Execute the command, capture all outputs, and return a Result.
  #
  # By default (force: true), the command is executed again and the
  # memoized Result is replaced.
  #
  # If `force: false` is passed and a result already exists, the
  # memoized Result is returned without re-executing.
  #
  def run(force: true)
    return @result if @result && !force

    raise ArgumentError, 'command cannot be nil' if command.nil?

    started_at  = Time.now
    stdout_str  = +''
    stderr_str  = +''
    status      = nil
    pid         = nil

    popen_args = env.empty? ? [command] : [env, command]
    popen_opts = chdir ? { chdir: chdir } : {}

    Open3.popen3(*popen_args, popen_opts) do |stdin, stdout, stderr, wait_thr|
      stdin.close
      stdout_str = stdout.read
      stderr_str = stderr.read
      pid        = wait_thr.pid
      status     = wait_thr.value
    end

    finished_at = Time.now

    @result = Result.new(
      command: command,
      stdout: stdout_str,
      stderr: stderr_str,
      status: status,
      started_at: started_at,
      finished_at: finished_at,
      pid: pid,
      env: env,
      chdir: chdir
    )
  end

  ##
  # Return the memoized result. Since the command runs at initialization,
  # this will always return the memoized result unless run(force: true)
  # was called to update it.
  #
  def fetch_result
    @result
  end

  # Convenience delegators to the last / memoized result:

  def stdout
    fetch_result.stdout
  end

  def stderr
    fetch_result.stderr
  end

  def exit_code
    fetch_result.exit_code
  end

  def success?
    fetch_result.success?
  end

  def failure?
    !fetch_result.success?
  end

  def duration
    fetch_result.duration
  end

  def started_at
    fetch_result.started_at
  end

  def finished_at
    fetch_result.finished_at
  end

  def pid
    fetch_result.pid
  end
end

# Test suite when running as a script
return if $PROGRAM_NAME != __FILE__

require 'bundler/setup'
Bundler.require(:default)

require 'minitest/autorun'
require 'tmpdir'
require 'fileutils'

# [TEST:SHELL_COMMAND] Comprehensive test suite for ExecutedShellCommand class
class ExecutedShellCommandTest < Minitest::Test
  # [TEST:SHELL_COMMAND] Test successful command execution (runs at initialization)
  def test_successful_command_execution
    cmd = ExecutedShellCommand.new("echo 'success'")
    result = cmd.result # Command already executed at initialization

    assert result.success?, 'Command should succeed'
    assert_equal 0, result.exit_code
    assert_equal "success\n", result.stdout
    assert_equal '', result.stderr
    assert_kind_of Process::Status, result.status
    assert result.status.success?
  end

  # [TEST:SHELL_COMMAND] Test failed command execution with exit code (runs at initialization)
  def test_failed_command_execution
    cmd = ExecutedShellCommand.new('exit 3')
    result = cmd.result # Command already executed at initialization

    refute result.success?, 'Command should fail'
    assert_equal 3, result.exit_code
    assert_equal '', result.stdout
    assert_equal '', result.stderr
    assert_kind_of Process::Status, result.status
    refute result.status.success?
  end

  # [TEST:SHELL_COMMAND] Test command with both STDOUT and STDERR (runs at initialization)
  def test_command_with_stdout_and_stderr
    cmd = ExecutedShellCommand.new(
      "echo 'hello from shell' && >&2 echo 'oops' && exit 3"
    )
    result = cmd.result # Command already executed at initialization

    refute result.success?, 'Command should fail'
    assert_equal 3, result.exit_code
    assert_equal "hello from shell\n", result.stdout
    assert_equal "oops\n", result.stderr
  end

  # [TEST:SHELL_COMMAND] Test result memoization - accessing result returns same object
  def test_result_memoization
    cmd = ExecutedShellCommand.new("echo 'test'")
    first = cmd.result # Access memoized result from initialization
    second = cmd.result # Should return same memoized result

    assert_equal first.object_id, second.object_id,
                 'Should return same memoized result object'
    assert_equal first.stdout, second.stdout
    assert_equal first.pid, second.pid
  end

  # [TEST:SHELL_COMMAND] Test run defaults to force: true and creates new result object
  def test_run_defaults_to_force_true
    cmd = ExecutedShellCommand.new("echo 'test'")
    first = cmd.result # Initial execution result
    fresh = cmd.run # Defaults to force: true, so re-executes

    refute_equal first.object_id, fresh.object_id,
                 'Run should create new result object (force: true by default)'
    assert_equal first.stdout, fresh.stdout, 'Output should be the same'
    # PIDs will be different as it's a new process
    refute_equal first.pid, fresh.pid,
                 'PID should be different for new execution'
  end

  # [TEST:SHELL_COMMAND] Test run with force: false returns memoized result
  def test_run_with_force_false_returns_memoized
    cmd = ExecutedShellCommand.new("echo 'test'")
    first = cmd.result # Initial execution result
    cached = cmd.run(force: false) # Should return memoized result

    assert_equal first.object_id, cached.object_id,
                 'Run with force: false should return memoized result'
    assert_equal first.stdout, cached.stdout
    assert_equal first.pid, cached.pid
  end

  # [TEST:SHELL_COMMAND] Test fetch_result returns memoized result
  def test_fetch_result_returns_memoized
    cmd = ExecutedShellCommand.new("echo 'test'")
    first = cmd.result # Initial execution result
    fetched = cmd.fetch_result

    assert_equal first.object_id, fetched.object_id,
                 'fetch_result should return memoized result'
  end

  # [TEST:SHELL_COMMAND] Test convenience delegator methods (command runs at initialization)
  def test_convenience_delegators
    cmd = ExecutedShellCommand.new(
      "echo 'output' && >&2 echo 'error' && exit 5"
    )
    # Command already executed at initialization, delegators access memoized result

    assert_equal "output\n", cmd.stdout
    assert_equal "error\n", cmd.stderr
    assert_equal 5, cmd.exit_code
    refute cmd.success?
    assert_kind_of Numeric, cmd.duration
    assert_kind_of Time, cmd.started_at
    assert_kind_of Time, cmd.finished_at
    assert_kind_of Integer, cmd.pid
  end

  # [TEST:SHELL_COMMAND] Test PID capture (command runs at initialization)
  def test_pid_capture
    cmd = ExecutedShellCommand.new("echo 'test'")
    result = cmd.result # Command already executed at initialization

    assert_kind_of Integer, result.pid
    assert result.pid.positive?, 'PID should be positive'
  end

  # [TEST:SHELL_COMMAND] Test duration calculation (command runs at initialization)
  def test_duration_calculation
    cmd = ExecutedShellCommand.new('sleep 0.1')
    result = cmd.result # Command already executed at initialization

    assert_kind_of Numeric, result.duration
    assert result.duration >= 0.1, 'Duration should be at least 0.1 seconds'
    assert result.duration < 1.0, 'Duration should be less than 1 second'
    assert result.started_at < result.finished_at,
           'Started at should be before finished at'
  end

  # [TEST:SHELL_COMMAND] Test timestamps (command runs at initialization)
  def test_timestamps
    before = Time.now
    cmd = ExecutedShellCommand.new("echo 'test'")
    after = Time.now
    result = cmd.result # Command already executed at initialization

    assert result.started_at >= before,
           'Started at should be after test start'
    assert result.finished_at <= after,
           'Finished at should be before test end'
    assert result.started_at <= result.finished_at,
           'Started at should be before finished at'
  end

  # [TEST:SHELL_COMMAND] Test environment variable passing (command runs at initialization)
  def test_environment_variables
    env = { 'TEST_VAR' => 'test_value', 'ANOTHER_VAR' => 'another_value' }
    cmd = ExecutedShellCommand.new('echo $TEST_VAR && echo $ANOTHER_VAR',
                                   env: env)
    result = cmd.result # Command already executed at initialization

    assert result.success?
    assert_includes result.stdout, 'test_value'
    assert_includes result.stdout, 'another_value'
    assert_equal env, result.env
  end

  # [TEST:SHELL_COMMAND] Test working directory change (command runs at initialization)
  def test_working_directory_change
    Dir.mktmpdir do |tmpdir|
      test_file = File.join(tmpdir, 'test.txt')
      File.write(test_file, 'test content')

      cmd = ExecutedShellCommand.new('cat test.txt', chdir: tmpdir)
      result = cmd.result # Command already executed at initialization

      assert result.success?
      assert_equal 'test content', result.stdout
      assert_equal tmpdir, result.chdir
    end
  end

  # [TEST:SHELL_COMMAND] Test command attribute
  def test_command_attribute
    command_str = "echo 'test'"
    cmd = ExecutedShellCommand.new(command_str)

    assert_equal command_str, cmd.command
  end

  # [TEST:SHELL_COMMAND] Test nil command raises ArgumentError at initialization
  def test_nil_command_raises_error
    assert_raises(ArgumentError, 'command cannot be nil') do
      ExecutedShellCommand.new(nil) # Error raised during initialization when run is called
    end
  end

  # [TEST:SHELL_COMMAND] Test Result#to_h method (command runs at initialization)
  def test_result_to_h
    cmd = ExecutedShellCommand.new("echo 'test'")
    result = cmd.result # Command already executed at initialization
    hash = result.to_h

    assert_kind_of Hash, hash
    assert_equal cmd.command, hash[:command]
    assert_equal result.stdout, hash[:stdout]
    assert_equal result.stderr, hash[:stderr]
    assert_equal result.exit_code, hash[:exit_code]
    assert_equal result.success?, hash[:success]
    assert_equal result.started_at, hash[:started_at]
    assert_equal result.finished_at, hash[:finished_at]
    assert_equal result.duration, hash[:duration]
    assert_equal result.pid, hash[:pid]
    assert_equal result.env, hash[:env]
    assert_equal result.chdir, hash[:chdir]
    assert_equal result.status, hash[:status]
  end

  # [TEST:SHELL_COMMAND] Test Result#signaled? method (command runs at initialization)
  def test_result_signaled
    cmd = ExecutedShellCommand.new("echo 'test'")
    result = cmd.result # Command already executed at initialization

    # Normal exit should not be signaled
    refute result.signaled?
  end

  # [TEST:SHELL_COMMAND] Test Result#termsig method (command runs at initialization)
  def test_result_termsig
    cmd = ExecutedShellCommand.new("echo 'test'")
    result = cmd.result # Command already executed at initialization

    # Normal exit should have nil termsig
    assert_nil result.termsig, 'Normal exit should have nil termsig'
  end

  # [TEST:SHELL_COMMAND] Test empty environment hash (command runs at initialization)
  def test_empty_environment_hash
    cmd = ExecutedShellCommand.new("echo 'test'", env: {})
    result = cmd.result # Command already executed at initialization

    assert result.success?
    assert_equal({}, result.env)
  end

  # [TEST:SHELL_COMMAND] Test command with complex shell syntax (command runs at initialization)
  def test_complex_shell_command
    cmd = ExecutedShellCommand.new(
      "echo 'line1' && echo 'line2' && echo 'line3'"
    )
    result = cmd.result # Command already executed at initialization

    assert result.success?
    assert_includes result.stdout, 'line1'
    assert_includes result.stdout, 'line2'
    assert_includes result.stdout, 'line3'
  end

  # [TEST:SHELL_COMMAND] Test command with no output (command runs at initialization)
  def test_command_with_no_output
    cmd = ExecutedShellCommand.new('true')
    result = cmd.result # Command already executed at initialization

    assert result.success?
    assert_equal 0, result.exit_code
    assert_equal '', result.stdout
    assert_equal '', result.stderr
  end

  # [TEST:SHELL_COMMAND] Test multiple runs (default force: true creates new results)
  def test_multiple_runs_create_new_results
    cmd = ExecutedShellCommand.new("echo 'test'")
    first = cmd.result # Initial execution result
    second = cmd.run # Defaults to force: true, creates new result
    third = cmd.run # Defaults to force: true, creates new result

    refute_equal first.object_id, second.object_id,
                 'Each run creates new result'
    refute_equal second.object_id, third.object_id,
                 'Each run creates new result'
    # All should have same output
    assert_equal first.stdout, second.stdout
    assert_equal second.stdout, third.stdout
  end

  # [TEST:SHELL_COMMAND] Test command with newlines in output (command runs at initialization)
  def test_command_with_newlines
    cmd = ExecutedShellCommand.new("echo -e 'line1\nline2\nline3'")
    result = cmd.result # Command already executed at initialization

    assert result.success?
    assert_includes result.stdout, 'line1'
    assert_includes result.stdout, 'line2'
    assert_includes result.stdout, 'line3'
  end

  # [TEST:SHELL_COMMAND] Test command attribute is immutable (command runs at initialization)
  def test_command_immutability
    original_command = "echo 'original'"
    cmd = ExecutedShellCommand.new(original_command)

    # Command should remain unchanged
    assert_equal original_command, cmd.command
    result = cmd.result # Command already executed at initialization
    assert_equal original_command, cmd.command
    assert_equal original_command, result.command
  end

  # [TEST:SHELL_COMMAND] Test command executes automatically at initialization
  def test_command_executes_at_initialization
    before = Time.now
    cmd = ExecutedShellCommand.new("echo 'auto-executed'")
    after = Time.now

    # Result should be available immediately without calling run
    refute_nil cmd.result,
               'Result should be available immediately after initialization'
    assert_equal "auto-executed\n", cmd.result.stdout
    assert cmd.result.started_at >= before,
           'Command should have started during initialization'
    assert cmd.result.finished_at <= after,
           'Command should have finished during initialization'
  end
end
