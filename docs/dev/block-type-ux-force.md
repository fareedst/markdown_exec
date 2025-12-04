/ The variable is defined mulitple times.
/ Blocks are evaluated in order from top to bottom.
/ The VARS assignment is output.
/ Inherited lines are output.
/ This VARS block creates the first assignment.
```vars :(document_vars)
Common_Name: Tapanuli Orangutan
```
/ This UX block forces the value in a second assignment.
```ux :[2]
init: Ruby Seadragon
force: true
name: Common_Name
```
! Common_Name! ${Common_Name}
@import bats-document-configuration.md
```opts :(document_opts)
dump_context_code: true
table_center: false
```