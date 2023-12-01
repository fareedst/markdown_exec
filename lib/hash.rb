#!/usr/bin/env ruby
# frozen_string_literal: true

# encoding=utf-8

# hash with keys sorted by name
# add Hash.sym_keys
#
class Hash
  unless defined?(sort_by_key)
    def sort_by_key
      keys.sort.to_h { |key| [key, self[key]] }
    end
  end

  unless defined?(sym_keys)
    def sym_keys
      transform_keys(&:to_sym)
    end
  end
end
