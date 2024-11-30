#!/usr/bin/env bats

load 'test_helper'

@test 'no-active-elements' {
  spec_mde_xansi_dname_doc_blocks_expect docs/dev/no-active-elements.md \
   ' DEMONSTRATE A DOCUMENT WITH NO ACTIVE ELEMENTS_A document with no active elements.'
}
