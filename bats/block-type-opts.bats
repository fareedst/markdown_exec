#!/usr/bin/env bats

load 'test_helper'

# Type: Opts

@test 'Opts block - before' {
  skip 'Fails because command executes after the block is processed'
  spec_mde_xansi_dname_doc_blocks_expect docs/dev/block-type-opts.md \
   'BEFORE Species_menu_note_format: "AFTER %{line}" '
}

@test 'Opts block - after' {
  spec_mde_xansi_dname_doc_blocks_expect docs/dev/block-type-opts.md \
   '[decorate-note]' \
   'AFTER Species_menu_note_format: "AFTER %{line}"'
}

@test 'Opts block - show that menu has changed' {
  skip 'Unable to show that menu has changed'
  spec_mde_args_expect docs/dev/block-type-opts.md '[decorate-note]' \
   'AFTER Species'
}
