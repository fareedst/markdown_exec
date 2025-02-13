# frozen_string_literal: true

# encoding=utf-8
require_relative 'block_types'

class AppInterrupt < StandardError; end
class BlockMissing < StandardError; end

class ArgPro
  ActFileIsMissing = :file_missing
  ActFind = :find
  ActSetBlockName = :block_name
  ActSetFileName = :set_filename
  ActSetOption = :set_option
  ActSetPath = :set_path
  ArgIsOption = :option
  ArgIsPosition = :position
  CallProcess = :proc_name
  ConvertValue = :convert
end

BLOCK_TYPE_COLOR_OPTIONS = {
  BlockType::EDIT => :menu_edit_color,
  BlockType::HISTORY => :menu_history_color,
  BlockType::LINK => :menu_link_color,
  BlockType::LOAD => :menu_load_color,
  BlockType::OPTS => :menu_opts_color,
  BlockType::SAVE => :menu_save_color,
  BlockType::SHELL => :menu_bash_color,
  BlockType::UX => :menu_ux_color,
  BlockType::VARS => :menu_vars_color
}.freeze

COLLAPSIBLE_SYMBOL_COLLAPSED = '⬢' # '<+>' # '∆'
COLLAPSIBLE_SYMBOL_EXPANDED = '⬡' # '< >' # '…'

# in regexp (?<collapse>[+-~]?)
COLLAPSIBLE_TOKEN_COLLAPSE = '+'
COLLAPSIBLE_TOKEN_EXPAND = '-'

COLLAPSIBLE_TYPES = [BlockType::DIVIDER, BlockType::HEADING].freeze

class ExecutionStreams
  STD_ERR = :stderr
  STD_IN  = :stdin
  STD_OUT = :stdout
end

IndexedLine = Struct.new(:index, :line) do
  def to_s
    line
  end
end

class LinkKeys
  BLOCK = 'block'
  EVAL = 'eval'
  EXEC = 'exec'
  FILE = 'file'
  LOAD = 'load'
  NEXT_BLOCK = 'next_block'
  RETURN = 'return'
  SAVE = 'save'
  VARS = 'vars'
end

class LoadFile
  EXIT = :exit
  LOAD = true
  REUSE = false
end

LoadFileLinkState = Struct.new(:load_file, :link_state)

class MenuOptions
  YES = 1
  NO = 2
  SCRIPT_TO_CLIPBOARD = 3
  SAVE_SCRIPT = 4
end

class MenuState
  BACK = :back
  CONTINUE = :continue
  EDIT = :edit
  EXIT = :exit
  HISTORY = :history
  LOAD = :load
  SAVE = :save
  SHELL = :shell
  VIEW = :view
end

# a struct to hold the data for a single line
NestedLine = Struct.new(:text, :depth, :indention) do
  def to_s
    indention + text
  end
end

# selected block and subsequent menu state
#
BlockSelection = Struct.new(:id)
SelectedBlockMenuState = Struct.new(:block, :source, :state)

class TtyMenu
  ENABLE = nil
  DISABLE = ''
end
