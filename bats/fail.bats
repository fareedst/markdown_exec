#!/usr/bin/env bats

load 'test_helper'

# this file contains a test that fails.
# this file is skipped during code checks.

@test 'FAIL' {
  run_mde_specs_md_args_expect_xansi '[VARIABLE1]' $EXIT_MENU ' VARIABLE1: FAIL'
}

@test 'OK' {
  run_mde_specs_md_args_expect_xansi '[VARIABLE1]' $EXIT_MENU ' VARIABLE1: 1'
}
