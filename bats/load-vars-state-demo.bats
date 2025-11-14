#!/usr/bin/env bats

load 'test_helper'

@test 'displays document initial state' {
  spec_mde_xansi_dname_doc_blocks_expect docs/dev/load-vars-state-demo.md \
   'var1 = line1_var3 = line6_  inherited_lines_  - : var1="line1"_  - : var3="line6"_            LOAD BLOCK STATE MODIFICATION DEMO__This document demonstrates how a LOAD block can modify_the inherited state that was initially set by VARS_blocks.__First, establish baseline variables using a VARS block:__Use a LOAD block to modify the initial state:__load-mode-default_load-mode-append_load-mode-replace'
}

@test 'applies load-mode-default to inherited state' {
  spec_mde_xansi_dname_doc_blocks_expect docs/dev/load-vars-state-demo.md \
   load-mode-default \
   'var1 = line1_var3 = line6_  inherited_lines_  - : var1="line1"_  - : var3="line6"_  inherited_lines_  - : var1="line1"_  - : var3="line6"_  - : # line 1_  - : var1=line2_  - : # line 3_  - : var2=line4_  - : # line 5_            LOAD BLOCK STATE MODIFICATION DEMO__This document demonstrates how a LOAD block can modify_the inherited state that was initially set by VARS_blocks.__First, establish baseline variables using a VARS block:__Use a LOAD block to modify the initial state:__load-mode-default_load-mode-append_load-mode-replace'
}

@test 'appends to inherited state with load-mode-append' {
  spec_mde_xansi_dname_doc_blocks_expect docs/dev/load-vars-state-demo.md \
   load-mode-append \
   'var1 = line1_var3 = line6_  inherited_lines_  - : var1="line1"_  - : var3="line6"_  inherited_lines_  - : var1="line1"_  - : var3="line6"_  - : # line 1_  - : var1=line2_  - : # line 3_  - : var2=line4_  - : # line 5_            LOAD BLOCK STATE MODIFICATION DEMO__This document demonstrates how a LOAD block can modify_the inherited state that was initially set by VARS_blocks.__First, establish baseline variables using a VARS block:__Use a LOAD block to modify the initial state:__load-mode-default_load-mode-append_load-mode-replace'
}

@test 'replaces inherited state with load-mode-replace' {
  spec_mde_xansi_dname_doc_blocks_expect docs/dev/load-vars-state-demo.md \
   load-mode-replace \
   'var1 = line1_var3 = line6_  inherited_lines_  - : var1="line1"_  - : var3="line6"_  inherited_lines_  - : # line 1_  - : var1=line2_  - : # line 3_  - : var2=line4_  - : # line 5_            LOAD BLOCK STATE MODIFICATION DEMO__This document demonstrates how a LOAD block can modify_the inherited state that was initially set by VARS_blocks.__First, establish baseline variables using a VARS block:__Use a LOAD block to modify the initial state:__load-mode-default_load-mode-append_load-mode-replace'
}
