#!/usr/bin/env bundle exec ruby
# frozen_string_literal: true

# encoding=utf-8

$imw_depth = 0
$imw_len = 128

module ImwUx
  def imw_ins(_obj = nil, _name = nil)
    # warn "#{imw_indent}#{name} #{obj.inspect}"
    pfx = '~ '
    fl = ' '
    v = '-' #inst ? '-' : '='
    $imw_depth ||= 0 # Initialize $imw_depth if not already initialized
    "#{fl * $imw_depth}#{pfx}" + "#{v}i#{v}"
  end

  def imw_indent(dir = :in, inst = true)
    pfx = '~ '
    fl = ' '
    inst ? '-' : '='
    $imw_depth ||= 0 # Initialize $imw_depth if not already initialized
    $imw_depth += 1 if dir == :in
    result = "#{fl * $imw_depth}#{pfx}" + (dir == :in ? '> ' : '< ')
    $imw_depth -= 1 if dir == :out
    result
  end
end

module ClassMethodWrapper
  def self.prepended(base)
    base.singleton_class.instance_methods(false).each do |method_name|
      wrap_method(base, method_name)
    end
  end

  def self.wrap_method(base, method_name)
    base.singleton_class.define_method(method_name) do |*args, **kwargs, &block|
      method = base.method(method_name)
      parameters = method.parameters.map(&:last)

      warn format("%s %.#{$imw_len}s",
                  imw_indent(:in, false).to_s,
                  ":i:> #{sbase}::#{method_name}: " +
                  [args == [] ? nil : "args=#{args.inspect}",
                   kwargs == {} ? nil : "kwargs=#{kwargs.inspect}"].compact.join(', '))
      $imw_depth += 1

      result = if parameters.include?(:key) || parameters.include?(:keyreq)
                 method.call(*args, **kwargs, &block)
               else
                 method.call(*args, &block)
               end

      $imw_depth -= 1
      warn format("%s %.#{$imw_len}s",
                  imw_indent(:out, false).to_s,
                  "<:o: #{sbase}::#{method_name}: #{result.inspect}")
      result
    end
  end
end

module InstanceMethodWrapper
  extend ImwUx # This makes imw_indent available as a class method
  include ImwUx # This makes imw_indent available as a class method

  def self.prepended(base)
    base.instance_methods(false).each do |method_name|
      wrap_method(base,
                  method_name) unless %i[method_missing].include? method_name
    end

    base.singleton_class.send(:define_method, :method_added) do |method_name|
      unless @_currently_adding_method
        @_currently_adding_method = true
        InstanceMethodWrapper.wrap_method(self, method_name)
        @_currently_adding_method = false
      end
    end
  end

  def self.wrap_method(base, method_name)
    sbase = base.to_s.gsub(/[a-z]/, '')
    original_method = base.instance_method(method_name)
    base.send(:define_method, method_name) do |*args, **kwargs, &block|
      warn format("%s %.#{$imw_len}s",
                  imw_indent(:in).to_s,
                  "#{sbase}::#{method_name}: " +
                   [args == [] ? nil : "args=#{args.inspect}",
                    kwargs == {} ? nil : "kwargs=#{kwargs.inspect}"].compact.join(', '))
      $imw_depth += 1
      original_method.bind(self).call(*args, **kwargs, &block).tap do |result|
        ### if !%w[method_missing].include? method_name
        $imw_depth -= 1
        warn format("%s %.#{$imw_len}s",
                    imw_indent(:out).to_s,
                    "#{sbase}::#{method_name}: " +
                   result.inspect)
        # end
      end
    end
  end
end

__END__

def the_method; other_method; end
def other_method; end

def start_trace
  trace = TracePoint.new(:call) { |tp| p [tp.path, tp.lineno, tp.event, tp.method_id] }

  trace.enable
  yield
  trace.disable
end

start_trace { the_method }

# EVENT NAME    DESCRIPTION
# call          Application methods
# c_call        C-level methods (like puts)
# return        Method return (for tracing return values & call depth)
# b_call        Block call
# b_return      Block return
# raise         Exception raised
# thread_begin  New thread
# thread_end    Thread ending

def the_method; "A" * 10; end

trace = TracePoint.new(:return) { |tp| puts "Return value for #{tp.method_id} is #{tp.return_value}." }

trace.enable
the_method
trace.disable
