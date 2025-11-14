#!/usr/bin/env bats

load 'test_helper'

@test 'merges row format with prior table' {
  spec_mde_xansi_dname_doc_blocks_expect docs/dev/block-type-ux-row-format.md \
   "   | Variable    | Value                 | Prompt                 |_   | ----------- | --------------------- | ---------------------- |_   | Species     | Pongo tapanuliensis   | New species?       |_   | Name: Genus | Value: Xform: 'Pongo' | Prompt: New genus? |_   | Family      | Hominidae             | Enter a value:     |"
}
