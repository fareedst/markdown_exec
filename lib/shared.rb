# frozen_string_literal: true

# encoding=utf-8

require 'shellwords'
require 'yaml'

# │0  │ to restore default    │
# │   │ color                 │
# ├───┼───────────────────────┤
# │   │                       │
# │1  │ for brighter colors   │
# ├───┼───────────────────────┤
# │   │                       │
# │4  │ for underlined text   │
# ├───┼───────────────────────┤
# │   │                       │
# │5  │ for flashing text
class String
  def black
    "\033[30m#{self}\033[0m"
  end

  def red
    "\033[31m#{self}\033[0m"
  end

  def bred
    "\033[1;31m#{self}\033[0m"
  end

  def green
    "\033[32m#{self}\033[0m"
  end

  def bgreen
    "\033[1;32m#{self}\033[0m"
  end

  def yellow
    "\033[33m#{self}\033[0m"
  end

  def byellow
    "\033[1;33m#{self}\033[0m"
  end

  def blue
    "\033[34m#{self}\033[0m"
  end

  def magenta
    "\033[35m#{self}\033[0m"
  end

  def cyan
    "\033[36m#{self}\033[0m"
  end

  def white
    "\033[37m#{self}\033[0m"
  end

  def bwhite
    "\033[1;37m#{self}\033[0m"
  end
end

public

def env_bool(name, default: false)
  return default if name.nil? || (val = ENV[name]).nil?
  return false if val.empty? || val == '0'

  true
end

def env_int(name, default: 0)
  return default if name.nil? || (val = ENV[name]).nil?
  return default if val.empty?

  val.to_i
end

def env_str(name, default: '')
  return default if name.nil? || (val = ENV[name]).nil?

  val || default
end

# debug output
#
def tap_inspect(format: nil, name: 'return')
  return self unless $pdebug

  cvt = {
    json: :to_json,
    string: :to_s,
    yaml: :to_yaml,
    else: :inspect
  }
  fn = cvt.fetch(format, cvt[:else])

  puts "-> #{caller[0].scan(/in `?(\S+)'$/)[0][0]}()" \
       " #{name}: #{method(fn).call}"

  self
end

def value_for_cli(value)
  case value.class.to_s
  when 'String'
    Shellwords.escape value
  when 'FalseClass', 'TrueClass'
    value ? '1' : '0'
  else
    Shellwords.escape value.to_s
  end
end

$pdebug = env_bool 'MDE_DEBUG'
