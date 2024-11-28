#!/usr/bin/env bats

load 'test_helper'

@test 'Directives - import, indented' {
  BATS_OUTPUT_FILTER=A
  spec_mde_args_expect docs/dev/import.md \
   --list-blocks-message indent --list-blocks \
   '              '
}

@test 'Directives - import, missing' {
  BATS_OUTPUT_FILTER=A
  spec_mde_args_expect docs/dev/import-missing.md \
   ' Error: CachedNestedFileReader.readlines -- No such file or directory - this-is-missing.md @@ '
}
