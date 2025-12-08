/ No blocks are evaluated at initialization.
/ When the shell block is activated, the UX block is required.
```bash :require-a-UX-block +[ux1] @context
ENTITY='Mythical Monkey'
```
/ Display variables set in the UX block.
${FIRST}
${LAST}
/ Parse and copy the name into variables.
```ux :[ux1]
echo:
  FIRST: '${ENTITY%% *}'
  LAST: '${ENTITY##* }'
  FULL_NAME: '$ENTITY'
init: false
readonly: true
```
@import bats-document-configuration.md
/```opts :(document_opts)
/dump_context_code: true
/menu_for_saved_lines: true
/```