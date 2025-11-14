#!/usr/bin/env bats

load 'test_helper'

@test 'displays undefined variable as precondition' {
  spec_mde_xansi_dname_doc_blocks_expect docs/dev/block-type-ux-required-variables.md \
   'SPECIES='
}
