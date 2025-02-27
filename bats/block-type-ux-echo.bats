#!/usr/bin/env bats

load 'test_helper'

@test 'automatic block - default' {
  spec_mde_xansi_dname_doc_blocks_expect docs/dev/block-type-ux-echo.md \
   'VAR=markdown_exec_IAB='
}

@test 'inherited lines' {
  spec_mde_xansi_dname_doc_blocks_expect docs/dev/block-type-ux-echo.md \
   '(menu_with_inherited_lines)' \
   'VAR=markdown_exec_VAR=markdown_exec_IAB='
}

@test 'selected block' {
  spec_mde_xansi_dname_doc_blocks_expect docs/dev/block-type-ux-echo.md \
   '(VAR_has_count)' '[IAB_has_count]' \
   'VAR=14_IAB=1414'
}
