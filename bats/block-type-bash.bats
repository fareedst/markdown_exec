#!/usr/bin/env bats

load 'test_helper'

@test 'executes bash block with default shell' {
  BATS_OUTPUT_FILTER=A
  spec_mde_args_expect docs/dev/block-type-bash.md block-with-no-shell-type \
   ' species'
}

@test 'executes bash block with bash shell' {
  BATS_OUTPUT_FILTER=A
  export MDE_BLOCK_TYPE_DEFAULT=bash
  spec_mde_args_expect docs/dev/block-type-bash.md bash \
   ' genus detected_shell: bash'
}

@test 'executes bash block with fish shell' {
  skip 'Fish shell is not testable'
  BATS_OUTPUT_FILTER=A
  export MDE_BLOCK_TYPE_DEFAULT=fish
  spec_mde_args_expect docs/dev/block-type-bash.md fish \
   ' family detected_shell: fish'
}

@test 'executes bash block with sh shell' {
  BATS_OUTPUT_FILTER=A
  export MDE_BLOCK_TYPE_DEFAULT=sh
  spec_mde_args_expect docs/dev/block-type-bash.md sh \
   ' family detected_shell: sh'
}

@test 'executes bash block with nickname' {
  BATS_OUTPUT_FILTER=A
  unset MDE_BLOCK_TYPE_DEFAULT
  spec_mde_args_expect docs/dev/block-type-bash.md \[show-shell-version\] \
   ' detected_shell: bash'
}
