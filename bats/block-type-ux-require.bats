#!/usr/bin/env bats

load 'test_helper'

@test 'Output of executed commands as initial value' {
  spec_mde_xansi_dname_doc_blocks_expect docs/dev/block-type-ux-require.md \
   'SPECIES=Pongo tapanuliensis_GENUS=Pongo_NAME=Pongo tapanuliensis - Pongo_NAME2=Pongo tapanuliensis - Pongo'
}

@test 'inherited lines' {
  spec_mde_xansi_dname_doc_blocks_expect docs/dev/block-type-ux-require.md \
   '(menu_with_inherited_lines)' \
   'SPECIES=Pongo\ tapanuliensis_GENUS=Pongo_NAME=Pongo\ tapanuliensis\ -\ Pongo_NAME2=Pongo\ tapanuliensis\ -\ Pongo_SPECIES=Pongo tapanuliensis_GENUS=Pongo_NAME=Pongo tapanuliensis - Pongo_NAME2=Pongo tapanuliensis - Pongo'
}
