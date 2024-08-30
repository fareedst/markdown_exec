#!/usr/bin/env bats

load 'test_helper'

# Directives

@test 'Directives - Import' {
  # this shell block is in the import, not the primary document
  run_mde_specs_md_args_expect_xansi 'shell-block-in-import' ' shell-block-in-import'
}

# Blocks, Wrapped

@test 'Shell blocks - wrapped block; nested; inverted' {
  run_mde_specs_md_args_expect_xansi '[single]' ' outer-before single-body outer-after'
  run_mde_specs_md_args_expect_xansi '[nested]' ' outer-before inner-before nested-body inner-after outer-after'
  run_mde_specs_md_args_expect_xansi '[inverted-nesting]' ' inner-before outer-before inverted-nesting outer-after inner-after'
}

# Blocks, Wrapped, Imported

@test 'Shell blocks - wrapped block; imported' {
  # the wrap blocks are in the import, not the primary document
  run_mde_specs_md_args_expect_xansi '[test-wrap-from-import]' ' wrap-from-import-before test-wrap-from-import wrap-from-import-after'
}

@test 'Shell blocks - required; wrapped block' {
  run_mde_specs_md_args_expect_xansi '[test-require-wrapped-block]' ' outer-before single-body outer-after test-require-wrapped-block'
}
