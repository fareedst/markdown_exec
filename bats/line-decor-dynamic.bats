#!/usr/bin/env bats

load 'test_helper'

@test 'Line decor, dynamic - new pattern, line_decor_pre, ansi' {
  spec_mde_dname_doc_blocks_expect docs/dev/line-decor-dynamic.md \
   $'\e[1m\e[3m\e[38;2;200;200;33m\e[48;2;60;60;32mSpecies\e[22;23;0m'
}
