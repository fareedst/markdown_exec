#!/usr/bin/env bats

load 'test_helper'

@test 'Variable expansion - default' {
  spec_mde_xansi_dname_doc_blocks_expect docs/dev/variable-expansion.md \
   ' EVIDENCE_ SOURCE is: ${SOURCE}_SOURCE is: ${SOURCE}_SOURCE is: ${SOURCE}_| SOURCE    |_| --------- |_| ${SOURCE} |_name_with_${SOURCE}_in_name_load: file_${SOURCE}.sh_ SOURCES'
}

@test 'Variable expansion - LINK_LOAD_SOURCE' {
  echo "SOURCE='Loaded file'" > temp_variable_expansion.sh
  spec_mde_xansi_dname_doc_blocks_expect docs/dev/variable-expansion.md \
   '(LINK_LOAD_SOURCE)' \
   ' EVIDENCE_ SOURCE is: Loaded file_SOURCE is: Loaded file_SOURCE is: Loaded file_| SOURCE      |_| ----------- |_| Loaded file |_name_with_${SOURCE}_in_name_load: file_Loaded file.sh_ SOURCES'
  rm temp_variable_expansion.sh
}

@test 'Variable expansion - LINK_VARS_SOURCE' {
  spec_mde_xansi_dname_doc_blocks_expect docs/dev/variable-expansion.md \
   '(LINK_VARS_SOURCE)' \
   ' EVIDENCE_ SOURCE is: Link block_SOURCE is: Link block_SOURCE is: Link block_| SOURCE     |_| ---------- |_| Link block |_name_with_${SOURCE}_in_name_load: file_Link block.sh_ SOURCES'
}

@test 'Variable expansion - VARS_SOURCE' {
  spec_mde_xansi_dname_doc_blocks_expect docs/dev/variable-expansion.md \
   '(VARS_SOURCE)' \
   ' EVIDENCE_ SOURCE is: Vars block_SOURCE is: Vars block_SOURCE is: Vars block_| SOURCE     |_| ---------- |_| Vars block |_name_with_${SOURCE}_in_name_load: file_Vars block.sh_ SOURCES'
}

### Load source

@test 'Variable expansion - in block body' {
  BATS_OUTPUT_FILTER=A
  spec_mde_args_expect docs/dev/variable-expansion.md \(VARS_SOURCE\) \
   --list-blocks --list-blocks-type 3 \
   --list-blocks-eval "block.body&.first&.start_with?(\"load: \") ? block.body : nil" \
   'load: file_Vars block.sh'
}

@test 'Variable expansion - in block dname' {
  BATS_OUTPUT_FILTER=A
  spec_mde_args_expect docs/dev/variable-expansion.md \(VARS_SOURCE\) \
   --list-blocks --list-blocks-type 3 \
   --list-blocks-eval "block.body&.first&.start_with?(\"load: \") ? block.dname : nil" \
   'load: file_Vars block.sh'
}