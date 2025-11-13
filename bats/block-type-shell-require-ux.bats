#!/usr/bin/env bats

load 'test_helper'

@test 'initial' {
  spec_mde_xansi_dname_doc_blocks_expect docs/dev/block-type-shell-require-ux.md \
   'require-a-UX-block__FULL_NAME='
}

@test 'activated' {
  # 2025-11-13 add a '.' block to force the display to update
  spec_mde_xansi_dname_doc_blocks_expect docs/dev/block-type-shell-require-ux.md \
   require-a-UX-block . \
   '__require-a-UX-block_Mythical_Monkey_FULL_NAME=Mythical Monkey'
}
