#!/usr/bin/env bats

load 'test_helper'

@test 'A UX block requires other read-only UX blocks that operate on the computed value.' {
  spec_mde_xansi_dname_doc_blocks_expect docs/dev/block-type-ux-chained.md \
   '[SPECIES]' \
   'SPECIES=Pongotapanuliensis_GENUS=Pongo_NAME=Pongotapanuliensis-Pongo'
}
