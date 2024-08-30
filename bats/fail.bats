#!/usr/bin/env bats

load 'test_helper'

@test 'FAIL' {
  run_mde_specs_md_args_expect_xansi '[VARIABLE1]' '__Exit' ' VARIABLE1: FAIL'
}

@test 'OK' {
  run_mde_specs_md_args_expect_xansi '[VARIABLE1]' '__Exit' ' VARIABLE1: 1'
}
