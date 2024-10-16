# frozen_string_literal: true

class BlockType
  ALL = [
    LINK = 'link',
    OPTS = 'opts',
    PORT = 'port',
    SHELL = 'shell',
    VARS = 'vars',
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
