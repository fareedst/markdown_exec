#!/usr/bin/env bats

load 'test_helper'

@test 'Directives - import, indented' {
  BATS_OUTPUT_FILTER=A
  spec_mde_args_expect docs/dev/import.md \
   --list-blocks-message indent --list-blocks \
   '              '
}
