#!/usr/bin/env bats

load 'test_helper'

@test 'collapses document options by default' {
  spec_mde_xansi_oname_doc_blocks_expect docs/dev/options-collapse.md \
   'H1.1_L1.1_H2.1_H1.2_H1.3_L1.3_H2.3_L2.3_h3.3_L3.3_D4.3_L4.3'
}

@test 'expands collapsible heading when selected' {
  spec_mde_xansi_oname_doc_blocks_expect docs/dev/options-collapse.md \
   H2.1 \
   'H1.1_L1.1_H2.1_L2.1_h3.1_L3.1_D4.1_L4.1_H1.2_H1.3_L1.3_H2.3_L2.3_h3.3_L3.3_D4.3_L4.3'
}

@test 'expands collapsible divider when selected' {
  spec_mde_xansi_oname_doc_blocks_expect docs/dev/options-collapse.md \
   D4.3 \
   'H1.1_L1.1_H2.1_H1.2_H1.3_L1.3_H2.3_L2.3_h3.3_L3.3_D4.3'
}

@test 'reveals multiple collapsed sections' {
  spec_mde_xansi_oname_doc_blocks_expect docs/dev/options-collapse.md \
   H1.2 H2.2 h3.2 D4.2 \
   'H1.1_L1.1_H2.1_H1.2_L1.2_H2.2_L2.2_h3.2_L3.2_D4.2_L4.2_H1.3_L1.3_H2.3_L2.3_h3.3_L3.3_D4.3_L4.3'
}
