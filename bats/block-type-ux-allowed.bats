#!/usr/bin/env bats

load 'test_helper'

@test 'loads defaults from constants or first allowed value' {
  spec_mde_xansi_dname_doc_blocks_expect docs/dev/block-type-ux-allowed.md \
   'SPECIES=Pongo tapanuliensis_GENUS=Pongo_FAMILY=_ORDER: Click to select..._Click to select..._YEAR_DISCOVERED=_NAME=Tapanuli Orangutan'
}

@test 'loads first allowed value when block executed' {
  skip 'Unable to test the menu presented'
  spec_mde_xansi_dname_doc_blocks_expect docs/dev/block-type-ux-allowed.md \
   '[FAMILY]' \
   'SPECIES=Pongo tapanuliensis_GENUS=Pongo_FAMILY=Hominidae_Click to select...Click to select..._YEAR_DISCOVERED=_NAME='
}

@test 'loads first line from exec output when block executed' {
  skip 'Unable to test the menu presented'
  spec_mde_xansi_dname_doc_blocks_expect docs/dev/block-type-ux-allowed.md \
   '[YEAR_DISCOVERED]' \
   'SPECIES=Pongo tapanuliensis_GENUS=Pongo_FAMILY=_YEAR_DISCOVERED=2017_NAME='
}

@test 'loads first line from echo output when block executed' {
  skip 'Unable to test the menu presented'
  spec_mde_xansi_dname_doc_blocks_expect docs/dev/block-type-ux-allowed.md \
   '[NAME]' \
   'SPECIES=Pongo tapanuliensis_GENUS=Pongo_FAMILY=_ORDER=Click to select..._CLASS=Click to select..._YEAR_DISCOVERED=_NAME=Tapanuli Orangutan'
}
