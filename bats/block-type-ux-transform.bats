#!/usr/bin/env bats

load 'test_helper'

@test 'Transformed output of executed commands' {
  spec_mde_xansi_dname_doc_blocks_expect docs/dev/block-type-ux-transform.md \
   '_Execution output has a trailing newline._Var0=markdown_exec_00000000  6d 61 72 6b 64 6f 77 6e  5f 65 78 65 63 0a        |markdown_exec.|__With validate and transform, output has no newline._Var1=markdown_exec_00000000  6d 61 72 6b 64 6f 77 6e  5f 65 78 65 63           |markdown_exec|__With transform :chomp, output has no newline._Var2=markdown_exec_00000000  6d 61 72 6b 64 6f 77 6e  5f 65 78 65 63           |markdown_exec|__With transform :upcase, output is in upper case w/ newline._Var3=MARKDOWN_EXEC_00000000  4d 41 52 4b 44 4f 57 4e  5f 45 58 45 43 0a        |MARKDOWN_EXEC.|'
}
