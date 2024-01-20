#!/usr/bin/env ruby
# frozen_string_literal: true

# encoding=utf-8

require_relative 'block_types'

class ExecutionStreams
  StdErr = :stderr
  StdIn  = :stdin
  StdOut = :stdout
end

IndexedLine = Struct.new(:index, :line) do
  def to_s
    line
  end
end

class LinkKeys
  Block = 'block'
  Eval = 'eval'
  Exec = 'exec'
  File = 'file'
  Load = 'load'
  NextBlock = 'next_block'
  Return = 'return'
  Save = 'save'
  Vars = 'vars'
end

class LoadFile
  Load = true
  Reuse = false
end

LoadFileLinkState = Struct.new(:load_file, :link_state)

class MenuControl
  Fresh = false
  Repeat = true
end

class MenuOptions
  YES = 1
  NO = 2
  SCRIPT_TO_CLIPBOARD = 3
  SAVE_SCRIPT = 4
end

class MenuState
  BACK = :back
  CONTINUE = :continue
  EXIT = :exit
end

# a struct to hold the data for a single line
NestedLine = Struct.new(:text, :depth) do
  def to_s
    text
  end
end

# selected block and subsequent menu state
#
SelectedBlockMenuState = Struct.new(:block, :state)

SHELL_COLOR_OPTIONS = {
  BlockType::BASH => :menu_bash_color,
  BlockType::LINK => :menu_link_color,
  BlockType::OPTS => :menu_opts_color,
  BlockType::VARS => :menu_vars_color
}.freeze

### Struct.new(:state, :block)
