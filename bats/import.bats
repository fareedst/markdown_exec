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

@test 'Directives - import; list block ids' {
  BATS_OUTPUT_FILTER=A
  BATS_SAFE=_
  spec_mde_args_expect docs/dev/import.md \
   --list-block-message id --list-blocks \
   'ItrBlkFrmNstFls:1¤./docs/dev/specs-import.md:0_ItrBlkFrmNstFls:4¤./docs/dev/specs-import.md:3_ItrBlkFrmNstFls:7¤./docs/dev/specs-import.md:6'
}
