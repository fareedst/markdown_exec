# frozen_string_literal: true

# encoding=utf-8

require_relative 'tap'

include Tap #; tap_config

# define options with initial values
# option to read value from environmnt variables
# option to cast input values
# value priority: default < environment < argument
#
# :reek:TooManyMethods
class EnvOpts
  attr_reader :opts, :values

  def initialize(opts_raw = {}, argv = ARGV)
    @opts = {}
    @values = {}
    add_options(opts_raw)
    # parse(argv, &block) if block_given?
    block_given? ? parse(argv, &block) : parse(argv)

    self # rubocop:disable Lint/Void
  end

  # add options to menu
  # calculate help text
  #
  # :reek:NestedIterators
  def add_options(opts_raw)
    return self if opts_raw.nil?

    rows = opts_raw.map do |key, opt_raw|
      opt_name = key_name_to_option_name(key)

      # set_per_options(opt_name, opt_raw)
      @opts[opt_name] = (opt_raw ||= {})
      set_key_value_as_cast opt_name, EnvOpts.optdefault(opt_raw)

      set_key_value_per_environment_as_cast(opt_name, opt_raw)

      [
        [20, '-', "--#{key}"],
        [16, '-',
         if @opts[opt_name][:env].present?
           option_name_to_environment_name(opt_name, @opts[opt_name])
         else
           ''
         end],
        # [24, '-', get_environment_value_from_option(opt_name, @opts[opt_name])],
        [24, '-', @opts[opt_name][:default]],
        [6, '-', if (fixed = opt_raw.fetch(:fixed, nil)).nil?
                   ":#{option_cast(@opts[opt_name])}"
                 else
                   fixed.to_s
                 end]
      ]
    end

    max_widths = rows.reduce([0, 0, 0, 0]) do |memo, vals|
      vals.map.with_index do |val, ind|
        [memo[ind], val[2].to_s.length].max
      end
    end

    @values['help'] = rows.map do |row|
      row.map.with_index do |cell, ind|
        format("%#{cell[1]}#{max_widths[ind]}s", cell[2])
      end.join('  ')
    end.join("\n")

    self
  end

  # accept :d or :default option
  #
  def self.optdefault(opt_raw)
    return opt_raw[:d] unless opt_raw[:d].nil?

    opt_raw[:default]
  end

  def output_help
    puts @values['help']
  end

  # process arguments as mostly pairs of option name and value
  #
  def parse(argv = ARGV)
    return self if argv.nil? || !(argv&.count || 0).positive?

    args_ind = 0
    while args_ind < argv.count
      args_consumed = 0
      arg = argv.fetch(args_ind, '') #.tap_inspect 'argument', source: 'EnvOpts'
      if arg.start_with? '--'
        opt_name = arg[2..-1] #.tap_inspect 'opt_name', source: 'EnvOpts'
        args_consumed = consume_arguments(opt_name,
                                          argv.fetch(args_ind + 1, nil))
      end

      if args_consumed.zero?
        if arg == '--help'
          output_help
          exit
        elsif block_given?
          yield 'NAO', [arg]
          args_consumed = 1
        else
          warn "Invalid argument: #{arg.inspect} in #{argv.inspect}"
          exit 1
        end
      end

      args_ind += args_consumed
    end

    self
  end

  # set option current values per environment values
  #
  def options_per_environment_as_cast(opts_raw)
    return self if opts_raw.nil?

    opts_raw.each do |key, opt_raw|
      set_key_value_per_environment_as_cast(key_name_to_option_name(key),
                                            opt_raw)
    end

    self
  end

  private

  # convert key name or symbol to an option name
  #
  def key_name_to_option_name(key)
    (key.is_a?(Symbol) ? symbol_name_to_option_name(key) : key) #.tap_inspect
  end

  # get cast of environment variable
  #
  def option_cast(opt_raw)
    (opt_raw[:cast].present? ? opt_raw[:cast].to_s : 'to_s')
  end

  # update value for named option
  # return number of arguments used
  #
  def consume_arguments(opt_name, value)
    return 0 if (opt_raw = @opts.fetch(opt_name, nil)).nil?

    return 0 unless opt_raw.fetch(:option, true)

    if !(fixed = opt_raw.fetch(:fixed, nil)).nil?
      set_key_value_as_cast(opt_name, fixed)
      1
    elsif value.nil?
      0
    else
      set_key_value_as_cast(opt_name, value)
      2
    end
  end

  # option names use hyphens
  #
  def method_name_to_option_name(name)
    name.to_s.gsub('_', '-') #.tap_inspect
  end

  # read and write options using the option name as a method
  #
  def method_missing(method_name, *args)
    if method_name.to_s.end_with?('=')
      value = args.first
      name = method_name_to_option_name(method_name.to_s[0..-2])
      set_key_value_as_cast(name, value)
    else
      @values[method_name_to_option_name(method_name)]
    end #.tap_inspect "ref #{method_name}", source: 'EnvOpts'
  end

  # option name to environment name
  # if true or empty, compute from option name
  #
  def option_name_to_environment_name(opt_name, opt_raw)
    case env_name = opt_raw.fetch(:env, '')
    when true, ''
      "#{@values['env-prefix']}#{opt_name.upcase.gsub('-', '_')}"
    else
      env_name
    end
  end

  # get environment value from option
  #
  def get_environment_value_from_option(opt_name, opt_raw)
    ENV.fetch(option_name_to_environment_name(opt_name, opt_raw),
              nil)
  end

  # option names are available as methods
  #
  # :reek:BooleanParameter
  def respond_to_missing?(method_name, include_private = false)
    (@opts.keys.include?(method_name_to_option_name(method_name)) || super)
  end

  def set_key_value_as_cast(key, value)
    opt = @opts[key]
    set_key_value_raw(key, (opt[:cast] ? value.send(opt[:cast]) : value))
  end

  # set key value_per environment as cast
  #
  def set_key_value_per_environment_as_cast(key, opt_raw)
    return if opt_raw[:env].nil?

    value = get_environment_value_from_option(key, opt_raw)

    return unless value

    set_key_value_as_cast(key,
                          opt_raw[:cast] ? value.send(opt_raw[:cast]) : value)
  end

  # set key value (raw)
  #
  def set_key_value_raw(key, value)
    @values[key] = value
  end

  # symbol name to option name
  # option names use hyphens
  #
  def symbol_name_to_option_name(name)
    name.to_s.gsub('_', '-') #.tap_inspect
  end
end
