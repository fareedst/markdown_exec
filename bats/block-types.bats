#!/usr/bin/env bats

load 'test_helper'

# Type: Bash

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

# Type: Link

@test 'Link blocks - set variable in link block; call hidden block' {
  # __Exit is required as last block is a Link type
  run_mde_specs_md_args_expect_xansi '[VARIABLE1]' __Exit ' VARIABLE1: 1'
  run_mde_specs_md_args_expect_xansi '[VARIABLE1]' '(echo-VARIABLE1)' ' VARIABLE1: 1   VARIABLE1: 1'
}

# Type: Opts

@test 'Opts block - before' {
  skip 'Fails because command executes after the block is processed'
  BATS_OUTPUT_FILTER=A
  spec_mde_args_expect docs/dev/block-type-opts.md --list-blocks-message dname --list-blocks-type 3 --list-blocks \
   'BEFORE Species menu_note_format: "AFTER %{line}" '
}

@test 'Opts block - after' {
  BATS_OUTPUT_FILTER=A
  spec_mde_args_expect docs/dev/block-type-opts.md --list-blocks-message dname --list-blocks-type 3 '[decorate-note]' --list-blocks \
   'AFTER Species menu_note_format: "AFTER %{line}" '
}

@test 'Opts block - show that menu has changed' {
  skip 'Unable to show that menu has changed'
  spec_mde_args_expect docs/dev/block-type-opts.md '[decorate-note]' \
   'AFTER Species'
}

# Type: Port

# includes output from assignment and from shell block
@test 'Port block - export variable' {
  BATS_OUTPUT_FILTER=A
  spec_mde_args_expect docs/dev/block-type-port.md '[set_vault_1]' show \
   'VAULT = 1  VAULT: 1'
}

@test 'Port block - export variable - not set' {
  BATS_OUTPUT_FILTER=A
  spec_mde_args_expect docs/dev/block-type-port.md VAULT-is-export show \
   '   VAULT: This variable has not been set.'
}

# Type: Vars

# includes output from assignment and from shell block
@test 'Vars block - set variable' {
  BATS_OUTPUT_FILTER=A
  spec_mde_args_expect docs/dev/block-type-vars.md '[set_vault_1]' show \
   'VAULT = 1  VAULT: 1'
}
