#!/usr/bin/env bats

load 'test_helper'

@test 'Each key in the echo hash is processed.' {
  spec_mde_xansi_dname_doc_blocks_expect docs/dev/block-type-ux-echo-hash-transform.md \
   'Tapanuli Orangutan_Species: PONGO TAPANULIENSIS_Genus: PONGO_Tapanuli Orangutan_Family: H:Hominidae_Order: P:Primates'
}
