#!/usr/bin/env bats

load 'test_helper'

# Type: Vars

# includes output from automatic vars blocks
@test 'Vars block - auto load' {
  BATS_OUTPUT_FILTER=A
  spec_mde_xansi_dname_doc_blocks_expect docs/dev/block-type-vars.md show \
   'Species = Not specified_Genus = Not specified__Species: Not specified_VAULT: '
}

# includes output from assignment and from shell block
@test 'Vars block - set variable' {
  BATS_OUTPUT_FILTER=A
  spec_mde_args_expect docs/dev/block-type-vars.md '[set_vault_1]' show \
   'Species = Not specified Genus = Not specified VAULT = 1  Species: Not specified VAULT: 1'
}

# handles invalid YAML in block
@test 'Vars block - invalid YAML' {
  BATS_OUTPUT_FILTER=A
  spec_mde_args_expect docs/dev/block-type-vars.md '[invalid_yaml]' show \
   'Species = Not specified Genus = Not specified  Species: Not specified VAULT: '
}
