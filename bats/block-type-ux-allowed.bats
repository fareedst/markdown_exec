#!/usr/bin/env bats

load 'test_helper'

@test 'automatic blocks load defaults - constants or first allowed from output of echo or exec' {
  spec_mde_xansi_dname_doc_blocks_expect docs/dev/block-type-ux-allowed.md \
   'SPECIES=Pongo tapanuliensis_GENUS=Pongo_FAMILY=_ORDER=Click to select..._CLASS=Click to select..._YEAR_DISCOVERED=_NAME=Tapanuli Orangutan'
}

@test 'executing a block loads the first allowed value' {
  skip 'Unable to test the menu presented'
  spec_mde_xansi_dname_doc_blocks_expect docs/dev/block-type-ux-allowed.md \
   '[FAMILY]' \
   'SPECIES=Pongo tapanuliensis_GENUS=Pongo_FAMILY=Hominidae_ORDER=Click to select..._CLASS=Click to select..._YEAR_DISCOVERED=_NAME='
}

@test 'executing a block loads the first line in the output of exec' {
  skip 'Unable to test the menu presented'
  spec_mde_xansi_dname_doc_blocks_expect docs/dev/block-type-ux-allowed.md \
   '[YEAR_DISCOVERED]' \
   'SPECIES=Pongo tapanuliensis_GENUS=Pongo_FAMILY=_YEAR_DISCOVERED=2017_NAME='
}

@test 'executing a block loads the first line in the output of echo' {
  skip 'Unable to test the menu presented'
  spec_mde_xansi_dname_doc_blocks_expect docs/dev/block-type-ux-allowed.md \
   '[NAME]' \
   'SPECIES=Pongo tapanuliensis_GENUS=Pongo_FAMILY=_ORDER=Click to select..._CLASS=Click to select..._YEAR_DISCOVERED=_NAME=Tapanuli Orangutan'
}
