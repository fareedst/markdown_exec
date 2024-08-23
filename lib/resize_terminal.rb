#!/usr/bin/env bundle exec ruby
# frozen_string_literal: true

# encoding=utf-8
require 'io/console'
require 'timeout'

# This function attempts to resize the terminal to its maximum supported size.
# It checks if the script is running in an interactive terminal with no arguments.
# If so, it sends escape sequences to query the terminal size and reads the response.
# It then compares the current terminal size with the calculated size and adjusts if necessary.
# If the terminal emulator is unsupported, it prints an error message.
# 2024-8-23 add require_stdout to allow for testing
def resize_terminal(show_dims: false, show_rectangle: false,
                    require_stdout: true)
  # Check if running in an interactive terminal and no arguments are provided
  unless $stdin.tty?
    warn 'Usage: resize_terminal'
    return
  end

  return if require_stdout && !$stdout.tty?

  # Save the current state and send the escape sequence to get the cursor position
  print "\e7\e[r\e[999;999H\e[6n\e8"
  $stdout.flush

  # Read the response from the terminal
  response = String.new
  Timeout.timeout(5) do
    loop do
      char = $stdin.getch
      response << char
      break if response.include?('R')
    end
  end

  if response.empty?
    warn "Error: No response received from terminal. Response: #{response.inspect}"
    return 1
  end

  # Match the response to extract the terminal dimensions
  match_data = response.match(/\[(\d+);(\d+)R/)
  unless match_data
    warn "Error: Failed to match terminal response pattern. Response: #{response.inspect}"
    return 1
  end

  calculated_rows, calculated_columns = match_data.captures.map(&:to_i)

  if ENV['COLUMNS'].to_i == calculated_columns && ENV['LINES'].to_i == calculated_rows
    puts "#{ENV.fetch('TERM', nil)} #{calculated_columns}x#{calculated_rows}"
  elsif calculated_columns.positive? && calculated_rows.positive?
    warn "#{ENV.fetch('COLUMNS',
                      nil)}x#{ENV.fetch('LINES',
                                        nil)} -> #{calculated_columns}x#{calculated_rows}" if show_dims
    system("stty cols #{calculated_columns} rows #{calculated_rows}")
  else
    warn "Error: Calculated terminal size is invalid. Columns: #{calculated_columns}, Rows: #{calculated_rows}"
    return 1
  end

  # Display a text rectangle if the option is enabled
  display_terminal_rectangle(calculated_columns,
                             calculated_rows) if show_rectangle
rescue Timeout::Error
  warn 'Error: Timeout while reading terminal response. Unsupported terminal emulator.'
  1
rescue StandardError => err
  warn "Error: #{err.message}. Unsupported terminal emulator."
  1
end

# This function draws a rectangle of the given width and height
# with stars on the edges and empty space inside.
def display_terminal_rectangle(width, height)
  puts '*' * width
  (height - 2).times { puts "*#{' ' * (width - 2)}*" }
  puts '*' * width
end

# resize_terminal(show_rectangle: true) if __FILE__ == $PROGRAM_NAME
return if __FILE__ != $PROGRAM_NAME

require 'minitest/autorun'

