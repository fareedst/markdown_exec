#!/usr/bin/env bats

load 'test_helper'

@test 'Output of executed commands as initial value' {
  spec_mde_xansi_dname_doc_blocks_expect docs/dev/block-type-ux-exec.md \
   "Now1=Unknown_Now2=markdown_exec_Now3=markdown_exec_Now4=Xform: 'markdown'"
}
