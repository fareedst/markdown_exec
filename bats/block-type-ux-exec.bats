#!/usr/bin/env bats

load 'test_helper'

@test 'uses executed command output as initial value' {
  spec_mde_xansi_dname_doc_blocks_expect docs/dev/block-type-ux-exec.md \
   "ux0=_ux1=Unknown_ux2=markdown_exec__ux3=markdown_exec__ux4=Xform: 'markdown'"
}
