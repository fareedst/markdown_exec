#!/usr/bin/env bats

load 'test_helper'

@test 'automatic block - disabled' {
  spec_mde_args_expect \
   docs/dev/block-type-ux-readonly.md \
   --blocks readonly \
   true
}
