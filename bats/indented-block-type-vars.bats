#!/usr/bin/env bats

load 'test_helper'

@test 'renders indented vars block with multiple lines' {
  BATS_OUTPUT_FILTER=A
  spec_mde_xansi_dname_doc_blocks_expect docs/dev/indented-block-type-vars.md \
   '  Species: Pongo tapanuliensis_  Genus: Pongo'
}
