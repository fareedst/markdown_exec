#!/usr/bin/env bats

load 'test_helper'

@test '' {
  spec_mde_xansi_dname_doc_blocks_expect docs/dev/import-directive-parameter-symbols.md \
   --blocks dname \
   'Stem: U1_Species: Illacme tobini_Genus: Illacme_Stem: U2_Species: Hydrodynastes bicinctus_Genus: Hydrodynastes'
}
