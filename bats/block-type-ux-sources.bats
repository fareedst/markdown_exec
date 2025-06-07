#!/usr/bin/env bats

load 'test_helper'

@test 'dname' {
  spec_mde_xansi_message_doc_blocks_expect docs/dev/block-type-ux-sources.md \
   dname \
   'USER_NAME=Guest_CURRENT_DIR=markdown_exec_SHELL_VERSION=/bin/bash_ENVIRONMENT=development_USER_EMAIL=_VERSION='
}

@test 'init_source' {
  spec_mde_xansi_message_doc_blocks_expect docs/dev/block-type-ux-sources.md \
   export_init \
   'Guest_exec_echo_allow_false_false'
}

@test 'act_source' {
  spec_mde_xansi_message_doc_blocks_expect docs/dev/block-type-ux-sources.md \
   export_act \
   'edit_edit_edit_allow_edit_edit'
}

@test 'is_disabled?' {
  spec_mde_xansi_message_doc_blocks_expect docs/dev/block-type-ux-sources.md \
   is_disabled? \
   'false_false_false_false_false_false'
}

