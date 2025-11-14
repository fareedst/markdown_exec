#!/usr/bin/env bats

load 'test_helper'

@test 'retains whitespace in shell block output' {
  spec_mde_xansi_dname_doc_blocks_expect docs/dev/indented-multi-line-output.md \
   '[make-output]' \
   '_Species_ Genus_  Family_Order'
}
