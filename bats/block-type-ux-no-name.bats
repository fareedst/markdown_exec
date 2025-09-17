#!/usr/bin/env bats

load 'test_helper'

@test 'displays last key in hash' {
  spec_mde_xansi_dname_doc_blocks_expect docs/dev/block-type-ux-no-name.md \
   'OPERATION1=exec_OPERATION2=exec__'
}
