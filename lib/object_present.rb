# frozen_string_literal: true

# encoding=utf-8

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
