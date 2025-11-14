#!/usr/bin/env bats

load 'test_helper'

@test 'displays initial value and inherited lines' {
  spec_mde_xansi_dname_doc_blocks_expect docs/dev/block-type-ux-require-chained.md \
   '[SPECIES]' \
   'ENTITY = Pongo tapanuliensis,Pongo_ENTITY="Pongo tapanuliensis,Pongo"_SPECIES=Pongo\ tapanuliensis_GENUS=Pongo_NAME=Pongo\ tapanuliensis\ -\ Pongo_NAME2=Pongo\ tapanuliensis\ -\ Pongo_SPECIES=Pongo tapanuliensis_GENUS=Pongo_NAME=Pongo tapanuliensis - Pongo_NAME2=Pongo tapanuliensis - Pongo'
}
