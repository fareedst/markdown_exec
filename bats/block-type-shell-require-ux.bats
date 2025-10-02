#!/usr/bin/env bats

load 'test_helper'

@test 'initial' {
  spec_mde_xansi_dname_doc_blocks_expect docs/dev/block-type-shell-require-ux.md \
   'require-a-UX-block__FULL_NAME='
}

@test 'activated' {
  spec_mde_xansi_dname_doc_blocks_expect docs/dev/block-type-shell-require-ux.md \
   require-a-UX-block \
   ''
}
