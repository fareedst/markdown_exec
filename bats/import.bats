#!/usr/bin/env bats

load 'test_helper'

@test 'lists indented blocks from imported file' {
  BATS_OUTPUT_FILTER=A
  spec_mde_args_expect docs/dev/import.md \
   --list-blocks-message indent --list-blocks \
   '              '
}

@test 'reports error when imported file missing' {
  BATS_OUTPUT_FILTER=A
  spec_mde_args_expect docs/dev/import-missing.md \
   ' Error: CachedNestedFileReader.readlines -- No such file or directory - this-is-missing.md @@ '
}

@test 'lists block ids from imported file' {
  BATS_OUTPUT_FILTER=A
  BATS_SAFE=_
  spec_mde_args_expect docs/dev/import.md \
   --list-block-message id --list-blocks \
   'ItrBlkFrmNstFls:1¤./docs/dev/specs-import.md:0_ItrBlkFrmNstFls:4¤./docs/dev/specs-import.md:3_ItrBlkFrmNstFls:7¤./docs/dev/specs-import.md:6'
}
