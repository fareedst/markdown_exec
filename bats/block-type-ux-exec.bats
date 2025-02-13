#!/usr/bin/env bats

load 'test_helper'

@test 'Output of executed commands as initial value' {
  spec_mde_xansi_dname_doc_blocks_expect docs/dev/block-type-ux-exec.md \
   "ux0=_ux1=Unknown_ux2=markdown_exec_ux3=markdown_exec_ux4=Xform: 'markdown'"
}
