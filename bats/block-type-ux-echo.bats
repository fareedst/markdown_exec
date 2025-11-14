#!/usr/bin/env bats

load 'test_helper'

@test 'executes automatic block with default values' {
  spec_mde_xansi_dname_doc_blocks_expect docs/dev/block-type-ux-echo.md \
   'VAR=markdown_exec_IAB='
}

@test 'displays inherited lines in menu' {
  spec_mde_xansi_dname_doc_blocks_expect docs/dev/block-type-ux-echo.md \
   '(menu_with_inherited_lines)' \
   '[[ -z $VAR ]] && VAR=markdown_exec_VAR=markdown_exec_IAB='
}

@test 'includes whitespace in wc output for selected block' {
  spec_mde_xansi_dname_doc_blocks_expect docs/dev/block-type-ux-echo.md \
   '(VAR_has_count)' '[IAB_has_count]' \
   'VAR=mmaarrkkddoowwnn__eexxeecc_IAB=mmaarrkkddoowwnn__eexxeeccmmaarrkkddoowwnn__eexxeecc'
}
