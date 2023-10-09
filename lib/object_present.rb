#!/usr/bin/env ruby
# frozen_string_literal: true

# encoding=utf-8

# version 2023-10-02

class FalseClass
  unless defined?(blank?)
    def present?
      true
    end
  end
end

# is the value empty?
#
class String
  unless defined?(blank?)
    def blank?
      empty? || /\A[[:space:]]*\z/.freeze.match?(self)
    end
  end
end

# is the value non-empty?
#
class String
  unless defined?(present?)
    def present?
      !empty?
    end
  end
end

# is the value a non-empty string or a binary?
#
# :reek:ManualDispatch ### temp
class Object
  unless defined?(present?)
    def present?
      case self.class.to_s
      when 'FalseClass', 'TrueClass'
        true
      else
        self && (!respond_to?(:blank?) || !blank?)
      end
    end
  end
end

if $PROGRAM_NAME == __FILE__
  require 'minitest/autorun'

  class TestStringMethods < Minitest::Test
    def test_blank
      assert ''.blank?
      assert ' '.blank?
      assert "\t\n\r".blank?
      refute 'foo'.blank?
    end

    def test_present
      assert 'foo'.present?
      refute ''.present?
    end
  end

  class TestObjectMethods < Minitest::Test
    def test_present
      assert 'foo'.present?
      refute ''.present?
      assert Object.new.present?
      assert 123.present?
      assert true.present?
      assert false.present?
      refute nil.present?
    end
  end
end
