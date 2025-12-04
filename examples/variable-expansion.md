Link to load a file that sets variable ALPHA.
```link
load: tmp/save1.sh
```

Load from file.
```load
directory: tmp
glob: save1.sh
```

Link block to set variable ALPHA.
```link
vars:
  ALPHA: 3.14159
```

Vars block to set variable ALPHA.
```vars
ALPHA: 1.414
```

## ALPHA is now: ${ALPHA}
:::: ALPHA is now: ${ALPHA}
ALPHA is now: ${ALPHA}
| ALPHA
| -
| ${ALPHA}

Link block to load a file with variable ALPHA in the name.
```link
load: file_${ALPHA}
```
A Shell (Bash) block that is not expanded.
Expansion is performed by the shell.
```bash
# notice the string is expanded by the shell, not
echo "ALPHA is now ${ALPHA}"
```
A Shell (Bash) block that is not expanded but the name is.
Expansion of the body is performed by the shell.
```bash :block_name_with_${ALPHA}_in_name
# notice the string is not expanded by the shell
echo "ALPHA is now ${ALPHA}"
```
A Shell block that requires a block with an expansion in the name.
```bash +block_name_with_${ALPHA}_in_name
echo 'ALPHA was displayed by the required block.'
```

```history
directory: tmp
filename_pattern: '^(?<name>.*)$'
glob: ${ALPHA}.sh
view: '%{name}'
```
```load
directory: tmp
glob: ${ALPHA}.sh
```
```view
View
```
```edit :edit
```
```save
directory: tmp
glob: ${ALPHA}.sh
```

/ import bats-document-configuration.md
@import example-document-opts.md
```opts :(document_opts)
divider4_center: false

dump_blocks_in_file: false     # Dump BlocksInFile (stage 1)
dump_delegate_object: false    # Dump @delegate_object
dump_context_code: false    # Dump inherited lines
dump_menu_blocks: false        # Dump MenuBlocks (stage 2)
dump_selected_block: false     # Dump selected block

execute_in_own_window: false

output_execution_report: false
output_execution_summary: false

pause_after_script_execution: false

save_executed_script: false

script_execution_frame_color: plain
script_execution_head:
script_execution_tail:

table_center: false

user_must_approve: false

clear_screen_for_select_block: false
```