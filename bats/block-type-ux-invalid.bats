#!/usr/bin/env bats

load 'test_helper'

@test 'automatic block is invalid YAML' {
  spec_mde_xansi_dname_doc_blocks_expect docs/dev/block-type-ux-invalid.md \
   '_Error: HashDelegator../docs/dev/block-type-ux-invalid.md¤ItrBlkFrmNstFls:1 - --- !ruby/object:NullResult_message: Invalid YAML_data: invalid_ --  -- '
}
