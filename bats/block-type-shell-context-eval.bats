#!/usr/bin/env bats

load 'test_helper'

@test 'context block appends shell code to context without executing it' {
  BATS_OUTPUT_FILTER=A
  BATS_SAFE=_
  spec_mde_args_expect docs/dev/block-type-shell-context-eval.md \
   '[context]' '[opts]' \
  __Exit \
  'VARS1 = 0.0__~ SHELL_V1=0.0, 1.1_~ SHELL_V2=0.0, 1.2__  context_code_  - : VARS1="0.0"_  - : SHELL_V1="${VARS1}, 1.1"_  - : SHELL_V2="${VARS1}, 1.2"'
}

@test 'eval block executes shell code and output becomes transient code' {
  BATS_OUTPUT_FILTER=A
  BATS_SAFE=_
  spec_mde_args_expect docs/dev/block-type-shell-context-eval.md \
   '[eval]' '[opts]' \
  __Exit \
  'VARS1 = 0.0__~ SHELL_V1=0.0, 2.1_~ SHELL_V2=0.0, 2.2__  context_code_  - : VARS1="0.0"'
}

@test 'eval-context block executes shell code and appends output to context' {
  BATS_OUTPUT_FILTER=A
  BATS_SAFE=_
  spec_mde_args_expect docs/dev/block-type-shell-context-eval.md \
   '[eval-context]' '[opts]' \
  __Exit \
  'VARS1 = 0.0__~ SHELL_V1=0.0, 3.1_~ SHELL_V2=0.0, 3.2__  context_code_  - : VARS1="0.0"_  - : SHELL_V1="0.0, 3.1"_  - : SHELL_V2="0.0, 3.2"'
}

@test 'require-context block requires context block and can access its variables' {
  BATS_OUTPUT_FILTER=A
  BATS_SAFE=_
  spec_mde_args_expect docs/dev/block-type-shell-context-eval.md \
   '[require-context]' '[opts]' \
  __Exit \
  'VARS1 = 0.0__~ SHELL_V1=0.0, 1.1, 4.1_~ SHELL_V2=0.0, 1.2, 4.2__  context_code_  - : VARS1="0.0"_  - : SHELL_V1="${VARS1}, 1.1"_  - : SHELL_V2="${VARS1}, 1.2"'
}

@test 'require-eval-context block requires eval-context block and can access its variables' {
  BATS_OUTPUT_FILTER=A
  BATS_SAFE=_
  spec_mde_args_expect docs/dev/block-type-shell-context-eval.md \
   '[require-eval-context]' '[opts]' \
  __Exit \
  'VARS1 = 0.0__~ SHELL_V1=0.0, 3.1, 5.1_~ SHELL_V2=0.0, 3.2, 5.2__  context_code_  - : VARS1="0.0"_  - : SHELL_V1="0.0, 3.1"_  - : SHELL_V2="0.0, 3.2"'
}
