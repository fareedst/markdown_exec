#!/usr/bin/env bats

load 'test_helper'

@test 'Operator $' {
  spec_mde_xansi_dname_doc_blocks_expect docs/dev/command-substitution-options.md \
   'operator_$' \
   'Command substitution__The current value of environment variable Common_Name is displayed using two different operators._The command echo $SHLVL is executed via command substitution, using two different operators.__| Operator | Variable Expansion | Command Substitution |_| -------- | ------------------ | -------------------- |_| $        | Tapanuli Orangutan | Pongo tapanuliensis  |_| @        | @{Common_Name}     | @(echo $Species)     |__Toggle between operators.__operator_$__operator_@'
}

@test 'Operator @' {
  spec_mde_xansi_dname_doc_blocks_expect docs/dev/command-substitution-options.md \
   'Command substitution__The current value of environment variable Common_Name is displayed using two different operators._The command echo $SHLVL is executed via command substitution, using two different operators.__| Operator | Variable Expansion | Command Substitution |_| -------- | ------------------ | -------------------- |_| $        | ${Common_Name}     | $(echo $Species)     |_| @        | Tapanuli Orangutan | Pongo tapanuliensis  |__Toggle between operators.__operator_$__operator_@'
}
