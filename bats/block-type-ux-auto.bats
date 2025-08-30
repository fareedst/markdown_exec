#!/usr/bin/env bats

load 'test_helper'

@test 'Initial values' {
  spec_mde_xansi_dname_doc_blocks_expect docs/dev/block-type-ux-auto.md \
   'v1 = _v2 = _v3 = 12_v4 = 21_v5 = markdown_exec_v6 = 31'
}
