#!/usr/bin/env bats

load 'test_helper'

@test 'uses $ operator for variable expansion' {
  spec_mde_xansi_dname_doc_blocks_expect docs/dev/command-substitution-options.md \
   'operator_$' \
   'Command substitution__The current value of environment variable Common_Name_is displayed using two different operators._The command echo $SHLVL is executed via command_substitution, using two different operators.__| Operator | Variable Expansion | Command Substitution |_| -------- | ------------------ | -------------------- |_| $        | Tapanuli Orangutan | Pongo tapanuliensis  |_| @        | @{Common_Name}     | @(echo $Species)     |__Toggle between operators.__operator_$__operator_@'
}

@test 'uses @ operator for command substitution' {
  spec_mde_xansi_dname_doc_blocks_expect docs/dev/command-substitution-options.md \
   'Command substitution__The current value of environment variable Common_Name_is displayed using two different operators._The command echo $SHLVL is executed via command_substitution, using two different operators.__| Operator | Variable Expansion | Command Substitution |_| -------- | ------------------ | -------------------- |_| $        | ${Common_Name}     | $(echo $Species)     |_| @        | Tapanuli Orangutan | Pongo tapanuliensis  |__Toggle between operators.__operator_$__operator_@'
}
