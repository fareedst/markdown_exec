#!/usr/bin/env bats

load 'test_helper'

@test 'An undefined variable is a precondition' {
  spec_mde_xansi_dname_doc_blocks_expect docs/dev/block-type-ux-preconditions.md \
   'A value must exist for: MISSING_VARIABLE_SPECIES='
}
