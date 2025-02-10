# frozen_string_literal: true

class BlockType
  ALL = [
    CHROME = 'chrome',
    DIVIDER = 'divider',
    EDIT = 'edit',
    HEADING = 'heading',
    HISTORY = 'history',
    LINK = 'link',
    LOAD = 'load',
    OPTS = 'opts',
    PORT = 'port',
    SAVE = 'save',
    SHELL = 'shell',
    TEXT = 'text',
    UX = 'ux',
    VARS = 'vars',
    VIEW = 'view',
    YAML = 'yaml'
  ].freeze
end

class ShellType
  ALL = [
    BASH = 'bash',
    FISH = 'fish',
    SH = 'sh'
  ].freeze
end
