#!/usr/bin/env bats

load 'test_helper'

@test 'pass-through arguments to scripts' {
  BATS_OUTPUT_FILTER=A
  spec_mde_args_expect docs/dev/pass-through-arguments.md output_arguments -- 1 23 \
   ' ARGS: 1 23'
}

@test 'searches current directory when file not found' {
  skip 'algorithm to exit waiting MDE is not ready'
  BATS_OUTPUT_FILTER=A
  BATS_SLEEP=8
  spec_mde_args_expect NotFoundAnywhere 'Searching in: .'
}

@test 'reports error when block not found' {
  BATS_OUTPUT_FILTER=A
  BATS_STATUS=1
  spec_mde_args_expect docs/dev/pass-through-arguments.md NonExistentBlock \
   ' Error: Block not found -- name: NonExistentBlock'
}

@test 'reports error when linked block missing' {
  BATS_STATUS=1
  spec_mde_args_expect docs/dev/requiring-blocks.md '[link-missing-local-block]' \
   'Block missing'
}

# Requiring blocks

@test 'bash block requires another bash block' {
  BATS_OUTPUT_FILTER=A
  spec_mde_args_expect docs/dev/requiring-blocks.md '[set-env]' \
   ' ARG1: 37'
}

@test 'appends vars from link block to inherited lines - local' {
  spec_mde_xansi_dname_doc_blocks_expect docs/dev/requiring-blocks.md \
   '[link-local-block-with-vars]' \
   '* Exit_# [link-local-block-with-vars]_ARG1="37"_block: echo-ARG1_  file: docs/dev/linked-file.md_  vars:_    ARG1: arg1-from-link-file_block: output_arguments_  vars:_    ARG1: 37_block: missing_ARG1=37_output_arguments'
}

@test 'appends vars from link block to inherited lines - external' {
  spec_mde_xansi_dname_doc_blocks_expect docs/dev/requiring-blocks.md \
   '[link-file-block-with-vars]' \
   '* Exit_# [link-file-block-with-vars]_ARG1="arg1-from-link-file"_echo-ARG1'
}

# the last block is a link block, so menu is displayed
@test 'link block requires bash block' {
  BATS_OUTPUT_FILTER=A
  spec_mde_args_expect docs/dev/requiring-blocks.md '[link-local-block-with-vars]' $EXIT_MENU \
   ' ARG1: 37'
}

# the last block is a link block, so menu is displayed
@test 'link block calls bash block in external file' {
  BATS_OUTPUT_FILTER=A
  spec_mde_args_expect docs/dev/requiring-blocks.md '[link-file-block-with-vars]' $EXIT_MENU \
   ' ARG1: arg1-from-link-file'
}

@test 'lists history files' {
  file_name="$(most_recent_history_file_name)"
  BATS_OUTPUT_GREP="$file_name"
  spec_mde_args_expect examples/save.md --history \
   "$file_name"
}

@test 'sifts history with text format' {
  file_name="$(most_recent_history_file_name)"
  date="$(date_from_history_file_name "$file_name")"
  BATS_OUTPUT_GREP="$file_name"
  spec_mde_args_expect examples/save.md --sift "$date" --history \
   "$file_name"
}

@test 'sifts history with yaml format' {
  file_name="$(most_recent_history_file_name)"
  date="$(date_from_history_file_name "$file_name")"
  BATS_OUTPUT_GREP="$file_name"
  spec_mde_args_expect examples/save.md --format yaml --sift "$date" --history \
   "- $file_name"
}
