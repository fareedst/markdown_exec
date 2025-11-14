#!/usr/bin/env bats

load 'test_helper'

@test 'substitutes command output in variables' {
  spec_mde_xansi_dname_doc_blocks_expect docs/dev/command-substitution.md \
   'CURRENT BASE NAME IS: MARKDOWN_EXEC_current base name is: markdown_exec_current base name is: markdown_exec_| current base name |_| ----------------- |_| markdown_exec     |_: notice the string is not expanded in Shell block types (names or body)._echo "current base name is now $(basename `pwd`)"_load: file_markdown_exec.sh_Status not zero: $(err)'
}
