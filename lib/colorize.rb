# frozen_string_literal: true

# encoding=utf-8

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
