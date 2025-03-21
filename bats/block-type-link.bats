#!/usr/bin/env bats

load 'test_helper'

@test 'Link blocks - set variable in link block; call hidden block' {
  # __Exit is required as last block is a Link type
  run_mde_specs_md_args_expect_xansi '[VARIABLE1]' __Exit ' VARIABLE1: 1'
  run_mde_specs_md_args_expect_xansi '[VARIABLE1]' '(echo-VARIABLE1)' ' VARIABLE1: 1   VARIABLE1: 1'
}
