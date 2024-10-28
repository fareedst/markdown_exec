# frozen_string_literal: true

# encoding=utf-8
require_relative 'constants'
require_relative 'object_present'

def process_arguments(arguments, loose_args, options_parsed)
  # !!t arguments, loose_args, options_parsed
  # loose_args will be empty first command contains pass-through arguments
  while loose_args.any?
    if arguments.first == loose_args.first
      yield ArgPro::ArgIsPosition, arguments.shift

      loose_args.shift
      next
    end

    yield ArgPro::ArgIsOption, options_parsed.first

    arguments.shift(options_parsed.first[:procname].present? ? 2 : 1)
    options_parsed.shift
  end
end

def process_commands(options_parsed:, arguments:, enable_search:,
                     named_procs:, rest:)
  # !!t arguments,options_parsed
  command_processed = false
  block_executed = false
  requested_menu = false
  position = 0

  process_arguments(arguments.dup, rest.dup,
                    options_parsed.dup) do |type, item|
    # !!t type,item
    case type
    when ArgPro::ArgIsOption
      if named_procs.include?(item[:name])
        command_processed = true
        yield ArgPro::CallProcess, item[:name]
      else
        converted = if item[:proccode]
                      yield ArgPro::ConvertValue, [item[:proccode],
                                                   item[:value]]
                    else
                      item[:value]
                    end
        if item[:name]
          yield ArgPro::ActSetOption, [item[:name], converted]
        end
      end
    when ArgPro::ArgIsPosition
      case position
      when 0
        # position 0: file, folder, or search term (optional)
        if Dir.exist?(item)
          yield ArgPro::ActSetPath, item
        elsif File.exist?(item)
          yield ArgPro::ActSetFileName, item
        elsif enable_search
          yield ArgPro::ActFind, item
        else
          yield ArgPro::ActFileIsMissing, item
        end
      else
        # position 1: block (optional)
        if item == '.'
          requested_menu = true
        else
          block_executed = true
          yield ArgPro::ActSetBlockName, item
        end
      end
      position += 1
      rest.shift
    else
      raise
    end
  end
end

return if $PROGRAM_NAME != __FILE__

require 'minitest/autorun'

class ArgumentProcessorTest < Minitest::Test
  def setup
    @arguments = ['fixtures/sample1.md', 'block', '--option', 'value',
                  'ignored']
    @rest = ['fixtures/sample1.md', 'block', 'ignored']
    @options_parsed = [{ name: '--option', procname: 'VAL', value: 'value' }]
  end

  def test_process_arguments_with_position
    result = []
    process_arguments(@arguments,
                      @rest, @options_parsed) do |type, item|
      result << [type, item]
    end

    expected = [
      [ArgPro::ArgIsPosition, 'fixtures/sample1.md'],
      [ArgPro::ArgIsPosition, 'block'],
      [ArgPro::ArgIsOption, { name: '--option', procname: 'VAL', value: 'value' }],
      [ArgPro::ArgIsPosition, 'ignored']
    ]
    assert_equal expected, result
  end
end

class CommandProcessorTest < Minitest::Test
  def setup
    @exisiting_file_name = Dir.glob('fixtures/*').first
    @missing_file_name = 'missing-file.tmp'
    @arguments = [@exisiting_file_name, 'process', '--option', 'value',
                  'ignored']
    @named_procs = []
    @options_parsed = [{ name: '--option', procname: 'VAL', value: 'value' }]
    @rest = [@exisiting_file_name, 'process', 'ignored']
    @enable_search = true
  end

  def test_process_commands_with_valid_file
    result = []
    process_commands(
      arguments: @arguments, named_procs: @named_procs,
      options_parsed: @options_parsed,
      rest: @rest, enable_search: @enable_search
    ) do |type, item|
      result << [type, item]
    end

    expected = [
      [ArgPro::ActSetFileName, @exisiting_file_name],
      [ArgPro::ActSetBlockName, 'process'],
      [ArgPro::ActSetOption, ['--option', 'value']],
      [ArgPro::ActSetBlockName, 'ignored']
    ]

    assert_equal expected, result
  end

  def test_process_commands_with_search
    result = []
    process_commands(arguments: [@missing_file_name, 'process'],
                     named_procs: @named_procs,
                     options_parsed: [],
                     rest: [@missing_file_name, 'process'],
                     enable_search: @enable_search) do |type, item|
      result << [type, item]
    end

    expected = [
      [ArgPro::ActFind, @missing_file_name],
      [ArgPro::ActSetBlockName, 'process']
    ]

    assert_equal expected, result
  end
end
