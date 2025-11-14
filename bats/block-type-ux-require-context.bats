#!/usr/bin/env bats

load 'test_helper'

@test 'displays initial values before activation' {
  spec_mde_xansi_dname_doc_blocks_expect docs/dev/block-type-ux-require-context.md \
   'Get the common name..._Entity: _ENTITY2: _UX1: _Common name: '
}

@test 'updates values when block activated' {
  spec_mde_xansi_dname_doc_blocks_expect docs/dev/block-type-ux-require-context.md \
   \[ux1\] \
   'Get the common name..._Entity: _ENTITY2: Mythical Monkey_UX1: Mythical Monkey_Common name: Mythical Monkey'
}
