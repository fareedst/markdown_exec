#!/usr/bin/env bats

load 'test_helper'

@test 'requires chained read-only UX blocks for computed value' {
  spec_mde_xansi_dname_doc_blocks_expect docs/dev/block-type-ux-chained.md \
   '[SPECIES]' \
   'SPECIES=Pongo tapanuliensis_NAME=Pongo tapanuliensis - Pongo'
}
