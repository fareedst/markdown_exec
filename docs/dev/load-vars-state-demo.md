# LOAD Block State Modification Demo

This document demonstrates how a LOAD block can modify the inherited state that was initially set by VARS blocks.

First, establish baseline variables using a VARS block:

```vars :(document_vars)
var1: line1
var3: line6
```

Use a LOAD block to modify the initial state:

```load :load-mode-default
directory: docs/dev
glob: load1.sh
```
```load :load-mode-append
directory: docs/dev
glob: load1.sh
mode: append
```
```load :load-mode-replace
directory: docs/dev
glob: load1.sh
mode: replace
```
/
@import bats-document-configuration.md
```opts :(document_opts)
dump_context_code: true
# menu_for_saved_lines: true

screen_width: 64
```