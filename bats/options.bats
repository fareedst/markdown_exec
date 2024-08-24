#!/usr/bin/env bats

load 'test_helper.bash'

# Options

@test 'Options - find' {
  spec_mde_args_expect \
   '--find search' \
   'Searching in: . In directory names ./docs/research In file names ./examples/search.md'
}

@test 'Options - list blocks' {
  spec_mde_args_expect \
   'examples/colors.md --list-blocks' \
   '(document_options) load_colors load_colors2 Bash1 Link1 Opts1 Port1 Vars1'
}
