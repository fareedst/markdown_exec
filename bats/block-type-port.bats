#!/usr/bin/env bats

load 'test_helper'

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
