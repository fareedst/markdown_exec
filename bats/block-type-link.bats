#!/usr/bin/env bats

load 'test_helper'

@test 'sets variable in link block and calls hidden block' {
  # __Exit is required as last block is a Link type
  run_mde_specs_md_args_expect_xansi '[VARIABLE1]' $EXIT_MENU ' VARIABLE1: 1'
  run_mde_specs_md_args_expect_xansi '[VARIABLE1]' '(echo-VARIABLE1)' ' VARIABLE1: 1   VARIABLE1: 1'
}
