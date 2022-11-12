# frozen_string_literal: true

# encoding=utf-8

require_relative 'tap'

include Tap #; tap_config

# define options with initial values
# option to read value from environmnt variables
# option to cast input values
# value priority: default < environment < argument
#
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
  def add_options(opts_raw)
    return self if opts_raw.nil?

    rows = opts_raw.map do |key, opt_raw|
      key2 = key_name_to_option_name(key)

      # set_per_options(key2, opt_raw)
      @opts[key2] = (opt_raw ||= {})
      set_key_value_as_cast key2, EnvOpts.optdefault(opt_raw)

      set_key_value_per_environment_as_cast(key2, opt_raw)

      [
        [20, '-', "--#{key}"],
        [16, '-', @opts[key2][:env].present? ? option_name_to_environment_name(key2, @opts[key2]) : ''],
        # [24, '-', get_environment_value_from_option(key2, @opts[key2])],
        [24, '-', @opts[key2][:default]],
        [6, '-', if (fixed = opt_raw.fetch(:fixed, nil)).nil?
                   ":#{option_cast(@opts[key2])}"
                 else
                   fixed.to_s
                 end]
      ]
    end.tap_yaml 'rows'

    max_widths = rows.reduce([0, 0, 0, 0]) do |memo, (c0, c1, c2, c3)|
      [
        [memo[0], c0[2].to_s.length].max,
        [memo[1], c1[2].to_s.length].max,
        [memo[2], c2[2].to_s.length].max,
        [memo[3], c3[2].to_s.length].max
      ]
    end.tap_inspect 'max_widths'

    @values['help'] = rows.map do |(c0, c1, c2, c3)|
      [format("%#{c0[1]}#{max_widths[0]}s", c0[2]),
       format("%#{c1[1]}#{max_widths[1]}s", c1[2]),
       format("%#{c2[1]}#{max_widths[2]}s", c2[2]),
       format("%#{c3[1]}#{max_widths[3]}s", c3[2])]
    end.map do |row|
      row.join('  ')
    end.join("\n")
    @opts.tap_inspect '@opts'
    @values.tap_inspect '@values'

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
        args_consumed = consume_arguments(opt_name, argv.fetch(args_ind + 1, nil))
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
    @opts.tap_inspect '@opts'
    @values.tap_inspect '@values'

    self
  end

  # set option current values per environment values
  #
  def set_keys_value_per_environment_as_cast(opts_raw)
    return self if opts_raw.nil?

    opts_raw.each do |key, opt_raw|
      set_key_value_per_environment_as_cast(key_name_to_option_name(key), opt_raw)
    end
    @opts.tap_inspect '@opts'

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
    (opt_raw[:cast].present? ? opt_raw[:cast].to_s : 'to_s').tap_inspect
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
    method_name.tap_inspect 'method_name'
    if method_name.to_s.end_with?('=')
      value = args.first
      name = method_name_to_option_name(method_name.to_s[0..-2])
      set_key_value_as_cast(name, value)
    else
      @values[method_name_to_option_name(method_name)]
    end.tap_inspect "ref #{method_name}", source: 'EnvOpts'
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
    end.tap_inspect
  end

  # get environment value from option
  #
  def get_environment_value_from_option(opt_name, opt_raw)
    ENV.fetch(option_name_to_environment_name(opt_name, opt_raw), nil).tap_inspect
  end

  # option names are available as methods
  #
  def respond_to_missing?(method_name, include_private = false)
    (@opts.keys.include?(method_name_to_option_name(method_name)) || super)
  end

  def set_key_value_as_cast(key, value)
    [key, value].tap_inspect 'key, value'
    opt = @opts[key]
    set_key_value_raw(key, (opt[:cast] ? value.send(opt[:cast]) : value))
  end

  # set key value_per environment as cast
  #
  def set_key_value_per_environment_as_cast(key, opt_raw)
    key.tap_inspect 'key'
    opt_raw.tap_inspect 'opt_raw'
    return if opt_raw[:env].nil?

    value = get_environment_value_from_option(key, opt_raw).tap_inspect 'value'
    set_key_value_as_cast(key, opt_raw[:cast] ? value.send(opt_raw[:cast]) : value) unless value.nil?
  end

  # set key value (raw)
  #
  def set_key_value_raw(key, value)
    [key, value].tap_inspect 'key, value'
    @values[key] = value
  end

  # symbol name to option name
  # option names use hyphens
  #
  def symbol_name_to_option_name(name)
    name.to_s.gsub('_', '-') #.tap_inspect
  end
end
