# frozen_string_literal: true

# encoding=utf-8

require 'optparse'
require 'yaml'

require_relative 'object_present'

# add Hash.sym_keys
#
class Hash
  unless defined?(sym_keys)
    def sym_keys
      transform_keys(&:to_sym)
      # map do |key, value|
      #   [key.to_sym, value]
      # end.to_h
    end
  end
end

# parse application configuration from command-line options and environment variables
#
class EnvironmentOptParse
  attr_reader :options, :remainder

  # utility functions to create menu
  #
  module Menu
    def menu_all(menu_data, lambdas, config)
      config.tap_yaml 'config'
      input_option_values, remainder, = menu_parse(add_proc(menu_data, lambdas))
      options = menu_default_option_values(menu_data)
                .merge(config)
                .merge(input_option_values)

      [options, remainder]
    end

    def add_proc(menu_data, lambdas)
      menu_data.each do |menu_item|
        menu_item.tap_yaml 'menu_item'
        procname = menu_item[:procname]
        next if procname.nil?

        menu_item[:proccode] =
          lambdas.fetch(procname.to_sym, menu_item[:procname])
      end.tap_yaml
    end

    def menu_default_option_values(menu_data)
      menu_data.map do |item|
        item_default = item[:default]
        next if item_default.nil?
        next unless item[:opt_name].present?

        [item[:opt_name].to_sym, item_default]
      end.compact.to_h
    end

    def menu_help(menu_data)
      options = {}
      option_parser = OptionParser.new do |opts|
        opts.banner = [
          "#{APP_NAME} - #{APP_DESC} (#{VERSION})",
          "Usage: #{File.basename($PROGRAM_NAME)} [options]"
        ].join("\n")

        menu_data.each do |item|
          menu_option_append opts, options, item
        end
      end

      option_parser.help
    end

    def menu_option_append(opts, options, item)
      return unless item[:long_name].present? || item[:short_name].present?

      mmoo = [
        # long name
        if item[:long_name].present?
          # if "--#{item[:long_name]}#{item[:arg_name]".present?
          #   " #{item[:arg_name]}"
          # else
          #   "''}"
          # end
        end,

        # short name
        item[:short_name].present? ? "-#{item[:short_name]}" : nil,

        # description and default
        [
          item[:description],
          item[:default].present? ? "[#{value_for_menu item[:default]}]" : nil
        ].compact.join('  '),

        # apply proccode, if present, to value
        # save value to options hash if option is named
        #
        lambda { |value|
          (item[:proccode] ? item[:proccode].call(value) : value).tap do |converted|
            opt_name = item[:opt_name]
            next if opt_name.nil?

            options[opt_name.to_sym] = converted if item[:opt_name]
          end
        }
      ].compact
      opts.on(*mmoo)
    end

    def menu_parse(menu_options)
      options = {}
      option_parser = OptionParser.new do |opts|
        menu_options.each do |item|
          item[:opt_name] = item[:opt_name]&.to_sym
          menu_option_append opts, options, item
        end
      end

      # filename defaults to basename of the program
      # without suffix in a directory ~/.options
      option_parser.load
      option_parser.environment # env defaults to the basename of the program.
      remainder = option_parser.parse!

      [options, remainder, option_parser.help]
    end

    # skip :reek:UtilityFunction
    def value_for_menu(value)
      case value.class.to_s
      when 'String'
        value
      when 'FalseClass', 'TrueClass'
        value ? '1' : '0'
      else
        value.to_s
      end
    end
  end

  include Menu

  def initialize(menu: {}, lambdas: nil, options: nil, version: nil)
    @menu = if menu.class.to_s == 'String'
              filetext = File.read(menu).tap_yaml 'filetext'
              fileyaml = YAML.load(filetext)
              fileyaml.map(&:sym_keys)
            else
              menu
            end.tap_yaml '@menu'
    @lambdas = lambdas
    @version = version || '0.1'
    # @options = {}
    @options = if options.class.to_s == 'String'
                 YAML.safe_load(File.read(options)).sym_keys.tap_yaml '@options'
               else
                 {}
               end #.tap_yaml '@options'

    parse!
  end

  def parse!
    @options, @remainder = menu_all(
      @menu,
      # @menu.map do |menu_item|
      #   menu_item.tap_inspect 'menu_item'
      #   mion = menu_item[:opt_name]&.to_sym.tap_inspect 'mion'
      #   omion = @options[mion].tap_inspect 'omion'
      #   unless omion.nil?
      #     @options[menu_item[:default]] = omion
      #   end
      #   menu_item
      # end,
      {
        debug: ->(value) { tap_config value: value },

        # stdout_configuration: lambda { |_| self.options.tap_puts 'eop' },
        # stdout_configuration: (lambda { |options|
        #   lambda { |v| options.tap_puts 'eop_l' }
        # }).call(@options),

        stdout_defaults: lambda { |_|
                           menu_default_option_values(@menu).to_yaml.tap_puts
                         },
        stdout_help: lambda { |_|
                       menu_help(@menu).tap_puts
                       exit
                     },
        val_as_bool: lambda { |value|
                       value.class.to_s == 'String' ? (value.chomp != '0') : value
                     },
        val_as_int: ->(value) { value.to_i },
        val_as_str: ->(value) { value.to_s },
        version: lambda { |_|
                   @version.tap_puts
                   exit
                 }
      }.merge(@lambdas || {}),
      @options
    )
    @options #.tap_yaml '@options'
  end
end
