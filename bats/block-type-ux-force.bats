#!/usr/bin/env bats

load 'test_helper'

# UX before VARS although VARS appears first
@test 'automatic' {
  spec_mde_xansi_dname_doc_blocks_expect docs/dev/block-type-ux-force.md \
  'Common_Name = Tapanuli Orangutan_  inherited_lines_  - : Common_Name="Tapanuli Orangutan"_  - : Common_Name=Ruby\ Seadragon_Common_Name=Ruby Seadragon_| Common_Name | Ruby Seadragon |'
}
