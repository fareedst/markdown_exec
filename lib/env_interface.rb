# frozen_string_literal: true

require_relative 'ww'

# A class that provides an interface to ENV variables with customizable getters and setters
class EnvInterface
  class << self
    # Get an environment variable with optional transformation
    # @param key [String] The environment variable name
    # @param default [Object] Default value if the variable is not set
    # @param transform [Proc] Optional transformation to apply to the value
    # @return [Object] The environment variable value
    def get(key, default: nil, transform: nil)
      value = ENV.fetch(key, nil)

      if value.nil?
        default
      else
        transform ? transform.call(value) : value
      end.tap do
        wwt :env, key, _1
      end
    end

    # Set an environment variable with optional transformation
    # @param key [String] The environment variable name
    # @param value [Object] The value to set
    # @param transform [Proc] Optional transformation to apply before setting
    # @return [String] The set value
    def set(key, value, transform: nil)
      transformed_value = transform ? transform.call(value) : value
      ENV[key] = transformed_value.to_s.tap do
        wwt :env, key, _1
      end
    end

    # Check if an environment variable exists
    # @param key [String] The environment variable name
    # @return [Boolean] true if the variable exists
    def exists?(key)
      ENV.key?(key)
    end

    # Delete an environment variable
    # @param key [String] The environment variable name
    # @return [String] The deleted value
    def delete(key)
      ENV.delete(key)
    end

    # Get all environment variables
    # @return [Hash] All environment variables
    def all
      ENV.to_h
    end

    # Clear all environment variables
    # @return [void]
    def clear
      ENV.clear
    end
  end
end
