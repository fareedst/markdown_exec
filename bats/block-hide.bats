#!/usr/bin/env bats

load 'test_helper'

@test 'hides blocks marked as hidden' {
  spec_mde_xansi_dname_doc_blocks_expect docs/dev/block-hide.md \
   'visible'
}
