#!/usr/bin/env bats

load 'test_helper'

@test 'executes blocks with same name but different requirements' {
  BATS_OUTPUT_FILTER=A
  BATS_SAFE=_
  spec_mde_args_expect docs/dev/import-conflict-0.md \
   'u0.0' \
   '_u0.0_d0.0_u0.1_d1.0_u1.1'
}
