#!/usr/bin/env bats

load 'test_helper'

@test 'pass-through arguments to scripts' {
  BATS_OUTPUT_FILTER=A
  spec_mde_args_expect docs/dev/pass-through-arguments.md output_arguments -- 1 23 \
   ' ARGS: 1 23'
}

@test 'Position 0 File Name - file does not exist; string not found; select a file from the current directory' {
  skip 'algorithm to exit waiting MDE is not ready'
  BATS_OUTPUT_FILTER=A
  BATS_SLEEP=8
  spec_mde_args_expect NotFoundAnywhere 'Searching in: .'
}

@test 'Position 1 Block Name - block does not exist' {
  BATS_OUTPUT_FILTER=A
  BATS_STATUS=1
  spec_mde_args_expect docs/dev/pass-through-arguments.md NonExistentBlock \
   ' Error: Block not found -- name: NonExistentBlock'
}

@test 'block named in link does not exist' {
  BATS_STATUS=1
  spec_mde_args_expect docs/dev/requiring-blocks.md '[link-missing-local-block]' \
   'Block missing'
}

# Requiring blocks

@test 'bash block setting an environment variable requires a bash block' {
  BATS_OUTPUT_FILTER=A
  spec_mde_args_expect docs/dev/requiring-blocks.md '[set-env]' \
   ' ARG1: 37'
}

# the last block is a link block, so menu is displayed
@test 'link block setting an environment variable requires a bash block' {
  BATS_OUTPUT_FILTER=A
  spec_mde_args_expect docs/dev/requiring-blocks.md '[link-local-block-with-vars]' __Exit \
   ' ARG1: 37'
}

# the last block is a link block, so menu is displayed
@test 'link block setting an environment variable calls a bash block in a file' {
  BATS_OUTPUT_FILTER=A
  spec_mde_args_expect docs/dev/requiring-blocks.md '[link-file-block-with-vars]' __Exit \
   ' ARG1: arg1-from-link-file'
}

@test 'history' {
  file_name="$(most_recent_history_file_name)"
  BATS_OUTPUT_GREP="$file_name"
  spec_mde_args_expect examples/save.md --history \
   "$file_name"
}

@test 'sift - format text' {
  file_name="$(most_recent_history_file_name)"
  date="$(date_from_history_file_name "$file_name")"
  BATS_OUTPUT_GREP="$file_name"
  spec_mde_args_expect examples/save.md --sift "$date" --history \
   "$file_name"
}

@test 'sift - format yaml' {
  file_name="$(most_recent_history_file_name)"
  date="$(date_from_history_file_name "$file_name")"
  BATS_OUTPUT_GREP="$file_name"
  spec_mde_args_expect examples/save.md --format yaml --sift "$date" --history \
   "- $file_name"
}
