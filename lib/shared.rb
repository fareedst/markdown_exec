# frozen_string_literal: true

# encoding=utf-8

require 'shellwords'

public

BF = 'bin'

# display_level values
DISPLAY_LEVEL_BASE = 0 # required output
DISPLAY_LEVEL_ADMIN = 1 # monit
DISPLAY_LEVEL_DEBUG = 2
DISPLAY_LEVEL_DUMP = 3
DISPLAY_LEVEL_DEFAULT = DISPLAY_LEVEL_ADMIN
DISPLAY_LEVEL_MAX = DISPLAY_LEVEL_DUMP

# @execute_files[ind] = @execute_files[ind] + [block]
EF_STDOUT = 0
EF_STDERR = 1
EF_STDIN = 2

LOCAL_YML = 'menu.yml'
MENU_YML = "lib/#{LOCAL_YML}"

def menu_from_yaml
  YAML.load File.open(File.join(File.expand_path(__dir__), LOCAL_YML))
end
