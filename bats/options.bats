#!/usr/bin/env bats

load 'test_helper'

# Defaults

@test 'Options - document and block name' {
  run_mde_specs_md_args_expect_xansi bash1 \
   ' bash1!'
}

# Options

@test 'Options - block-name' {
  BATS_OUTPUT_FILTER=A
  spec_mde_args_expect --block-name bash1 docs/dev/specs.md \
   ' bash1!'
}

@test 'Options - find, find-path in directory names' {
  run_mde_specs_md_args_expect_xansi --find-path ./docs --find search \
   'Searching in: ./docs In directory names ./docs/research'
}

@test 'Options - find, find-path in file names' {
  run_mde_specs_md_args_expect_xansi --find-path ./examples --find search \
   'Searching in: ./examples In file names ./examples/search.md'
}

@test 'Options - list blocks' {
  BATS_OUTPUT_FILTER=A
  spec_mde_args_expect --list-blocks-message oname --list-blocks-type 0 examples/colors.md --list-blocks \
   'load_colors load_colors2  Bash1 Link1 Opts1 Port1 Vars1'
}

@test 'Options - list blocks, eval' {
  BATS_OUTPUT_FILTER=A
  spec_mde_args_expect --list-blocks-eval block.oname examples/colors.md --list-blocks \
   'load_colors load_colors2  Bash1 Link1 Opts1 Port1 Vars1'
}

@test 'Options - how' {
  spec_mde_args_expect --how how \
   "prompt_show_expr_format: 'Expr: %{expr}'      # prompt_show_expr_format"
}

@test 'Options - list-default-env' {
  BATS_OUTPUT_GREP=SHEBANG
  spec_mde_args_expect --list-default-env \
   "MDE_SHEBANG=\#\!/usr/bin/env      # Shebang for saved scripts"
}

@test 'Options - list-default-yaml' {
  BATS_OUTPUT_GREP=shebang
  spec_mde_args_expect --list-default-yaml \
   "shebang: '#!/usr/bin/env'      # Shebang for saved scripts"
}

@test 'Options - list-docs, path' {
  BATS_OUTPUT_FILTER=A
  BATS_OUTPUT_GREP=specs
  spec_mde_args_expect --path docs/dev --list-docs \
   'docs/dev/specs-import.md docs/dev/specs.md'
}

# @test 'Options - list-recent-output' {
#   BATS_OUTPUT_FILTER=A \
#    spec_mde_args_expect \
#     --path docs/dev \
#     --list-recent-output \
#     "?"
# }

@test 'Options - load-code' {
  BATS_OUTPUT_FILTER=A
  BATS_OUTPUT_GREP=var1
  spec_mde_args_expect examples/load_code.md --load-code examples/load1.sh display_variables \
   'var1: line2'
}

@test 'Options - pwd' {
  spec_mde_args_expect --pwd \
   $(pwd)
}

@test 'Options - tab-completions' {
  BATS_OUTPUT_FILTER=A
  BATS_OUTPUT_GREP=find
  spec_mde_args_expect --tab-completions \
   '--find --find-path'
}

@test 'Options - version' {
  version=$(grep VERSION "$PROJECT_ROOT/lib/markdown_exec/version.rb" | cut -d "'" -f 2)
  spec_mde_args_expect --version \
   "$version"
}
