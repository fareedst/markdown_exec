#!/usr/bin/env bats

load 'test_helper'

@test 'Bash blocks - default' {
  BATS_OUTPUT_FILTER=A
  spec_mde_args_expect docs/dev/block-type-bash.md block-with-no-shell-type \
   ' species'
}

@test 'Bash blocks - specified Bash' {
  BATS_OUTPUT_FILTER=A
  export MDE_BLOCK_TYPE_DEFAULT=bash
  spec_mde_args_expect docs/dev/block-type-bash.md bash \
   ' genus detected_shell: bash'
}

@test 'Bash blocks - specified Fish' {
  skip 'Fish shell is not testable'
  BATS_OUTPUT_FILTER=A
  export MDE_BLOCK_TYPE_DEFAULT=fish
  spec_mde_args_expect docs/dev/block-type-bash.md fish \
   ' family detected_shell: fish'
}

@test 'Bash blocks - specified Sh' {
  BATS_OUTPUT_FILTER=A
  export MDE_BLOCK_TYPE_DEFAULT=sh
  spec_mde_args_expect docs/dev/block-type-bash.md sh \
   ' family detected_shell: sh'
}

@test 'Bash blocks - specified nickname' {
  BATS_OUTPUT_FILTER=A
  unset MDE_BLOCK_TYPE_DEFAULT
  spec_mde_args_expect docs/dev/block-type-bash.md \[show-shell-version\] \
   ' detected_shell: bash'
}
