#!/usr/bin/env bats

load 'test_helper'

@test 'automatic block - disabled' {
  spec_mde_args_expect \
   docs/dev/block-type-ux-readonly.md \
   --list-blocks-message readonly --list-blocks-type 3 --list-blocks \
   true
}
