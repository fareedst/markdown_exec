#!/usr/bin/env bats

load 'test_helper'

# Type: Bash

# Type: Link

@test 'Link blocks - set variable in link block; call hidden block' {
  run_mde_specs_md_args_expect_xansi '[VARIABLE1]' '__Exit' ' VARIABLE1: 1'
  run_mde_specs_md_args_expect_xansi '[VARIABLE1]' '(echo-VARIABLE1)' ' VARIABLE1: 1   VARIABLE1: 1'
}

# Type: Opts

@test 'Opts block - before' {
  BATS_OUTPUT_FILTER=A
  spec_mde_args_expect docs/dev/block-type-opts.md --list-blocks-message dname --list-blocks-type 3 --list-blocks \
   'BEFORE Species menu_note_format: "AFTER %{line}" '
}

@test 'Opts block - after' {
  skip 'Fails because command executes before the block is processed'
  spec_mde_args_expect docs/dev/block-type-opts.md --list-blocks-message dname --list-blocks-type 3 '[decorate-note]' --list-blocks \
   'AFTER Species'
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
