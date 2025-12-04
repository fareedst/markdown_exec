#!/usr/bin/env bats

load 'test_helper'

@test 'requires document_shell for inherited lines' {
  spec_mde_xansi_dname_doc_blocks_expect docs/dev/document-shell.md \
   --dump-context-code t '* Exit' \
   '  context_code_  - : : from required_  - : : from document_shell'
}
