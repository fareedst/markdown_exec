#!/usr/bin/env bats

load 'test_helper'

@test 'Each key in the exec hash is processed.' {
  spec_mde_xansi_dname_doc_blocks_expect docs/dev/block-type-ux-exec-hash-transform.md \
   'Cappuccino Snake_Species_ H  Y  D  R  O  D  Y  N  A  S  T  E  S     B  I_ 48 59 44 52 4F 44 59 4E 41 53 54 45 53 20 42 49_  C  I  N  C  T  U  S  _ _ 43 49 4E 43 54 55 53 0A_Genus_ H  Y  D  R  O  D  Y  N  A  S  T  E  S  _ _ 48 59 44 52 4F 44 59 4E 41 53 54 45 53 0A_Family_ C  O  L  U  B  R  I  D  A  E_ 43 4F 4C 55 42 52 49 44 41 45_Order_ S  u  m  t  _ _ 53 75 6D 74 0A_Class_ R  p  i  i_ 52 70 69 69_Phylum_ C  o  d  t_ 43 6F 64 74'
}
