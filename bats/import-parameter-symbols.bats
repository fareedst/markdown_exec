#!/usr/bin/env bats

load 'test_helper'

@test 'Initial values' {
  spec_mde_xansi_dname_doc_blocks_expect docs/dev/import-parameter-symbols.md \
   'COMMON_NAME=Tapanuli Orangutan_Command substitution: Tapanuli Orangutan_echo "Command substitution: ${NAMEC}"__Evaluated expression: Tapanuli Orangutan_echo "Evaluated expression: ${NAMEE}"__Raw literal: Tapanuli Orangutan_echo "Raw literal: Tapanuli Orangutan"__Force-quoted literal: Tapanuli Orangutan_echo "Force-quoted literal: ${NAMEQ}"__Variable reference: Tapanuli Orangutan_echo "Variable reference: ${COMMON_NAME}"'
}
