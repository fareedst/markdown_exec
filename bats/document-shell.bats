#!/usr/bin/env bats

load 'test_helper'

@test 'requires document_shell for inherited lines' {
  spec_mde_xansi_dname_doc_blocks_expect docs/dev/document-shell.md \
   --dump-inherited-lines t '* Exit' \
   '  inherited_lines_  - : : from required_  - : : from document_shell'
}
