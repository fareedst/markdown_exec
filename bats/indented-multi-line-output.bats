#!/usr/bin/env bats

load 'test_helper'

@test 'Retain whitespace in output from shell blocks' {
  spec_mde_xansi_dname_doc_blocks_expect docs/dev/indented-multi-line-output.md \
   '[make-output]' \
   '_Species_ Genus_  Family_Order'
}
