#!/usr/bin/env bats

load 'test_helper.bash'

# Directives

@test 'Directives - import' {
  specs_md 'from-import' ' from-import'
}

# Blocks, Type: Link

@test 'Link blocks - set variable in link block; call hidden block' {
  specs_md '[VARIABLE1]' '__Exit' ' VARIABLE1: 1'
  specs_md '[VARIABLE1]' '(echo-VARIABLE1)' ' VARIABLE1: 1   VARIABLE1: 1'
}

# Blocks, Wrapped

@test 'Shell blocks - wrapped blocks; nested; inverted' {
  specs_md '[single]' ' outer-before single-body outer-after'
  specs_md '[nested]' ' outer-before inner-before nested-body inner-after outer-after'
  specs_md '[inverted-nesting]' ' inner-before outer-before inverted-nesting outer-after inner-after'
}
