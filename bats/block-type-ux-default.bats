#!/usr/bin/env bats

load 'test_helper'

@test 'Initial values' {
  spec_mde_xansi_dname_doc_blocks_expect docs/dev/block-type-ux-default.md \
   'v1 = _v2 = 11_v3 = 12_v4 = 21_v5 = markdown_exec__v6 = 31'
}
