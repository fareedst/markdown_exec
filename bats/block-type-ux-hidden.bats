#!/usr/bin/env bats

load 'test_helper'

@test 'a UX block requires a shell block and another UX block' {
  spec_mde_xansi_dname_doc_blocks_expect docs/dev/block-type-ux-hidden.md \
   '[SPECIES]' \
   'SPECIES=Pongo tapanuliensis_NAME=Pongo tapanuliensis - Pongo'
}
