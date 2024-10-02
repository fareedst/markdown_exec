#!/usr/bin/env bats

load 'test_helper'

@test 'Options - history, sorted' {
  local log_files="$(ls -1t logs/*examples_save_md*)"
  spec_mde_args_expect examples/save.md --history \
   "$log_files"
}

@test 'Options - history, dig' {
  skip 'test hangs on menu'
  local log_files="$(ls -1 logs/*)"
  spec_mde_args_expect --history --dig \
   "$log_files"
}

@test 'Options - history, probe' {
  local log_files="$(grep --files-with-matches '04:31' logs/* 2>/dev/null)"
  spec_mde_args_expect examples/save.md --probe '04:31' --history \
   "$log_files"
}

@test 'Options - history, sift' {
  local log_files="$(ls -1 logs/*-31-*examples_save_md*)"
  spec_mde_args_expect examples/save.md --sift -31- --history \
   "$log_files"
}

@test 'Options - history, sift and probe' {
  local log_files="$(grep --files-with-matches 'e' logs/*-31-*examples_save_md* 2>/dev/null)"
  spec_mde_args_expect examples/save.md --sift -31- --probe e --history \
   "$log_files"
}
