#!/usr/bin/env bats

load 'test_helper'

@test 'automatic' {
  spec_mde_xansi_dname_doc_blocks_expect docs/dev/block-type-ux-exec-hash.md \
   'A single named variable is set automatically as the_output of the exec string._Common_Name=Yeti Crab_Common_Name=Yeti Crab_ Y  e  t  i     C  r  a  b  _ _ 59 65 74 69 20 43 72 61 62 0A__Multiple variables are set automatically as the_output of each exec string._One variable is temporary/not stored to inherited lines_but available for calculations within the block._Domain=ukaryota____D=_Domain=ukaryota_ u  k  a  r  y  o  t  a  _   _ _ 75 6B 61 72 79 6F 74 61 0A 0A__A single named variable is set interactively as the_output of the exec string._Year_Discovered=_Year_Discovered=_$(hexdump_format "$Year_Discovered")__Multiple variables are set interactively as the_output of the exec string._Genus=_Species=_$(hexdump_format "$Species")_Genus=_$(hexdump_format "$Genus")__A single named variable is set automatically as the_first line of the output of the first element in the echo_hash._Kingdom=Animalia_Kingdom=Animalia_ A  n  i  m  a  l  i  a_ 41 6E 69 6D 61 6C 69 61__A single named variable is set automatically as the_first line of the output of the first element in the exec_hash._Class=Malacostraca_Class=Malacostraca_ M  a  l  a  c  o  s  t  r  a  c  a_ 4D 61 6C 61 63 6F 73 74 72 61 63 61'
}

@test 'interactive' {
  spec_mde_xansi_dname_doc_blocks_expect docs/dev/block-type-ux-exec-hash.md \
   '[Year_Discovered]' \
   '[Genus]' \
   'A single named variable is set automatically as the_output of the exec string._Common_Name=Yeti Crab_Common_Name=Yeti Crab_ Y  e  t  i     C  r  a  b  _ _ 59 65 74 69 20 43 72 61 62 0A__Multiple variables are set automatically as the_output of each exec string._One variable is temporary/not stored to inherited lines_but available for calculations within the block._Domain=ukaryota____D=_Domain=ukaryota_ u  k  a  r  y  o  t  a  _   _ _ 75 6B 61 72 79 6F 74 61 0A 0A__A single named variable is set interactively as the_output of the exec string._Year_Discovered=2005_Year_Discovered=2005_ 2  0  0  5  _ _ 32 30 30 35 0A__Multiple variables are set interactively as the_output of the exec string._Genus=Kiwa__Species=Kiwa hirsuta_ K  i  w  a     h  i  r  s  u  t  a  _ _ 4B 69 77 61 20 68 69 72 73 75 74 61 0A_Genus=Kiwa_ K  i  w  a  _   _ _ 4B 69 77 61 0A 0A__A single named variable is set automatically as the_first line of the output of the first element in the echo_hash._Kingdom=Animalia_Kingdom=Animalia_ A  n  i  m  a  l  i  a_ 41 6E 69 6D 61 6C 69 61__A single named variable is set automatically as the_first line of the output of the first element in the exec_hash._Class=Malacostraca_Class=Malacostraca_ M  a  l  a  c  o  s  t  r  a  c  a_ 4D 61 6C 61 63 6F 73 74 72 61 63 61'
}
