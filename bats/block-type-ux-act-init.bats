#!/usr/bin/env bats

load 'test_helper'

@test 'act_source' {
  spec_mde_xansi_message_doc_blocks_expect docs/dev/block-type-ux-act-init.md \
   export_act \
   'allow_echo_edit_exec_allow_allow_allow_allow_allow_allow_false_allow_allow_edit'
}

@test 'init_source' {
  spec_mde_xansi_message_doc_blocks_expect docs/dev/block-type-ux-act-init.md \
   export_init \
   'allow_allow_allow_allow_allow_default_echo_exec_allow_false_false_1.0.0_allow_false'
}

# bin/bmde docs/dev/block-type-ux-act-init.md --list-blocks-message export_init --list-blocks-type 3 --list-blocks