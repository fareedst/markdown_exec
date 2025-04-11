#!/usr/bin/env bats

load 'test_helper'

@test 'Prefix $' {
  spec_mde_xansi_dname_doc_blocks_expect docs/dev/command-substitution-options.md \
   'prefix_$' \
   'Command substitution__The current value of environment variable Common_Name is displayed using two different prefixes._The command echo $SHLVL is executed via command substitution, using two different prefixes.__| Prefix | Variable Expansion | Command Substitution |_| ------ | ------------------ | -------------------- |_| $      | Tapanuli Orangutan | Pongo tapanuliensis  |_| @      | @{Common_Name}     | @(echo $Species)     |__Toggle between prefixes.__prefix_$__prefix_@'
}

@test 'Prefix @' {
  spec_mde_xansi_dname_doc_blocks_expect docs/dev/command-substitution-options.md \
   'Command substitution__The current value of environment variable Common_Name is displayed using two different prefixes._The command echo $SHLVL is executed via command substitution, using two different prefixes.__| Prefix | Variable Expansion | Command Substitution |_| ------ | ------------------ | -------------------- |_| $      | ${Common_Name}     | $(echo $Species)     |_| @      | Tapanuli Orangutan | Pongo tapanuliensis  |__Toggle between prefixes.__prefix_$__prefix_@'
}
