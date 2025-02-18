#!/usr/bin/env bats

load 'test_helper'

@test 'hide blocks' {
  spec_mde_xansi_dname_doc_blocks_expect docs/dev/block-hide.md \
   'visible'
}
