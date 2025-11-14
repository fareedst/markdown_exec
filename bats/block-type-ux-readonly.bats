#!/usr/bin/env bats

load 'test_helper'

@test 'disables automatic block when readonly' {
  spec_mde_args_expect \
   docs/dev/block-type-ux-readonly.md \
   --blocks readonly \
   true
}
