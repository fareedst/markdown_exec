#!/usr/bin/env bats

load 'test_helper'

@test 'An undefined variable is a precondition - initial' {
  spec_mde_xansi_dname_doc_blocks_expect docs/dev/block-type-ux-required-variables.md \
   'SPECIES='
}
