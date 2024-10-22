# frozen_string_literal: true

class BlockType
  ALL = [
    EDIT = 'edit',
    HISTORY = 'history',
    LINK = 'link',
    LOAD = 'load',
    OPTS = 'opts',
    PORT = 'port',
    SAVE = 'save',
    SHELL = 'shell',
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
