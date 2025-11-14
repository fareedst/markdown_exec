#!/usr/bin/env bats

load 'test_helper'

@test 'processes each key in echo hash with transform' {
  spec_mde_xansi_dname_doc_blocks_expect docs/dev/block-type-ux-echo-hash-transform.md \
   'Tapanuli Orangutan_Species: PONGO TAPANULIENSIS_Genus: PONGO_Tapanuli Orangutan_Family: H:Hominidae_Order: P:Primates_Psychedelic Frogfish_Species2:  Haccdeeehhiiilnopprsstyy_Genus2: Hehiinoprsty_Family2: Aaadeeiinnnrt'
}