class ResizeTerminalTest < Minitest::Test
  def setup
    # Backup original ARGV and environment variables
    @original_argv = ARGV.dup
    @original_columns = ENV.fetch('COLUMNS', nil)
    @original_lines = ENV.fetch('LINES', nil)
  end

  def teardown
    # Restore original ARGV and environment variables
    ARGV.replace(@original_argv)
    ENV['COLUMNS'] = @original_columns
    ENV['LINES'] = @original_lines
  end

  # def test_resize_terminal_successful
  #   # Simulate interactive terminal
  #   $stdin.stub(:tty?, true) do
  #     ARGV.replace([])
  #     ENV['COLUMNS'] = '80'
  #     ENV['LINES'] = '24'
  #     response = "\e[999;999H\e[6n\e[24;80R"
  #     $stdin.stub(:getch, -> { response.slice!(0) || '' }) do
  #       assert_output(nil, /24x80/) do
  #         resize_terminal
  #       end
  #     end
  #   end
  # end
  def test_resize_terminal_successful
    # Simulate interactive terminal
    $stdin.stub(:tty?, true) do
      ARGV.replace([])
      columns = 40 + (2 * rand(10))
      ENV['COLUMNS'] = columns.to_s
      ENV['LINES'] = '24'
      response = "\e[999;999H\e[6n\e[24;#{columns}R".dup
      $stdin.stub(:getch, -> { response.slice!(0) || '' }) do
        assert_output("\e7\e[r\e[999;999H\e[6n\e8xterm-256color #{columns}x24\n") do
          # assert_output('', '') do
          resize_terminal(require_stdout: false)
        end
      end
    end
  end

  def test_resize_terminal_no_response
    # Simulate interactive terminal with no response
    $stdin.stub(:tty?, true) do
      ARGV.replace([])
      $stdin.stub(:getch, -> { '' }) do
        # assert_output(nil, /Error: No response received from terminal/) do
        assert_output(nil,
                      "Error: Timeout while reading terminal response. Unsupported terminal emulator.\n") do
          assert_equal 1, resize_terminal(require_stdout: false)
        end
      end
    end
  end

  def test_resize_terminal_invalid_response
    # Simulate interactive terminal with invalid response
    $stdin.stub(:tty?, true) do
      ARGV.replace([])
      response = "\e[999;999H\e[6n\e[InvalidResponse".dup
      $stdin.stub(:getch, -> { response.slice!(0) || '' }) do
        assert_output(nil,
                      /Error: Failed to match terminal response pattern/) do
          assert_equal 1, resize_terminal(require_stdout: false)
        end
      end
    end
  end

  def test_resize_terminal_timeout
    # Simulate interactive terminal with timeout
    $stdin.stub(:tty?, true) do
      ARGV.replace([])
      Timeout.stub(:timeout, ->(_) { raise Timeout::Error }) do
        assert_output(nil, /Error: Timeout while reading terminal response/) do
          assert_equal 1, resize_terminal(require_stdout: false)
        end
      end
    end
  end

  def test_resize_terminal_non_interactive
    # Simulate non-interactive terminal
    $stdin.stub(:tty?, false) do
      assert_output(nil, /Usage: resize_terminal/) do
        resize_terminal
      end
    end
  end

  #   def test_resize_terminal_display_rectangle
  #     # Simulate interactive terminal with rectangle display
  #     $stdin.stub(:tty?, true) do
  #       ARGV.replace([])
  #       ENV['COLUMNS'] = '80'
  #       ENV['LINES'] = '24'
  #       response = "\e[999;999H\e[6n\e[24;80R".dup
  #       $stdin.stub(:getch, -> { response.slice!(0) || '' }) do
  #         expected_output = "\e7\e[r\e[999;999H\e[6n\e8"
  # #         expected_output = <<-RECTANGLE
  # # ********************************************************************************
  # # *                                                                              *
  # # *                                                                              *
  # # *                                                                              *
  # # *                                                                              *
  # # *                                                                              *
  # # *                                                                              *
  # # *                                                                              *
  # # *                                                                              *
  # # *                                                                              *
  # # *                                                                              *
  # # *                                                                              *
  # # *                                                                              *
  # # *                                                                              *
  # # *                                                                              *
  # # *                                                                              *
  # # *                                                                              *
  # # *                                                                              *
  # # *                                                                              *
  # # *                                                                              *
  # # *                                                                              *
  # # *                                                                              *
  # # ********************************************************************************
  # #         RECTANGLE
  #         assert_output(expected_output.strip) do
  #           resize_terminal(show_rectangle: true)
  #         end
  #       end
  #     end
  #   end
end
