#!/usr/bin/env bats

load 'test_helper'

@test '' {
  spec_mde_xansi_dname_doc_blocks_expect docs/dev/variable-expansion-multiline.md \
   'Genus2 = Pongo_Pongo_UX block:_Genus2=Pongo_Pongo_Command substitution:_Genus2 hex: 00000000  50 6f 6e 67 6f 0a 50 6f  6e 67 6f                 |Pongo.Pongo|_0000000b_Command substitution:_Genus2 text: Pongo_Pongo_Command substitution:_Gemfile_Gemfile.lock_Variable expansion:_Genus2 text: Pongo_Pongo'
}
