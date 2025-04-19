#!/usr/bin/env bats

load 'test_helper'

@test 'Border - ' {
  spec_mde_xansi_dname_doc_blocks_expect docs/dev/border.md \
   'A: 1_B: 2'
}
