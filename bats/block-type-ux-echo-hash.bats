#!/usr/bin/env bats

load 'test_helper'

@test 'automatic block sets multiple variables from echo hash' {
  spec_mde_xansi_dname_doc_blocks_expect docs/dev/block-type-ux-echo-hash.md \
   'BASENAME=markdown_exec_DOCUMENTS=markdown_OPERATION=exec_Load Tapanuli Orangutan_Load Psychedelic Frogfish_| Variable | Value |_| -------- | ----- |_| Species  |   |_| Genus    |       |_| Family   |   |'
}

@test 'activated block sets multiple variables from echo hash' {
  spec_mde_xansi_dname_doc_blocks_expect docs/dev/block-type-ux-echo-hash.md \
   'Load Tapanuli Orangutan' \
   'BASENAME=markdown_exec_DOCUMENTS=markdown_OPERATION=exec_Load Tapanuli Orangutan_Load Psychedelic Frogfish_| Variable | Value                   |_| -------- | ----------------------- |_| Species  | Pongo tapanuliensis |_| Genus    | Pongo                   |_| Family   | Hominidae           |'
}
